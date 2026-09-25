---
name: implementation
description: Make a small, coherent, understood engineering change and prove its intended behavior.
---

# Implementation

## Use when

The problem, scope, conventions, and intended solution are understood.

## Do not use when

Root cause, architecture, visual direction, or key requirements remain uncertain; return to the appropriate discovery skill.

## Inputs

Scope, relevant files and conventions, invariants, approved decision/plan where needed, and verification expectations.

## Workflow

1. Reconfirm scope, affected files, conventions, and invariants.
2. State small implementation steps and make focused edits.
3. Add or update regression protection where appropriate.
4. Run relevant mechanical checks, inspect the diff, and update behavior or contract documentation when needed.

## Stop conditions

Stop and return to research or architecture if evidence invalidates the plan; stop for an owner decision if compatibility must intentionally change.

## Output and verification

Report changed behavior, files, compatibility impact, and evidence using [verification](../verification/SKILL.md). No unrelated refactors, speculative abstractions, or unjustified dependencies.

## Related

[architecture](../architecture/SKILL.md), [root-cause](../root-cause/SKILL.md), [verification](../verification/SKILL.md)
