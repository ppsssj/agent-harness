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

Requirements, frontend architecture, design system, relevant [DESIGN.md](../../templates/DESIGN.md), and design-research synthesis plus its Reference Lock Human Approval status when the visual direction is unsettled.

## Workflow

1. Inspect components, tokens, routing, responsiveness, and existing patterns.
2. Decide if design research is needed; normally run it for greenfield visual work.
3. For significant unsettled visual work, inspect the Design Synthesis Proposal and Reference Lock before implementation. Implement only when the recorded status is exactly `APPROVED` or `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`, the material direction has a PRESERVE / ADAPT / INVENT map, and every Major Visual Decision has recorded valid provenance. If any are `PENDING`, missing, unresolved, or unsupported, stop and return to design-research; do not edit implementation files or begin visual implementation.
4. Preserve the established system or implement the approved direction without inventing a parallel design system. PRESERVE elements should remain recognizably faithful to the approved reference decision; ADAPT elements must reflect their recorded reason; INVENT elements must satisfy their documented product need. Do not silently redesign that direction after its human checkpoint.
5. Render the changed surface. For significant visual work, hand the rendered result to [visual-critique](../visual-critique/SKILL.md) after the first implementation and before completion; apply only the technical and within-lock refinements it permits, return to design-research when it identifies a directional weakness that needs a new major decision, and re-render after each pass. Tiny fixes and changes fully governed by an existing system skip this loop.
6. Proceed to mechanical verification of responsive states, keyboard/focus behavior, accessibility, and performance sanity only after the visual state is acceptable or its remaining caveats are explicitly reported. Do not claim visual completion from code inspection alone.

If an implementation constraint requires changing the approved synthesis, stop and surface the conflict. Do not drift toward generic model-prior aesthetics.

## Stop conditions

Stop when a needed product or visual direction decision is unresolved, the system constraints conflict, or visual critique exposes a directional weakness requiring a return to design research and renewed approval.

## Output and verification

Report the approved direction, affected surfaces, responsive/accessibility findings, fresh render evidence, and the visual-critique status for significant visual work. Use [verification](../verification/SKILL.md) for the gate report.

## Related

[design-research](../design-research/SKILL.md), [visual-critique](../visual-critique/SKILL.md), [implementation](../implementation/SKILL.md), [verification](../verification/SKILL.md)
