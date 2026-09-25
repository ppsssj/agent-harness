[CmdletBinding()]
param(
    [ValidateSet('Codex', 'Claude', 'Both')][string]$Target = 'Both',
    [switch]$Apply,
    [string]$StatePath,
    [hashtable]$TargetRootOverrides
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/AgentHarness.psm1') -Force

function Get-StateTarget { param($State, [string]$TargetHost) return @($State.managedTargets | Where-Object { $_.host -eq $TargetHost }) }

if ([string]::IsNullOrWhiteSpace($StatePath)) { $StatePath = Get-AgentHarnessDefaultStatePath }
$StatePath = Get-AgentHarnessCanonicalPath $StatePath
$selected = Resolve-AgentHarnessSelection -Target $Target
$state = Read-AgentHarnessState -StatePath $StatePath
if ($null -eq $state) {
    [pscustomobject]@{ apply = [bool]$Apply; statePath = $StatePath; results = @($selected | ForEach-Object { [pscustomobject]@{ host = $_; status = 'NOT_MANAGED'; message = 'No ownership state exists; no files were removed.' } }) }
    return
}

$results = @()
$removedHosts = @()
foreach ($targetHost in $selected) {
    $records = @(Get-StateTarget -State $state -TargetHost $targetHost)
    if ($records.Count -eq 0) { $results += [pscustomobject]@{ host = $targetHost; status = 'NOT_MANAGED'; message = 'No managed target entry.' }; continue }
    if ($records.Count -ne 1) { $results += [pscustomobject]@{ host = $targetHost; status = 'FAILED'; message = 'Duplicate managed target state; preserving all files.' }; continue }
    $record = $records[0]
    try {
        $resolvedRoot = Resolve-AgentHarnessTargetRoot -TargetHost $targetHost -TargetRootOverrides $TargetRootOverrides
        if (-not (Get-AgentHarnessCanonicalPath $record.destinationRoot).Equals((Get-AgentHarnessCanonicalPath $resolvedRoot), [System.StringComparison]::OrdinalIgnoreCase)) { throw 'State destination does not match resolved target root.' }
        if (Test-AgentHarnessReparsePoint $resolvedRoot) { throw 'Target root is a reparse point.' }
        foreach ($package in $record.packages) {
            $path = Join-Path $resolvedRoot $package.name
            if (-not (Test-AgentHarnessPathWithin -Path $path -Root $resolvedRoot)) { throw "Package path escapes target root: $($package.name)" }
            if (-not (Test-Path -LiteralPath $path -PathType Container) -or (Test-AgentHarnessReparsePoint $path)) { throw "Owned package is missing or unsafe: $($package.name)" }
            $inventory = Test-AgentHarnessInventory -Root $path -ExpectedInventory $package.files
            if (-not $inventory.Valid) { throw "Owned package '$($package.name)' was modified; preserving it. $($inventory.Reason)" }
        }
        if ($Apply) {
            foreach ($package in $record.packages) { Remove-Item -LiteralPath (Join-Path $resolvedRoot $package.name) -Recurse -Force }
            $removedHosts += $targetHost
            $results += [pscustomobject]@{ host = $targetHost; status = 'REMOVED'; message = 'Removed only hash-verified owned packages.' }
        } else {
            $results += [pscustomobject]@{ host = $targetHost; status = 'PREVIEW'; message = 'All owned packages verify; no files were removed.' }
        }
    } catch { $results += [pscustomobject]@{ host = $targetHost; status = 'FAILED'; message = $_.Exception.Message } }
}

if ($Apply -and $removedHosts.Count -gt 0) {
    $remaining = @($state.managedTargets | Where-Object { $_.host -notin $removedHosts })
    if ($remaining.Count -eq 0) {
        Remove-Item -LiteralPath $StatePath -Force
    } else {
        $newState = [pscustomobject]@{ schemaVersion = 1; updatedAt = [DateTime]::UtcNow.ToString('o'); source = $state.source; managedTargets = $remaining }
        Write-AgentHarnessState -State $newState -StatePath $StatePath
    }
}
[pscustomobject]@{ apply = [bool]$Apply; statePath = $StatePath; results = $results }
