# Installation

agent-harness v0.2 installs eight self-contained, namespaced skill packages for native Windows hosts. It copies a verified snapshot; it does not install repository `AGENTS.md` or `CLAUDE.md`, edit host configuration, create links, alter PATH, or change project files.

## Requirements

- PowerShell 5.1 or later and Git for the default clean-source policy.
- A clean clone of this repository. Tracked and untracked changes both make a normal install refuse.
- A normal user-writable host skill root. Administrator elevation is neither needed nor attempted.

Native Windows and WSL are separate environments. Run the scripts in the environment where the target host runs.

## Preview, then apply

From the repository root, preview the changes first. Preview creates only transient package-validation staging; it does not change host skill roots or state.

```powershell
.\scripts\install.ps1 -Target Both
```

Apply only after reviewing the source revision, provenance, paths, and planned results:

```powershell
.\scripts\install.ps1 -Target Both -Apply
```

Select one host with `-Target Codex` or `-Target Claude`.

Codex installs below `%USERPROFILE%\.agents\skills`. Claude installs below `%CLAUDE_CONFIG_DIR%\skills` when `CLAUDE_CONFIG_DIR` is set; otherwise it uses `%USERPROFILE%\.claude\skills`.

The packages are `agent-harness-research`, `agent-harness-design-research`, `agent-harness-frontend-design`, `agent-harness-architecture`, `agent-harness-implementation`, `agent-harness-root-cause`, `agent-harness-verification`, and `agent-harness-pr`.

## Updates and source trust

Update the repository through your normal reviewed Git workflow, then preview and apply again. The installer never pulls, resets, checks out, cleans, or otherwise changes the source repository.

`-AllowDirtySource` and `-AllowNonGitSource` are explicit exceptions for a reviewed snapshot. Their state record captures provenance, Git status when available, and installed content hashes. They should not be used for ordinary updates.

An existing package is replaced only if agent-harness state proves ownership and every recorded hash still matches. A same-named foreign package, a modified package, a stale state entry, a path escape, or a reparse point is a safe refusal, not an overwrite.

## Doctor

```powershell
.\scripts\doctor.ps1 -Target Codex
.\scripts\doctor.ps1 -Target Both
```

Doctor reports `MANAGED_HEALTHY`, `MANAGED_DEGRADED`, `UNMANAGED_INSTALLED`, or `NOT_INSTALLED` for selected targets, and `UNSELECTED` for the other host, then an overall `HEALTHY`, `DEGRADED`, or `BROKEN` result. A host not selected for the command is not evaluated and cannot degrade the selected host.

Doctor validates filesystem and discovery prerequisites, ownership state, package manifests, package-local links, namespaced related-skill identifiers, containment, and hashes. It always states: “Filesystem/discovery prerequisites validated; model skill selection is not proven by doctor.” Start a fresh host session and use the behavioral smoke-test plan in [V0.2_INSTALLATION_DESIGN.md](V0.2_INSTALLATION_DESIGN.md) to assess actual model behavior.

## Uninstall

Preview removal first:

```powershell
.\scripts\uninstall.ps1 -Target Both
```

Then apply it:

```powershell
.\scripts\uninstall.ps1 -Target Both -Apply
```

Uninstall reads `%USERPROFILE%\.agent-harness\install-state.json` (outside host directories), recomputes all hashes, and deletes only unmodified owned package directories. Modified, foreign, missing, or unsafe paths are preserved for manual cleanup. It never deletes a whole host skill directory. The state file is removed only after its final managed target is successfully removed.

## Windows and Unicode

The scripts use literal paths, .NET path APIs, and UTF-8 JSON to support spaces and Unicode profile paths. They reject managed destination reparse points and do not bridge Windows and WSL automatically.
