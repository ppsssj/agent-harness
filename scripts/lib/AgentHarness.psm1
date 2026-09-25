Set-StrictMode -Version Latest

$script:SchemaVersion = 1
$script:ExpectedSkills = @(
    'research',
    'design-research',
    'frontend-design',
    'architecture',
    'implementation',
    'root-cause',
    'verification',
    'pr'
)

function Get-AgentHarnessExpectedSkills {
    [CmdletBinding()]
    param()

    return @($script:ExpectedSkills)
}

function Get-AgentHarnessPackageName {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$SourceSkillName)

    if ($SourceSkillName -notin $script:ExpectedSkills) {
        throw "Unknown source skill '$SourceSkillName'."
    }
    return "agent-harness-$SourceSkillName"
}

function Get-AgentHarnessCanonicalPath {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    return [System.IO.Path]::GetFullPath($Path)
}

function Get-AgentHarnessRelativePath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$From,
        [Parameter(Mandatory)][string]$To
    )

    $fromPath = (Get-AgentHarnessCanonicalPath -Path $From).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar) + [System.IO.Path]::DirectorySeparatorChar
    $toPath = Get-AgentHarnessCanonicalPath -Path $To
    $fromUri = New-Object System.Uri($fromPath)
    $toUri = New-Object System.Uri($toPath)
    return [System.Uri]::UnescapeDataString($fromUri.MakeRelativeUri($toUri).ToString()).Replace('\', '/')
}

function Test-AgentHarnessPathWithin {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Root
    )

    $canonicalPath = Get-AgentHarnessCanonicalPath -Path $Path
    $canonicalRoot = Get-AgentHarnessCanonicalPath -Path $Root
    $separator = [System.IO.Path]::DirectorySeparatorChar
    $rootWithSeparator = $canonicalRoot.TrimEnd($separator, [System.IO.Path]::AltDirectorySeparatorChar) + $separator
    return $canonicalPath.StartsWith($rootWithSeparator, [System.StringComparison]::OrdinalIgnoreCase) -or
        $canonicalPath.Equals($canonicalRoot, [System.StringComparison]::OrdinalIgnoreCase)
}

function Test-AgentHarnessReparsePoint {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) { return $false }
    return ([System.IO.FileAttributes](Get-Item -LiteralPath $Path -Force).Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0
}

function Test-AgentHarnessSafeTree {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $canonicalRoot = Get-AgentHarnessCanonicalPath -Path $Root
    if (-not (Test-Path -LiteralPath $canonicalRoot)) { throw "Path does not exist: $canonicalRoot" }
    $pending = New-Object 'System.Collections.Generic.Stack[string]'
    $pending.Push($canonicalRoot)
    while ($pending.Count -gt 0) {
        $current = $pending.Pop()
        if (-not (Test-AgentHarnessPathWithin -Path $current -Root $canonicalRoot)) { throw "Path escapes managed tree: $current" }
        $item = Get-Item -LiteralPath $current -Force
        if (([System.IO.FileAttributes]$item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Reparse point is not allowed in managed tree: $current" }
        if ($item.PSIsContainer) {
            foreach ($child in (Get-ChildItem -LiteralPath $current -Force)) { $pending.Push($child.FullName) }
        }
    }
    return $true
}

function Get-AgentHarnessHomePath {
    [CmdletBinding()]
    param()

    $profile = [Environment]::GetFolderPath([Environment+SpecialFolder]::UserProfile)
    if ([string]::IsNullOrWhiteSpace($profile)) { throw 'Unable to resolve the current user profile.' }
    return Get-AgentHarnessCanonicalPath -Path $profile
}

function Resolve-AgentHarnessTargetRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][ValidateSet('Codex', 'Claude')][string]$TargetHost,
        [hashtable]$TargetRootOverrides
    )

    if ($null -ne $TargetRootOverrides -and $TargetRootOverrides.ContainsKey($TargetHost)) {
        return Get-AgentHarnessCanonicalPath -Path ([string]$TargetRootOverrides[$TargetHost])
    }

    $home = Get-AgentHarnessHomePath
    if ($TargetHost -eq 'Codex') {
        return Join-Path $home '.agents/skills'
    }

    if (-not [string]::IsNullOrWhiteSpace($env:CLAUDE_CONFIG_DIR)) {
        if (-not [System.IO.Path]::IsPathRooted($env:CLAUDE_CONFIG_DIR)) {
            throw 'CLAUDE_CONFIG_DIR must be an absolute path.'
        }
        return Join-Path (Get-AgentHarnessCanonicalPath -Path $env:CLAUDE_CONFIG_DIR) 'skills'
    }
    return Join-Path $home '.claude/skills'
}

