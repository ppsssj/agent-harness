---
name: frontend-design
description: Implement an intentional, accessible frontend while preserving product conventions and validating the rendered result.
---

# Frontend Design

## Use when

Building or materially revising a UI surface.

## Do not use when

The task is non-visual backend work, a pure bug investigation, or a trivial style correction with no design decision.

## Inputs

Requirements, frontend architecture, design system, relevant [DESIGN.md](../../templates/DESIGN.md), and design-research output when the visual direction is unsettled.

## Workflow

1. Inspect components, tokens, routing, responsiveness, and existing patterns.
2. Decide if design research is needed; normally run it for greenfield visual work.
3. Preserve the established system or define an intentional direction and implementation plan.
4. Implement coherent, accessible UI changes without inventing a parallel design system.
5. Verify render, responsive states, keyboard/focus behavior, accessibility, performance sanity, and visual consistency.

## Stop conditions

Stop when a needed product or visual direction decision is unresolved, the system constraints conflict, or visual verification exposes a problem requiring a return to design research.

## Output and verification

Report the direction, affected surfaces, responsive/accessibility findings, and fresh render evidence. Use [verification](../verification/SKILL.md) for the gate report.

## Related

[design-research](../design-research/SKILL.md), [implementation](../implementation/SKILL.md), [verification](../verification/SKILL.md)
