[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repository = Split-Path -Parent $PSScriptRoot
$module = Join-Path $repository 'scripts/lib/AgentHarness.psm1'
$installer = Join-Path $repository 'scripts/install.ps1'
$uninstaller = Join-Path $repository 'scripts/uninstall.ps1'
$doctor = Join-Path $repository 'scripts/doctor.ps1'
Import-Module $module -Force

$passed = 0
$notAvailable = @()
function Assert-Test {
    param([bool]$Condition, [string]$Name)
    if (-not $Condition) { throw "FAIL: $Name" }
    $script:passed++
    Write-Output "PASS: $Name"
}

function New-FixtureSource {
    param([string]$Root)
    $source = Join-Path $Root 'clean source'
    [System.IO.Directory]::CreateDirectory($source) | Out-Null
    foreach ($directory in @('skills', 'references', 'templates')) {
        Copy-Item -LiteralPath (Join-Path $repository $directory) -Destination $source -Recurse -Force
    }
    & git -C $source init -q
    & git -C $source config core.autocrlf false
    & git -C $source add skills references templates
    & git -C $source -c user.name='agent-harness tests' -c user.email='tests@example.invalid' commit -qm 'fixture'
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create clean Git source fixture.' }
    return $source
}

$korean = ([string][char]0xD14C) + ([string][char]0xC2A4) + ([string][char]0xD2B8)
$root = Join-Path ([System.IO.Path]::GetTempPath()) ("Agent Harness $korean " + [guid]::NewGuid().ToString('N'))
try {
    [System.IO.Directory]::CreateDirectory($root) | Out-Null
    $source = New-FixtureSource -Root $root
    $state = Join-Path $root 'state/install-state.json'
    $overrides = @{ Codex = (Join-Path $root 'Codex skills'); Claude = (Join-Path $root 'Claude skills') }

    $firstPackages = Join-Path $root 'packages-one'
    $secondPackages = Join-Path $root 'packages-two'
    New-AgentHarnessPackages -SourceRoot $source -OutputRoot $firstPackages | Out-Null
    New-AgentHarnessPackages -SourceRoot $source -OutputRoot $secondPackages | Out-Null
    Assert-Test ((Get-ChildItem -LiteralPath $firstPackages -Directory).Count -eq 8) 'deterministic packaging creates all eight packages'
    Assert-Test (@(Compare-Object (Get-AgentHarnessFileInventory $firstPackages | ForEach-Object { "$($_.path):$($_.sha256)" }) (Get-AgentHarnessFileInventory $secondPackages | ForEach-Object { "$($_.path):$($_.sha256)" })).Count -eq 0) 'deterministic packaging has identical hashes'
    foreach ($skill in (Get-AgentHarnessExpectedSkills)) {
        $name = Get-AgentHarnessPackageName $skill
        $package = Join-Path $firstPackages $name
        Assert-Test (Test-AgentHarnessPackageRoot $package) "package validation $name"
        $frontmatter = Get-Content -LiteralPath (Join-Path $package 'SKILL.md') -Raw
        Assert-Test ($frontmatter -match "(?m)^name: $name$") "namespaced frontmatter $name"
        Assert-Test ($frontmatter -notmatch '\]\([^)]*SKILL\.md') "no sibling SKILL.md dependency $name"
    }

    $preview = & $installer -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($preview.results[0].status -eq 'PREVIEW' -and -not (Test-Path -LiteralPath $overrides.Codex) -and -not (Test-Path -LiteralPath $state)) 'dry-run performs no host or state writes'

    $installCodex = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($installCodex.results[0].status -eq 'INSTALLED') 'clean first Codex install'
    Assert-Test ((Get-ChildItem -LiteralPath $overrides.Codex -Directory | Where-Object { $_.Name -like 'agent-harness-*' }).Count -eq 8) 'Codex has eight installed packages'
    $repeat = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($repeat.results[0].status -eq 'UNCHANGED') 'repeat install is idempotent'
    $doctorCodex = & $doctor -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($doctorCodex.result -eq 'HEALTHY' -and $doctorCodex.targets[0].status -eq 'MANAGED_HEALTHY' -and $doctorCodex.targets[1].status -eq 'UNSELECTED') 'Codex-only doctor remains healthy with Claude unselected'

    $foreignName = Get-AgentHarnessPackageName 'research'
    [System.IO.Directory]::CreateDirectory((Join-Path $overrides.Claude $foreignName)) | Out-Null
    $foreign = & $installer -Target Claude -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($foreign.results[0].status -eq 'FAILED' -and $foreign.results[0].message -match 'collision') 'foreign package collision is refused'

    Add-Content -LiteralPath (Join-Path $overrides.Codex 'agent-harness-research/SKILL.md') -Value "`nmodified"
    $modified = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($modified.results[0].status -eq 'FAILED' -and $modified.results[0].message -match 'modified') 'modified managed package is preserved'
    $uninstallModified = & $uninstaller -Target Codex -Apply -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($uninstallModified.results[0].status -eq 'FAILED' -and (Test-Path -LiteralPath (Join-Path $overrides.Codex 'agent-harness-research'))) 'uninstall preserves modified package'

    Remove-Item -LiteralPath $overrides.Codex -Recurse -Force
    Remove-Item -LiteralPath $state -Force
    $fresh = & $installer -Target Both -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test (@($fresh.results | Where-Object { $_.status -eq 'INSTALLED' }).Count -eq 1) 'independent target result preserves successful host when Claude collision fails'
    Remove-Item -LiteralPath (Join-Path $overrides.Claude $foreignName) -Recurse -Force
    $both = & $installer -Target Both -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test (@($both.results | Where-Object { $_.status -eq 'INSTALLED' }).Count -eq 1) 'Claude-only follow-up install succeeds'
    $bothDoctor = & $doctor -Target Both -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($bothDoctor.result -eq 'HEALTHY' -and @($bothDoctor.targets | Where-Object { $_.status -eq 'MANAGED_HEALTHY' }).Count -eq 2) 'both targets doctor health'

    Remove-Item -LiteralPath (Join-Path $overrides.Codex 'agent-harness-pr') -Recurse -Force
    $partial = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($partial.results[0].status -eq 'FAILED' -and $partial.results[0].message -match 'stale') 'partial installation is refused without overwrite'

    & git -C $source status --porcelain | Out-Null
    Add-Content -LiteralPath (Join-Path $source 'skills/research/SKILL.md') -Value "`ndirty source"
    $dirty = $null
    try { & $installer -Target Claude -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides | Out-Null } catch { $dirty = $_.Exception.Message }
    Assert-Test ($dirty -match 'Clean Git source required') 'dirty source is refused by default'
    & git -C $source checkout -- skills/research/SKILL.md

    $outside = Join-Path $root 'outside.md'
    [System.IO.File]::WriteAllText($outside, 'outside')
    $manifest = Join-Path $source 'skills/research/SKILL.md'
    Add-Content -LiteralPath $manifest -Value "`n[escape](../../../../outside.md)"
    $traversal = $null
    try { New-AgentHarnessPackages -SourceRoot $source -OutputRoot (Join-Path $root 'bad-packages') | Out-Null } catch { $traversal = $_.Exception.Message }
    Assert-Test ($traversal -match 'Unsupported package dependency') 'path traversal dependency is rejected'
    & git -C $source checkout -- skills/research/SKILL.md

    $healthyUninstall = & $uninstaller -Target Claude -Apply -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($healthyUninstall.results[0].status -eq 'REMOVED' -and -not (Test-Path -LiteralPath (Join-Path $overrides.Claude 'agent-harness-research'))) 'healthy uninstall removes only owned Claude packages'
    $missingState = Join-Path $root 'missing/install-state.json'
    $stale = & $uninstaller -Target Claude -Apply -StatePath $missingState -TargetRootOverrides $overrides
    Assert-Test ($stale.results[0].status -eq 'NOT_MANAGED') 'missing state is non-destructive'

    try {
        $link = Join-Path $root 'reparse-test'
        New-Item -ItemType SymbolicLink -Path $link -Target $source -ErrorAction Stop | Out-Null
        Assert-Test (Test-AgentHarnessReparsePoint $link) 'reparse point detection'
    } catch {
        $notAvailable += 'reparse/symlink creation requires local policy support'
        Write-Output 'NOT AVAILABLE: reparse/symlink creation requires local policy support'
    }

    Write-Output "PASS: $passed assertions"
    if ($notAvailable.Count -gt 0) { Write-Output "NOT AVAILABLE: $($notAvailable -join '; ')" }
} finally {
    if (Test-Path -LiteralPath $root) { Remove-Item -LiteralPath $root -Recurse -Force }
}
