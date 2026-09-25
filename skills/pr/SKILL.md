---
name: pr
description: Prepare a transparent, reviewable pull request without merging or concealing risk.
---

# Pull Request

## Use when

A change is ready to be packaged for review or its review readiness must be assessed.

## Do not use when

The implementation or required verification is incomplete, or no reviewable change exists.

## Inputs

Target branch, intended scope, working tree and diff, verification evidence, CI state when available, and visual evidence when applicable.

## Workflow

1. Inspect working tree and diff; confirm scope and check for generated or secret files.
2. Run or review relevant verification; do not hide failures.
3. Create a clear commit and PR when authorized, without merging.
4. Write summary, why, changes, verification, risks, screenshots for visual work, follow-ups, and CI state.

## Stop conditions

Stop and report when required checks fail, scope is unclear, credentials are present, or repository permissions prevent publication. Never mark a PR ready when required checks fail.

## Output and verification

Provide branch, commit, PR URL if created, CI state, and remaining risk. Verify the published diff matches the reviewed local diff.

## Related

[verification](../verification/SKILL.md), [implementation](../implementation/SKILL.md), [AGENTS.md](../../AGENTS.md)
