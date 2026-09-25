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

$expectedPackageCount = @(Get-AgentHarnessExpectedSkills).Count
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

function Set-FixtureSkillLineEndings {
    param([string]$Source, [ValidateSet('LF', 'CRLF')][string]$LineEnding)
    $ending = if ($LineEnding -eq 'CRLF') { "`r`n" } else { "`n" }
    Get-ChildItem -LiteralPath (Join-Path $Source 'skills') -Recurse -File -Filter SKILL.md | ForEach-Object {
        $normalized = [regex]::Replace((Get-Content -LiteralPath $_.FullName -Raw), "`r?`n", "`n")
        [System.IO.File]::WriteAllText($_.FullName, $normalized.Replace("`n", $ending), (New-Object System.Text.UTF8Encoding($false)))
    }
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
    Assert-Test ($expectedPackageCount -eq 9 -and 'visual-critique' -in (Get-AgentHarnessExpectedSkills)) 'expected skills include visual-critique as the ninth skill'
    Assert-Test ((Get-ChildItem -LiteralPath $firstPackages -Directory).Count -eq $expectedPackageCount) 'deterministic packaging creates every expected package'
    Assert-Test (Test-Path -LiteralPath (Join-Path $firstPackages 'agent-harness-visual-critique/SKILL.md') -PathType Leaf) 'visual-critique package is generated'
    Assert-Test (@(Compare-Object (Get-AgentHarnessFileInventory $firstPackages | ForEach-Object { "$($_.path):$($_.sha256)" }) (Get-AgentHarnessFileInventory $secondPackages | ForEach-Object { "$($_.path):$($_.sha256)" })).Count -eq 0) 'deterministic packaging has identical hashes'
    foreach ($lineEnding in @('LF', 'CRLF')) {
        $endingSource = New-FixtureSource -Root (Join-Path $root "frontmatter $lineEnding")
        Set-FixtureSkillLineEndings -Source $endingSource -LineEnding $lineEnding
        $endingPackages = Join-Path $root "packages $lineEnding"
        New-AgentHarnessPackages -SourceRoot $endingSource -OutputRoot $endingPackages | Out-Null
        $generated = Get-Content -LiteralPath (Join-Path $endingPackages 'agent-harness-research/SKILL.md') -Raw
        Assert-Test ($generated -match '(?m)^name: agent-harness-research\r?$') "namespaced frontmatter rewrite with $lineEnding source"
        if ($lineEnding -eq 'CRLF') { Assert-Test ($generated.Contains("name: agent-harness-research`r`n")) 'CRLF is preserved in generated frontmatter' }
    }
    foreach ($skill in (Get-AgentHarnessExpectedSkills)) {
        $name = Get-AgentHarnessPackageName $skill
        $package = Join-Path $firstPackages $name
        Assert-Test (Test-AgentHarnessPackageRoot $package) "package validation $name"
        $frontmatter = Get-Content -LiteralPath (Join-Path $package 'SKILL.md') -Raw
        Assert-Test ($frontmatter -match "(?m)^name: $name\r?$") "namespaced frontmatter $name"
        Assert-Test ($frontmatter -notmatch '\]\([^)]*SKILL\.md') "no sibling SKILL.md dependency $name"
    }
    $critiquePackage = Join-Path $firstPackages 'agent-harness-visual-critique'
    foreach ($dependency in @('templates/visual-critique-report.md', 'templates/reference-lock.md', 'templates/DESIGN.md')) {
        Assert-Test (Test-Path -LiteralPath (Join-Path $critiquePackage $dependency) -PathType Leaf) "visual-critique package-local dependency $dependency"
    }
    foreach ($pair in @(@('design-research', 'visual-critique'), @('frontend-design', 'visual-critique'), @('verification', 'visual-critique'), @('visual-critique', 'frontend-design'), @('visual-critique', 'design-research'), @('visual-critique', 'verification'))) {
        $manifestText = Get-Content -LiteralPath (Join-Path $firstPackages "agent-harness-$($pair[0])/SKILL.md") -Raw
        $related = [regex]::Match($manifestText, '(?ms)^## Related\s*\r?\n(.*?)(?=^## |\z)').Groups[1].Value
        Assert-Test ($related -match "\bagent-harness-$($pair[1])\b") "agent-harness-$($pair[0]) relates to agent-harness-$($pair[1])"
    }
    $unknownRelated = Join-Path $root 'unknown related package'
    Copy-Item -LiteralPath $critiquePackage -Destination $unknownRelated -Recurse
    Add-Content -LiteralPath (Join-Path $unknownRelated 'SKILL.md') -Value 'agent-harness-visual-critic'
    $unknownRelatedError = $null
    try { Test-AgentHarnessPackageRoot $unknownRelated | Out-Null } catch { $unknownRelatedError = $_.Exception.Message }
    Assert-Test ($unknownRelatedError -match "Unknown related skill identifier 'agent-harness-visual-critic'") 'related skill validation still rejects unknown identifiers'

    $preview = & $installer -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($preview.results[0].status -eq 'PREVIEW' -and -not (Test-Path -LiteralPath $overrides.Codex) -and -not (Test-Path -LiteralPath $state)) 'dry-run performs no host or state writes'

    $installCodex = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($installCodex.results[0].status -eq 'INSTALLED') 'clean first Codex install'
    Assert-Test ((Get-ChildItem -LiteralPath $overrides.Codex -Directory | Where-Object { $_.Name -like 'agent-harness-*' }).Count -eq $expectedPackageCount) 'Codex has every expected installed package'
    Assert-Test (@((Read-AgentHarnessState -StatePath $state).managedTargets[0].packages).Count -eq $expectedPackageCount) 'Codex state records every expected package'
    $repeat = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($repeat.results[0].status -eq 'UNCHANGED') 'repeat install is idempotent'
    $doctorCodex = & $doctor -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($doctorCodex.result -eq 'HEALTHY' -and $doctorCodex.targets[0].status -eq 'MANAGED_HEALTHY' -and $doctorCodex.targets[1].status -eq 'UNSELECTED') 'Codex-only doctor remains healthy with Claude unselected'

    # Simulate an install made before visual-critique existed: owned state and files for the prior eight packages only.
    $legacyName = Get-AgentHarnessPackageName 'visual-critique'
    $legacyState = Read-AgentHarnessState -StatePath $state
    $legacyState.managedTargets[0].packages = @($legacyState.managedTargets[0].packages | Where-Object { $_.name -ne $legacyName })
    Write-AgentHarnessState -State $legacyState -StatePath $state
    Remove-Item -LiteralPath (Join-Path $overrides.Codex $legacyName) -Recurse -Force
    $legacyDoctor = & $doctor -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($legacyDoctor.result -eq 'DEGRADED' -and $legacyDoctor.targets[0].detail -eq "DEGRADED: state does not contain the expected $expectedPackageCount packages.") 'doctor reports the expected package count for a prior eight-package install'
    $upgrade = & $installer -Target Codex -Apply -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    $upgradeDoctor = & $doctor -Target Codex -SourceRoot $source -StatePath $state -TargetRootOverrides $overrides
    Assert-Test ($upgrade.results[0].status -eq 'INSTALLED' -and (Test-Path -LiteralPath (Join-Path $overrides.Codex $legacyName)) -and $upgradeDoctor.result -eq 'HEALTHY') 'owned eight-package install upgrades to include visual-critique'

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

    $transactionRoot = Join-Path $root 'transaction tests'
    [System.IO.Directory]::CreateDirectory($transactionRoot) | Out-Null
    $transactionSource = New-FixtureSource -Root $transactionRoot
    $transactionState = Join-Path $transactionRoot 'state/install-state.json'
    $transactionTargets = @{ Codex = (Join-Path $transactionRoot 'Codex skills'); Claude = (Join-Path $transactionRoot 'Claude skills') }
    $firstFailure = & $installer -Target Codex -Apply -TestInjectStateWriteFailure -SourceRoot $transactionSource -StatePath $transactionState -TargetRootOverrides $transactionTargets
    Assert-Test ($firstFailure.results[0].status -eq 'FAILED' -and -not (Test-Path -LiteralPath (Join-Path $transactionTargets.Codex 'agent-harness-research')) -and -not (Test-Path -LiteralPath $transactionState)) 'first install state failure restores filesystem and leaves no state'

    & $installer -Target Codex -Apply -SourceRoot $transactionSource -StatePath $transactionState -TargetRootOverrides $transactionTargets | Out-Null
    $oldState = Read-AgentHarnessState -StatePath $transactionState
    $oldResearch = @($oldState.managedTargets[0].packages | Where-Object { $_.name -eq 'agent-harness-research' })[0].files
    Add-Content -LiteralPath (Join-Path $transactionSource 'skills/research/SKILL.md') -Value "`nUpdated fixture text."
    & git -C $transactionSource add skills/research/SKILL.md
    & git -C $transactionSource -c user.name='agent-harness tests' -c user.email='tests@example.invalid' commit -qm update
    $updateFailure = & $installer -Target Codex -Apply -TestInjectStateWriteFailure -SourceRoot $transactionSource -StatePath $transactionState -TargetRootOverrides $transactionTargets
    $restored = Test-AgentHarnessInventory -Root (Join-Path $transactionTargets.Codex 'agent-harness-research') -ExpectedInventory $oldResearch
    Assert-Test ($updateFailure.results[0].status -eq 'FAILED' -and $restored.Valid -and @((Read-AgentHarnessState -StatePath $transactionState).managedTargets).Count -eq 1) 'update state failure restores old packages and old state'

    $uninstallFailure = & $uninstaller -Target Codex -Apply -TestInjectStateWriteFailure -StatePath $transactionState -TargetRootOverrides $transactionTargets
    $uninstallRestored = Test-AgentHarnessInventory -Root (Join-Path $transactionTargets.Codex 'agent-harness-research') -ExpectedInventory $oldResearch
    Assert-Test ($uninstallFailure.results[0].status -eq 'FAILED' -and $uninstallRestored.Valid -and @((Read-AgentHarnessState -StatePath $transactionState).managedTargets).Count -eq 1) 'uninstall state failure restores packages and old state'

    $closureSource = New-FixtureSource -Root (Join-Path $root 'closure tests')
    Add-Content -LiteralPath (Join-Path $closureSource 'references/engineering-sources.md') -Value "`n[verification template](../templates/verification-report.md)"
    $closureOutput = Join-Path $root 'closure packages'
    New-AgentHarnessPackages -SourceRoot $closureSource -OutputRoot $closureOutput | Out-Null
    Assert-Test (Test-Path -LiteralPath (Join-Path $closureOutput 'agent-harness-research/templates/verification-report.md')) 'transitive support dependency is copied package-locally'
    Add-Content -LiteralPath (Join-Path $closureSource 'references/engineering-sources.md') -Value "`n[missing](../templates/missing.md)"
    $closureFailure = $null
    try { New-AgentHarnessPackages -SourceRoot $closureSource -OutputRoot (Join-Path $root 'closure failure') | Out-Null } catch { $closureFailure = $_.Exception.Message }
    Assert-Test ($closureFailure -match 'Unsupported support dependency|does not exist') 'missing transitive support dependency fails packaging'

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