function Get-AgentHarnessDefaultStatePath {
    [CmdletBinding()]
    param()

    return Join-Path (Get-AgentHarnessHomePath) '.agent-harness/install-state.json'
}

function Resolve-AgentHarnessSelection {
    [CmdletBinding()]
    param([ValidateSet('Codex', 'Claude', 'Both')][string]$Target = 'Both')

    if ($Target -eq 'Both') { return @('Codex', 'Claude') }
    return @($Target)
}

function Get-AgentHarnessSourceTrust {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [switch]$AllowDirtySource,
        [switch]$AllowNonGitSource
    )

    $source = Get-AgentHarnessCanonicalPath -Path $SourceRoot
    if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Source root does not exist: $source" }

    $gitRoot = $null
    try { $gitRoot = (& git -C $source rev-parse --show-toplevel 2>$null).Trim() } catch { }
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($gitRoot)) {
        $head = (& git -C $source rev-parse HEAD).Trim()
        if ($LASTEXITCODE -ne 0) { throw "Unable to read Git HEAD for $source." }
        $statusLines = @(& git -C $source status --porcelain=v1 --untracked-files=all)
        if ($LASTEXITCODE -ne 0) { throw "Unable to read Git status for $source." }
        $dirty = $statusLines.Count -gt 0
        if ($dirty -and -not $AllowDirtySource) {
            throw 'Clean Git source required: tracked or untracked changes were found. Use -AllowDirtySource only after reviewing the exact snapshot.'
        }
        return [pscustomobject]@{
            Path = $source; Provenance = if ($dirty) { 'dirty-git' } else { 'clean-git' }
            GitCommit = $head; GitStatus = @($statusLines); IsClean = -not $dirty
        }
    }

    if (-not $AllowNonGitSource) {
        throw 'Git metadata is required by default. Use -AllowNonGitSource only after reviewing the complete source inventory.'
    }
    return [pscustomobject]@{
        Path = $source; Provenance = 'non-git'; GitCommit = $null; GitStatus = @(); IsClean = $false
    }
}

function Get-AgentHarnessFileInventory {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Root)

    $rootPath = Get-AgentHarnessCanonicalPath -Path $Root
    if (-not (Test-Path -LiteralPath $rootPath -PathType Container)) { throw "Inventory root does not exist: $rootPath" }
    Test-AgentHarnessSafeTree -Root $rootPath | Out-Null
    $items = Get-ChildItem -LiteralPath $rootPath -Recurse -File -Force | Sort-Object FullName
    $inventory = @()
    foreach ($item in $items) {
        if (Test-AgentHarnessReparsePoint -Path $item.FullName) { throw "Reparse-point file is not allowed: $($item.FullName)" }
        $relative = Get-AgentHarnessRelativePath -From $rootPath -To $item.FullName
        $inventory += [pscustomobject]@{ path = $relative; sha256 = (Get-FileHash -LiteralPath $item.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
    }
    return @($inventory)
}

function Test-AgentHarnessInventory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)]$ExpectedInventory
    )

    try { $actual = @(Get-AgentHarnessFileInventory -Root $Root) } catch { return [pscustomobject]@{ Valid = $false; Reason = $_.Exception.Message } }
    $expected = @($ExpectedInventory | ForEach-Object { [pscustomobject]@{ path = [string]$_.path; sha256 = [string]$_.sha256 } } | Sort-Object path)
    if ($actual.Count -ne $expected.Count) { return [pscustomobject]@{ Valid = $false; Reason = 'Installed file count differs from ownership inventory.' } }
    for ($index = 0; $index -lt $actual.Count; $index++) {
        if ($actual[$index].path -ne $expected[$index].path -or $actual[$index].sha256 -ne $expected[$index].sha256) {
            return [pscustomobject]@{ Valid = $false; Reason = "Installed file inventory differs at '$($actual[$index].path)'." }
        }
    }
    return [pscustomobject]@{ Valid = $true; Reason = $null }
}

