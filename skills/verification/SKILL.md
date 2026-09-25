---
name: verification
description: Choose, execute, and transparently report fresh mechanical evidence for a change.
---

# Verification

## Use when

Completing, reviewing, or preparing a change whose behavior or quality needs evidence.

## Do not use when

No change or decision needs validation; do not run ceremonial unrelated checks.

## Inputs

Changed behavior, project capabilities, risk/invariants, affected surface, and project-defined verification commands.

## Workflow

1. Discover verification commands from the repository first: package scripts, Makefile or task-runner configuration, CI workflows, project docs, and existing agent instructions. Do not invent or hardcode commands the project does not define.
2. Select proportionate gates using [verification rules](../../references/verification-rules.md).
3. Run focused checks first, then broader relevant gates.
4. Inspect diff and working tree; include runtime/browser evidence for user-facing behavior where available.
5. For significant visual work, record the [visual-critique](../visual-critique/SKILL.md) final status as an evidence item alongside the mechanical gates. Do not re-run the critique here or merge it into a gate; report `VISUAL_NOT_AVAILABLE` as such, never as `PASS`.
6. Record every relevant gate in [verification-report.md](../../templates/verification-report.md).

## Stop conditions

Stop when relevant gates have fresh outcomes, or report a blocker/unavailable capability. A failure is a result to report, not a reason to omit the gate.

## Output and verification

Report `PASS`, `FAIL`, `NOT AVAILABLE`, or `NOT RUN`, with commands and observations. Completion claims must match this evidence.

## Related

[implementation](../implementation/SKILL.md), [root-cause](../root-cause/SKILL.md), [visual-critique](../visual-critique/SKILL.md), [pr](../pr/SKILL.md)
