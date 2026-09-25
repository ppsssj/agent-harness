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

Requirements, frontend architecture, design system, relevant [DESIGN.md](../../templates/DESIGN.md), and approved design-research synthesis when the visual direction is unsettled.

## Workflow

1. Inspect components, tokens, routing, responsiveness, and existing patterns.
2. Decide if design research is needed; normally run it for greenfield visual work.
3. For significant unsettled visual work, consume the approved Design Synthesis Proposal and Reference Lock before implementation. Do not silently redesign that direction after its human checkpoint.
4. Preserve the established system or implement the approved direction without inventing a parallel design system. PRESERVE elements should remain recognizably faithful to the approved reference decision; ADAPT elements must reflect their recorded reason; INVENT elements must satisfy their documented product need.
5. Verify render, responsive states, keyboard/focus behavior, accessibility, performance sanity, and visual consistency.

If an implementation constraint requires changing the approved synthesis, stop and surface the conflict. Do not drift toward generic model-prior aesthetics.

## Stop conditions

Stop when a needed product or visual direction decision is unresolved, the system constraints conflict, or visual verification exposes a problem requiring a return to design research.

## Output and verification

Report the approved direction, affected surfaces, responsive/accessibility findings, and fresh render evidence. Use [verification](../verification/SKILL.md) for the gate report.

## Related

[design-research](../design-research/SKILL.md), [implementation](../implementation/SKILL.md), [verification](../verification/SKILL.md)