function Get-AgentHarnessMarkdownLinks {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Content)

    return @([regex]::Matches($Content, '\[[^\]]+\]\(([^)#]+)(?:#[^)]+)?\)'))
}

function Get-AgentHarnessSourceManifest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$SkillName
    )

    $path = Join-Path $SourceRoot "skills/$SkillName/SKILL.md"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Expected source manifest missing: $path" }
    $content = Get-Content -LiteralPath $path -Raw
    $match = [regex]::Match($content, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $match.Success) { throw "Invalid frontmatter in $path" }
    $frontmatter = $match.Groups[1].Value
    $nameMatch = [regex]::Match($frontmatter, '(?m)^name:\s*([^\r\n]+)\s*$')
    $descriptionMatch = [regex]::Match($frontmatter, '(?m)^description:\s*(.+)\s*$')
    if (-not $nameMatch.Success -or $nameMatch.Groups[1].Value.Trim() -ne $SkillName) { throw "Unexpected frontmatter name in $path" }
    if (-not $descriptionMatch.Success -or [string]::IsNullOrWhiteSpace($descriptionMatch.Groups[1].Value)) { throw "Missing frontmatter description in $path" }
    return [pscustomobject]@{ Path = $path; Content = $content; FrontmatterMatch = $match; Description = $descriptionMatch.Groups[1].Value.Trim() }
}

function Copy-AgentHarnessSupportFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$SourceFile,
        [Parameter(Mandatory)][string]$PackageRoot
    )

    $relative = Get-AgentHarnessRelativePath -From $SourceRoot -To $SourceFile
    if ($relative -notmatch '^(references|templates)/') { throw "Only references/ and templates/ may be package support files: $relative" }
    if (-not (Test-Path -LiteralPath $SourceFile -PathType Leaf)) { throw "Support dependency does not exist: $relative" }
    $destination = Join-Path $PackageRoot $relative
    if (-not (Test-AgentHarnessPathWithin -Path $destination -Root $PackageRoot)) { throw "Package support path escapes its package: $relative" }
    $parent = Split-Path -Parent $destination
    [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    Copy-Item -LiteralPath $SourceFile -Destination $destination -Force
    return $relative
}

function Complete-AgentHarnessSupportClosure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$PackageRoot
    )

    $processed = @{}
    while ($true) {
        $next = @(Get-ChildItem -LiteralPath $PackageRoot -Recurse -File -Filter *.md -Force | Where-Object {
            $relative = Get-AgentHarnessRelativePath -From $PackageRoot -To $_.FullName
            $relative -match '^(references|templates)/' -and -not $processed.ContainsKey($relative)
        })
        if ($next.Count -eq 0) { break }
        foreach ($packageFile in $next) {
            $relativeFile = Get-AgentHarnessRelativePath -From $PackageRoot -To $packageFile.FullName
            $processed[$relativeFile] = $true
            $sourceFile = Join-Path $SourceRoot $relativeFile
            if (-not (Test-Path -LiteralPath $sourceFile -PathType Leaf)) { throw "Copied support file has no source counterpart: $relativeFile" }
            $sourceContent = Get-Content -LiteralPath $sourceFile -Raw
            $packageContent = Get-Content -LiteralPath $packageFile.FullName -Raw
            foreach ($link in (Get-AgentHarnessMarkdownLinks -Content $sourceContent)) {
                $rawTarget = $link.Groups[1].Value
                if ($rawTarget -match '^[a-z][a-z0-9+.-]*:' -or $rawTarget.StartsWith('#')) { continue }
                $sourceTarget = Get-AgentHarnessCanonicalPath -Path (Join-Path (Split-Path -Parent $sourceFile) $rawTarget)
                $whole = $link.Value
                $label = [regex]::Match($whole, '^\[([^\]]+)\]').Groups[1].Value
                if ((Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'references')) -or (Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'templates'))) {
                    $targetRelative = Copy-AgentHarnessSupportFile -SourceRoot $SourceRoot -SourceFile $sourceTarget -PackageRoot $PackageRoot
                    $packageTarget = Join-Path $PackageRoot $targetRelative
                    $rewritten = Get-AgentHarnessRelativePath -From (Split-Path -Parent $packageFile.FullName) -To $packageTarget
                    $packageContent = $packageContent.Replace($whole, "[$label]($rewritten)")
                    continue
                }
                if (Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'skills')) {
                    $skillRelative = Get-AgentHarnessRelativePath -From (Join-Path $SourceRoot 'skills') -To $sourceTarget
                    if ($skillRelative -notmatch '^([^/]+)/SKILL\.md$') { throw "Unexpected support cross-skill dependency: $rawTarget" }
                    $packageContent = $packageContent.Replace($whole, (Get-AgentHarnessPackageName -SourceSkillName $Matches[1]))
                    continue
                }
                if ($sourceTarget.Equals((Join-Path $SourceRoot 'AGENTS.md'), [System.StringComparison]::OrdinalIgnoreCase)) {
                    $packageContent = $packageContent.Replace($whole, 'project AGENTS.md')
                    continue
                }
                throw "Unsupported support dependency '$rawTarget' in $sourceFile"
            }
            [System.IO.File]::WriteAllText($packageFile.FullName, $packageContent, (New-Object System.Text.UTF8Encoding($false)))
        }
    }
}

