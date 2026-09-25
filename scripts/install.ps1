[CmdletBinding()]
param(
    [ValidateSet('Codex', 'Claude', 'Both')][string]$Target = 'Both',
    [switch]$Apply,
    [switch]$AllowDirtySource,
    [switch]$AllowNonGitSource,
    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$StatePath,
    [hashtable]$TargetRootOverrides
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/AgentHarness.psm1') -Force

function New-InstallerTemporaryDirectory {
    $path = Join-Path ([System.IO.Path]::GetTempPath()) ('agent-harness-' + [guid]::NewGuid().ToString('N'))
    [System.IO.Directory]::CreateDirectory($path) | Out-Null
    return $path
}

function Get-StateTarget {
    param($State, [string]$TargetHost)
    if ($null -eq $State) { return $null }
    $matches = @($State.managedTargets | Where-Object { $_.host -eq $TargetHost })
    if ($matches.Count -gt 1) { throw "State has duplicate managed target entries for $TargetHost." }
    if ($matches.Count -eq 1) { return $matches[0] }
    return $null
}

function Get-DirectoryByInsensitiveName {
    param([string]$Root, [string]$Name)
    if (-not (Test-Path -LiteralPath $Root -PathType Container)) { return $null }
    $matches = @(Get-ChildItem -LiteralPath $Root -Directory -Force | Where-Object { $_.Name.Equals($Name, [System.StringComparison]::OrdinalIgnoreCase) })
    if ($matches.Count -gt 1) { throw "Case-insensitive package collision at $Root for $Name." }
    if ($matches.Count -eq 1) { return $matches[0].FullName }
    return $null
}

function Test-InstallPreflight {
    param($State, [string]$TargetHost, [string]$TargetRoot, [string]$PackagesRoot)

    $ownedTarget = Get-StateTarget -State $State -TargetHost $TargetHost
    if ($null -ne $ownedTarget -and -not (Get-AgentHarnessCanonicalPath $ownedTarget.destinationRoot).Equals((Get-AgentHarnessCanonicalPath $TargetRoot), [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "$TargetHost state destination does not match the resolved destination root."
    }
    if ((Test-Path -LiteralPath $TargetRoot) -and (Test-AgentHarnessReparsePoint $TargetRoot)) { throw "$TargetHost skill root is a reparse point: $TargetRoot" }

    foreach ($sourcePackage in (Get-ChildItem -LiteralPath $PackagesRoot -Directory -Force | Sort-Object Name)) {
        $name = $sourcePackage.Name
        $destination = Get-DirectoryByInsensitiveName -Root $TargetRoot -Name $name
        $ownedPackage = @()
        if ($null -ne $ownedTarget) { $ownedPackage = @($ownedTarget.packages | Where-Object { $_.name -eq $name }) }
        if ($null -ne $destination) {
            if (Test-AgentHarnessReparsePoint $destination) { throw "$TargetHost package destination is a reparse point: $destination" }
            if ($null -eq $ownedTarget -or $ownedPackage.Count -ne 1) { throw "$TargetHost package collision: $destination is not owned by agent-harness." }
            $inventory = Test-AgentHarnessInventory -Root $destination -ExpectedInventory $ownedPackage[0].files
            if (-not $inventory.Valid) { throw "$TargetHost package '$name' was modified or is incomplete: $($inventory.Reason)" }
        } elseif ($null -ne $ownedTarget -and $ownedPackage.Count -eq 1) {
            throw "$TargetHost state is stale: owned package '$name' is missing."
        }
    }
}

function Test-TargetMatchesPackages {
    param($State, [string]$TargetHost, [string]$TargetRoot, [string]$PackagesRoot)

    $ownedTarget = Get-StateTarget -State $State -TargetHost $TargetHost
    if ($null -eq $ownedTarget) { return $false }
    foreach ($sourcePackage in (Get-ChildItem -LiteralPath $PackagesRoot -Directory -Force)) {
        $record = @($ownedTarget.packages | Where-Object { $_.name -eq $sourcePackage.Name })
        $destination = Join-Path $TargetRoot $sourcePackage.Name
        if ($record.Count -ne 1 -or -not (Test-Path -LiteralPath $destination -PathType Container)) { return $false }
        $sourceInventory = Get-AgentHarnessFileInventory -Root $sourcePackage.FullName
        $comparison = Test-AgentHarnessInventory -Root $destination -ExpectedInventory $sourceInventory
        if (-not $comparison.Valid) { return $false }
    }
    return $true
}

function Install-OneTarget {
    param([string]$TargetHost, [string]$TargetRoot, [string]$PackagesRoot, $Trust)

    $target = Get-AgentHarnessCanonicalPath $TargetRoot
    $targetParent = Split-Path -Parent $target
    if (-not (Test-AgentHarnessPathWithin -Path $target -Root $targetParent)) { throw "Unsafe target path: $target" }
    [System.IO.Directory]::CreateDirectory($target) | Out-Null
    if (Test-AgentHarnessReparsePoint $target) { throw "$TargetHost skill root is a reparse point: $target" }

    $stage = Join-Path $targetParent ('.agent-harness-stage-' + [guid]::NewGuid().ToString('N'))
    $backup = Join-Path $targetParent ('.agent-harness-backup-' + [guid]::NewGuid().ToString('N'))
    $movedOld = @()
    $movedNew = @()
    try {
        [System.IO.Directory]::CreateDirectory($stage) | Out-Null
        foreach ($sourcePackage in (Get-ChildItem -LiteralPath $PackagesRoot -Directory -Force | Sort-Object Name)) {
            Copy-Item -LiteralPath $sourcePackage.FullName -Destination $stage -Recurse -Force
            $staged = Join-Path $stage $sourcePackage.Name
            $expected = Get-AgentHarnessFileInventory -Root $sourcePackage.FullName
            $verified = Test-AgentHarnessInventory -Root $staged -ExpectedInventory $expected
            if (-not $verified.Valid) { throw "Staged package verification failed for $($sourcePackage.Name): $($verified.Reason)" }
        }
        [System.IO.Directory]::CreateDirectory($backup) | Out-Null
        foreach ($stagedPackage in (Get-ChildItem -LiteralPath $stage -Directory -Force | Sort-Object Name)) {
            $existing = Get-DirectoryByInsensitiveName -Root $target -Name $stagedPackage.Name
            if ($null -ne $existing) {
                Move-Item -LiteralPath $existing -Destination $backup
                $movedOld += $stagedPackage.Name
            }
        }
        foreach ($stagedPackage in (Get-ChildItem -LiteralPath $stage -Directory -Force | Sort-Object Name)) {
            Move-Item -LiteralPath $stagedPackage.FullName -Destination $target
            $movedNew += $stagedPackage.Name
        }
        $packages = @()
        foreach ($name in (Get-AgentHarnessExpectedSkills | ForEach-Object { Get-AgentHarnessPackageName $_ })) {
            $packagePath = Join-Path $target $name
            Test-AgentHarnessPackageRoot -PackageRoot $packagePath | Out-Null
            $packages += [pscustomobject]@{ name = $name; files = @(Get-AgentHarnessFileInventory -Root $packagePath) }
        }
        return [pscustomobject]@{
            host = $TargetHost; destinationRoot = $target; installedAt = [DateTime]::UtcNow.ToString('o')
            packageFormatVersion = 1; packages = $packages
            source = [pscustomobject]@{ path = $Trust.Path; gitCommit = $Trust.GitCommit; provenance = $Trust.Provenance; gitStatus = @($Trust.GitStatus); artifactInventory = @($Trust.ArtifactInventory) }
        }
    } catch {
        foreach ($name in $movedNew) {
            $newPath = Join-Path $target $name
            if (Test-Path -LiteralPath $newPath) { Remove-Item -LiteralPath $newPath -Recurse -Force }
        }
        foreach ($name in $movedOld) {
            $oldPath = Join-Path $backup $name
            if (Test-Path -LiteralPath $oldPath) { Move-Item -LiteralPath $oldPath -Destination $target }
        }
        throw
    } finally {
        if (Test-Path -LiteralPath $stage) { Remove-Item -LiteralPath $stage -Recurse -Force }
        if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Recurse -Force }
    }
}

if ([string]::IsNullOrWhiteSpace($StatePath)) { $StatePath = Get-AgentHarnessDefaultStatePath }
$StatePath = Get-AgentHarnessCanonicalPath $StatePath
$source = Get-AgentHarnessCanonicalPath $SourceRoot
$trust = Get-AgentHarnessSourceTrust -SourceRoot $source -AllowDirtySource:$AllowDirtySource -AllowNonGitSource:$AllowNonGitSource
$selected = Resolve-AgentHarnessSelection -Target $Target
$temporary = New-InstallerTemporaryDirectory

try {
    $packagesRoot = Join-Path $temporary 'packages'
    New-AgentHarnessPackages -SourceRoot $source -OutputRoot $packagesRoot | Out-Null
    $trust | Add-Member -NotePropertyName ArtifactInventory -NotePropertyValue @(Get-AgentHarnessFileInventory -Root $packagesRoot) -Force
    $state = Read-AgentHarnessState -StatePath $StatePath
    $results = @()
    foreach ($targetHost in $selected) {
        $targetRoot = Resolve-AgentHarnessTargetRoot -TargetHost $targetHost -TargetRootOverrides $TargetRootOverrides
        try {
            Test-InstallPreflight -State $state -TargetHost $targetHost -TargetRoot $targetRoot -PackagesRoot $packagesRoot
            if ($Apply) {
                if (Test-TargetMatchesPackages -State $state -TargetHost $targetHost -TargetRoot $targetRoot -PackagesRoot $packagesRoot) {
                    $results += [pscustomobject]@{ host = $targetHost; status = 'UNCHANGED'; destinationRoot = $targetRoot; record = $null; message = 'Already installed with identical verified content.' }
                } else {
                    $record = Install-OneTarget -TargetHost $targetHost -TargetRoot $targetRoot -PackagesRoot $packagesRoot -Trust $trust
                    $results += [pscustomobject]@{ host = $targetHost; status = 'INSTALLED'; destinationRoot = $targetRoot; record = $record; message = 'Installed and hash-verified.' }
                }
            } else {
                $results += [pscustomobject]@{ host = $targetHost; status = 'PREVIEW'; destinationRoot = $targetRoot; record = $null; message = 'Validated; no host or state files were changed.' }
            }
        } catch {
            $results += [pscustomobject]@{ host = $targetHost; status = 'FAILED'; destinationRoot = $targetRoot; record = $null; message = $_.Exception.Message }
        }
    }

    if ($Apply) {
        $successful = @($results | Where-Object { $_.status -eq 'INSTALLED' })
        if ($successful.Count -gt 0) {
            $retained = @()
            if ($null -ne $state) { $retained = @($state.managedTargets | Where-Object { $_.host -notin $successful.host }) }
            $newState = [pscustomobject]@{
                schemaVersion = 1; updatedAt = [DateTime]::UtcNow.ToString('o')
                source = [pscustomobject]@{ path = $trust.Path; gitCommit = $trust.GitCommit; provenance = $trust.Provenance; gitStatus = @($trust.GitStatus); artifactInventory = @($trust.ArtifactInventory) }
                managedTargets = @($retained + @($successful | ForEach-Object { $_.record }))
            }
            Write-AgentHarnessState -State $newState -StatePath $StatePath
        }
    }
    [pscustomobject]@{ source = $trust; statePath = $StatePath; apply = [bool]$Apply; results = $results }
} finally {
    if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
