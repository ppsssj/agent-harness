[CmdletBinding()]
param(
    [ValidateSet('Codex', 'Claude', 'Both')][string]$Target = 'Both',
    [switch]$Apply,
    [switch]$TestInjectStateWriteFailure,
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
$transactions = @()
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
            $quarantine = Join-Path (Split-Path -Parent $resolvedRoot) ('.agent-harness-uninstall-' + [guid]::NewGuid().ToString('N'))
            [System.IO.Directory]::CreateDirectory($quarantine) | Out-Null
            $moved = @()
            try {
                foreach ($package in $record.packages) { Move-Item -LiteralPath (Join-Path $resolvedRoot $package.name) -Destination $quarantine; $moved += $package.name }
            } catch {
                foreach ($name in $moved) { $saved = Join-Path $quarantine $name; if (Test-Path -LiteralPath $saved) { Move-Item -LiteralPath $saved -Destination $resolvedRoot } }
                throw
            }
            $transactions += [pscustomobject]@{ host = $targetHost; root = $resolvedRoot; quarantine = $quarantine; moved = @($moved) }
            $removedHosts += $targetHost
            $results += [pscustomobject]@{ host = $targetHost; status = 'PENDING_STATE_COMMIT'; message = 'Packages quarantined pending state commit.' }
        } else {
            $results += [pscustomobject]@{ host = $targetHost; status = 'PREVIEW'; message = 'All owned packages verify; no files were removed.' }
        }
    } catch { $results += [pscustomobject]@{ host = $targetHost; status = 'FAILED'; message = $_.Exception.Message } }
}

if ($Apply -and $removedHosts.Count -gt 0) {
    $remaining = @($state.managedTargets | Where-Object { $_.host -notin $removedHosts })
    $newState = [pscustomobject]@{ schemaVersion = 1; updatedAt = [DateTime]::UtcNow.ToString('o'); source = $state.source; managedTargets = $remaining }
    try {
        Write-AgentHarnessState -State $newState -StatePath $StatePath -TestInjectFailure:$TestInjectStateWriteFailure
        foreach ($transaction in $transactions) {
            Remove-Item -LiteralPath $transaction.quarantine -Recurse -Force
            ($results | Where-Object { $_.host -eq $transaction.host }).status = 'REMOVED'
            ($results | Where-Object { $_.host -eq $transaction.host }).message = 'Removed only hash-verified owned packages after state commit.'
        }
        if ($remaining.Count -eq 0) { Remove-Item -LiteralPath $StatePath -Force }
    } catch {
        $stateFailure = $_.Exception.Message
        foreach ($transaction in $transactions) {
            $failures = @()
            foreach ($name in $transaction.moved) { $saved = Join-Path $transaction.quarantine $name; if (Test-Path -LiteralPath $saved) { try { Move-Item -LiteralPath $saved -Destination $transaction.root } catch { $failures += $_.Exception.Message } } }
            $result = $results | Where-Object { $_.host -eq $transaction.host }
            if ($failures.Count -gt 0) { $result.status = 'BROKEN'; $result.message = "State commit failed; rollback incomplete. Recovery material: $($transaction.quarantine). $($failures -join ' | ')" }
            else { if (Test-Path -LiteralPath $transaction.quarantine) { Remove-Item -LiteralPath $transaction.quarantine -Recurse -Force }; $result.status = 'FAILED'; $result.message = "State commit failed; packages restored. $stateFailure" }
        }
    }
}
[pscustomobject]@{ apply = [bool]$Apply; statePath = $StatePath; results = $results }