function ConvertTo-AgentHarnessPackageContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Manifest,
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$SkillName,
        [Parameter(Mandatory)][string]$PackageRoot
    )

    $content = $Manifest.Content
    $links = Get-AgentHarnessMarkdownLinks -Content $content
    foreach ($link in $links) {
        $rawTarget = $link.Groups[1].Value
        if ($rawTarget -match '^[a-z][a-z0-9+.-]*:' -or $rawTarget.StartsWith('#')) { continue }
        $sourceTarget = Get-AgentHarnessCanonicalPath -Path (Join-Path (Split-Path -Parent $Manifest.Path) $rawTarget)
        $whole = $link.Value
        $label = [regex]::Match($whole, '^\[([^\]]+)\]').Groups[1].Value
        if (Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'skills')) {
            $relativeSkill = Get-AgentHarnessRelativePath -From (Join-Path $SourceRoot 'skills') -To $sourceTarget
            if ($relativeSkill -notmatch '^([^/]+)/SKILL\.md$') { throw "Unexpected cross-skill link: $rawTarget" }
            $related = $Matches[1]
            $replacement = Get-AgentHarnessPackageName -SourceSkillName $related
            $content = $content.Replace($whole, $replacement)
            continue
        }
        if (Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'references')) {
            $relative = Copy-AgentHarnessSupportFile -SourceRoot $SourceRoot -SourceFile $sourceTarget -PackageRoot $PackageRoot
            $content = $content.Replace($whole, "[$label]($relative)")
            continue
        }
        if (Test-AgentHarnessPathWithin -Path $sourceTarget -Root (Join-Path $SourceRoot 'templates')) {
            $relative = Copy-AgentHarnessSupportFile -SourceRoot $SourceRoot -SourceFile $sourceTarget -PackageRoot $PackageRoot
            $content = $content.Replace($whole, "[$label]($relative)")
            continue
        }
        if ($sourceTarget.Equals((Join-Path $SourceRoot 'AGENTS.md'), [System.StringComparison]::OrdinalIgnoreCase)) {
            $content = $content.Replace($whole, 'project AGENTS.md')
            continue
        }
        throw "Unsupported package dependency '$rawTarget' in $($Manifest.Path)."
    }

    $frontmatter = $Manifest.FrontmatterMatch.Value
    $replacementFrontmatter = [regex]::Replace($frontmatter, '(?m)^name:\s*[^\r\n]+$', "name: $(Get-AgentHarnessPackageName -SourceSkillName $SkillName)")
    return $content.Substring(0, $Manifest.FrontmatterMatch.Index) + $replacementFrontmatter + $content.Substring($Manifest.FrontmatterMatch.Index + $Manifest.FrontmatterMatch.Length)
}

