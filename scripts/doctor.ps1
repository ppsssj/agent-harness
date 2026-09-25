[CmdletBinding()]
param(
    [ValidateSet('Codex', 'Claude', 'Both')][string]$Target = 'Both',
    [string]$SourceRoot = (Split-Path -Parent $PSScriptRoot),
    [string]$StatePath,
    [hashtable]$TargetRootOverrides
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'lib/AgentHarness.psm1') -Force

function Get-StateTarget { param($State, [string]$TargetHost) return @($State.managedTargets | Where-Object { $_.host -eq $TargetHost }) }

function Test-ManagedTarget {
    param($Record, [string]$TargetHost, [string]$Root)
    if (-not (Get-AgentHarnessCanonicalPath $Record.destinationRoot).Equals((Get-AgentHarnessCanonicalPath $Root), [System.StringComparison]::OrdinalIgnoreCase)) { return 'BROKEN: state destination differs from resolved root.' }
    if (-not (Test-Path -LiteralPath $Root -PathType Container) -or (Test-AgentHarnessReparsePoint $Root)) { return 'BROKEN: target root is missing or a reparse point.' }
    $expectedNames = @(Get-AgentHarnessExpectedSkills | ForEach-Object { Get-AgentHarnessPackageName $_ })
    if (@($Record.packages).Count -ne $expectedNames.Count) { return "DEGRADED: state does not contain the expected $($expectedNames.Count) packages." }
    foreach ($name in $expectedNames) {
        $records = @($Record.packages | Where-Object { $_.name -eq $name })
        if ($records.Count -ne 1) { return "DEGRADED: package state missing or duplicated for $name." }
        $path = Join-Path $Root $name
        if (-not (Test-AgentHarnessPathWithin -Path $path -Root $Root) -or -not (Test-Path -LiteralPath $path -PathType Container) -or (Test-AgentHarnessReparsePoint $path)) { return "BROKEN: unsafe or missing package $name." }
        try { Test-AgentHarnessPackageRoot -PackageRoot $path | Out-Null } catch { return "DEGRADED: package validation failed for ${name}: $($_.Exception.Message)" }
        $inventory = Test-AgentHarnessInventory -Root $path -ExpectedInventory $records[0].files
        if (-not $inventory.Valid) { return "DEGRADED: package hash mismatch for ${name}: $($inventory.Reason)" }
    }
    return 'HEALTHY'
}

if ([string]::IsNullOrWhiteSpace($StatePath)) { $StatePath = Get-AgentHarnessDefaultStatePath }
$StatePath = Get-AgentHarnessCanonicalPath $StatePath
$source = Get-AgentHarnessCanonicalPath $SourceRoot
$repository = try { foreach ($skill in (Get-AgentHarnessExpectedSkills)) { Get-Item -LiteralPath (Join-Path $source "skills/$skill/SKILL.md") -ErrorAction Stop | Out-Null }; 'PASS' } catch { "FAIL: $($_.Exception.Message)" }
$stateError = $null
try { $state = Read-AgentHarnessState -StatePath $StatePath } catch { $state = $null; $stateError = $_.Exception.Message }
$selected = Resolve-AgentHarnessSelection -Target $Target
$results = @()
foreach ($targetHost in @('Codex', 'Claude')) {
    $root = Resolve-AgentHarnessTargetRoot -TargetHost $targetHost -TargetRootOverrides $TargetRootOverrides
    if ($targetHost -notin $selected) {
        $results += [pscustomobject]@{ host = $targetHost; destinationRoot = $root; status = 'UNSELECTED'; detail = 'Not requested for this doctor run; does not affect overall health.' }
        continue
    }
    if ($null -ne $stateError) { $results += [pscustomobject]@{ host = $targetHost; destinationRoot = $root; status = 'MANAGED_DEGRADED'; detail = "BROKEN: $stateError" }; continue }
    $records = @()
    if ($null -ne $state) { $records = @(Get-StateTarget -State $state -TargetHost $targetHost) }
    if ($records.Count -gt 1) { $results += [pscustomobject]@{ host = $targetHost; destinationRoot = $root; status = 'MANAGED_DEGRADED'; detail = 'BROKEN: duplicate state entries.' }; continue }
    if ($records.Count -eq 1) {
        $validation = Test-ManagedTarget -Record $records[0] -TargetHost $targetHost -Root $root
        $status = if ($validation -eq 'HEALTHY') { 'MANAGED_HEALTHY' } else { 'MANAGED_DEGRADED' }
        $results += [pscustomobject]@{ host = $targetHost; destinationRoot = $root; status = $status; detail = $validation }
        continue
    }
    $hasPackages = (Get-AgentHarnessExpectedSkills | ForEach-Object { Test-Path -LiteralPath (Join-Path $root (Get-AgentHarnessPackageName $_)) -PathType Container } | Where-Object { $_ }).Count -gt 0
    $status = if ($hasPackages) { 'UNMANAGED_INSTALLED' } elseif (Get-Command -Name $(if ($targetHost -eq 'Codex') { 'codex' } else { 'claude' }) -ErrorAction SilentlyContinue) { 'UNMANAGED_INSTALLED' } else { 'NOT_INSTALLED' }
    $results += [pscustomobject]@{ host = $targetHost; destinationRoot = $root; status = $status; detail = 'No agent-harness ownership record for this selected host.' }
}
$overall = if ($repository -notlike 'PASS*' -or @($results | Where-Object { $_.detail -like 'BROKEN:*' }).Count -gt 0) { 'BROKEN' } elseif (@($results | Where-Object { $_.status -eq 'MANAGED_DEGRADED' }).Count -gt 0) { 'DEGRADED' } else { 'HEALTHY' }
[pscustomobject]@{ repository = $repository; statePath = $StatePath; result = $overall; targets = $results; note = 'Filesystem/discovery prerequisites validated; model skill selection is not proven by doctor.' }