function Test-AgentHarnessPackageRoot {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$PackageRoot)

    $root = Get-AgentHarnessCanonicalPath -Path $PackageRoot
    if (-not (Test-Path -LiteralPath $root -PathType Container)) { throw "Package root missing: $root" }
    Test-AgentHarnessSafeTree -Root $root | Out-Null
    $manifestPath = Join-Path $root 'SKILL.md'
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Package manifest missing: $manifestPath" }
    $manifests = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter SKILL.md -Force)
    if ($manifests.Count -ne 1) { throw "A package must contain exactly one SKILL.md: $root" }
    $content = Get-Content -LiteralPath $manifestPath -Raw
    $frontmatter = [regex]::Match($content, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $frontmatter.Success) { throw "Invalid package frontmatter: $manifestPath" }
    $name = [regex]::Match($frontmatter.Groups[1].Value, '(?m)^name:\s*([^\r\n]+)\s*$')
    $description = [regex]::Match($frontmatter.Groups[1].Value, '(?m)^description:\s*(.+)\s*$')
    $expectedNames = @($script:ExpectedSkills | ForEach-Object { Get-AgentHarnessPackageName -SourceSkillName $_ })
    if (-not $name.Success -or $name.Groups[1].Value.Trim() -notin $expectedNames) { throw "Invalid package name in $manifestPath" }
    if (-not $description.Success -or [string]::IsNullOrWhiteSpace($description.Groups[1].Value)) { throw "Missing package description in $manifestPath" }

    foreach ($markdown in (Get-ChildItem -LiteralPath $root -Recurse -File -Filter *.md -Force)) {
        $markdownContent = Get-Content -LiteralPath $markdown.FullName -Raw
        foreach ($link in (Get-AgentHarnessMarkdownLinks -Content $markdownContent)) {
            $target = $link.Groups[1].Value
            if ($target -match '^[a-z][a-z0-9+.-]*:' -or $target.StartsWith('#')) { continue }
            $resolved = Get-AgentHarnessCanonicalPath -Path (Join-Path (Split-Path -Parent $markdown.FullName) $target)
            if (-not (Test-AgentHarnessPathWithin -Path $resolved -Root $root) -or -not (Test-Path -LiteralPath $resolved -PathType Leaf)) {
                throw "Package-local Markdown link does not resolve inside package: $target"
            }
        }
    }

    $relatedMatch = [regex]::Match($content, '(?ms)^## Related\s*\r?\n(.*?)(?=^## |\z)')
    if ($relatedMatch.Success) {
        $ids = [regex]::Matches($relatedMatch.Groups[1].Value, '\bagent-harness-[a-z-]+\b') | ForEach-Object { $_.Value }
        foreach ($id in $ids) {
            if ($id -notin ($script:ExpectedSkills | ForEach-Object { "agent-harness-$_" })) { throw "Unknown related skill identifier '$id' in $manifestPath" }
        }
        if ($relatedMatch.Groups[1].Value -match '\]\([^)]*SKILL\.md') { throw "Related skills may not use filesystem links in $manifestPath" }
    }
    return $true
}

function New-AgentHarnessPackages {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$OutputRoot
    )

    $source = Get-AgentHarnessCanonicalPath -Path $SourceRoot
    $output = Get-AgentHarnessCanonicalPath -Path $OutputRoot
    if (Test-AgentHarnessPathWithin -Path $output -Root $source) { throw 'Package output must not be inside the source checkout.' }
    if (Test-Path -LiteralPath $output) {
        if ((Get-ChildItem -LiteralPath $output -Force | Measure-Object).Count -ne 0) { throw "Package output root must be empty: $output" }
    } else { [System.IO.Directory]::CreateDirectory($output) | Out-Null }

    $seen = @{}
    foreach ($skill in $script:ExpectedSkills) {
        $packageName = Get-AgentHarnessPackageName -SourceSkillName $skill
        if ($seen.ContainsKey($packageName.ToLowerInvariant())) { throw "Duplicate case-insensitive package destination: $packageName" }
        $seen[$packageName.ToLowerInvariant()] = $true
        $packageRoot = Join-Path $output $packageName
        [System.IO.Directory]::CreateDirectory($packageRoot) | Out-Null
        $manifest = Get-AgentHarnessSourceManifest -SourceRoot $source -SkillName $skill
        $content = ConvertTo-AgentHarnessPackageContent -Manifest $manifest -SourceRoot $source -SkillName $skill -PackageRoot $packageRoot
        [System.IO.File]::WriteAllText((Join-Path $packageRoot 'SKILL.md'), $content, (New-Object System.Text.UTF8Encoding($false)))
        Complete-AgentHarnessSupportClosure -SourceRoot $source -PackageRoot $packageRoot
        Test-AgentHarnessPackageRoot -PackageRoot $packageRoot | Out-Null
    }
    return @($script:ExpectedSkills | ForEach-Object { Join-Path $output (Get-AgentHarnessPackageName -SourceSkillName $_) })
}

function Read-AgentHarnessState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$StatePath)

    if (-not (Test-Path -LiteralPath $StatePath -PathType Leaf)) { return $null }
    try { $state = Get-Content -LiteralPath $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json } catch { throw "State file is invalid and will not be trusted: $StatePath" }
    if ($state.schemaVersion -ne $script:SchemaVersion -or $null -eq $state.managedTargets) { throw "State file has an unsupported schema: $StatePath" }
    return $state
}

function Write-AgentHarnessState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$State,
        [Parameter(Mandatory)][string]$StatePath,
        [switch]$TestInjectFailure
    )

    $statePath = Get-AgentHarnessCanonicalPath -Path $StatePath
    $stateDirectory = Split-Path -Parent $statePath
    if (Test-Path -LiteralPath $stateDirectory) {
        if (Test-AgentHarnessReparsePoint -Path $stateDirectory) { throw "State directory is a reparse point: $stateDirectory" }
    } else { [System.IO.Directory]::CreateDirectory($stateDirectory) | Out-Null }
    if ((Test-Path -LiteralPath $statePath) -and (Test-AgentHarnessReparsePoint -Path $statePath)) { throw "State file is a reparse point: $statePath" }
    $temporary = Join-Path $stateDirectory ('.install-state.' + [guid]::NewGuid().ToString('N') + '.tmp')
    $backup = Join-Path $stateDirectory ('.install-state.' + [guid]::NewGuid().ToString('N') + '.bak')
    $replaced = $false
    try {
        $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes(($State | ConvertTo-Json -Depth 12))
        $stream = New-Object System.IO.FileStream($temporary, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
        try { $stream.Write($bytes, 0, $bytes.Length); $stream.Flush($true) } finally { $stream.Dispose() }
        if ($TestInjectFailure) { throw 'Injected state commit failure.' }
        if (Test-Path -LiteralPath $statePath) {
            [System.IO.File]::Replace($temporary, $statePath, $backup, $true)
            $replaced = $true
        } else {
            [System.IO.File]::Move($temporary, $statePath)
        }
        $validated = Read-AgentHarnessState -StatePath $statePath
        if ($null -eq $validated -or $validated.schemaVersion -ne $script:SchemaVersion) { throw "State validation failed after commit: $statePath" }
        if (Test-Path -LiteralPath $backup) { Remove-Item -LiteralPath $backup -Force }
    } catch {
        if ($replaced -and (Test-Path -LiteralPath $backup)) {
            try { [System.IO.File]::Copy($backup, $statePath, $true) } catch { throw "State commit and recovery failed. Previous state backup retained at $backup. $($_.Exception.Message)" }
        }
        throw
    } finally {
        if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Force }
    }
}

Export-ModuleMember -Function @(
    'Get-AgentHarnessExpectedSkills', 'Get-AgentHarnessPackageName', 'Get-AgentHarnessCanonicalPath', 'Get-AgentHarnessRelativePath',
    'Test-AgentHarnessPathWithin', 'Test-AgentHarnessReparsePoint', 'Test-AgentHarnessSafeTree', 'Resolve-AgentHarnessTargetRoot',
    'Get-AgentHarnessDefaultStatePath', 'Resolve-AgentHarnessSelection', 'Get-AgentHarnessSourceTrust',
    'Get-AgentHarnessFileInventory', 'Test-AgentHarnessInventory', 'New-AgentHarnessPackages',
    'Test-AgentHarnessPackageRoot', 'Read-AgentHarnessState', 'Write-AgentHarnessState'
)
