---
name: design-research
description: Establish a reference-led visual direction before significant frontend design work.
---

# Design Research

## Use when

Creating a meaningful greenfield visual surface, substantially changing a visual direction, or when a product lacks a settled design system.

## Do not use when

A small UI change is governed by an existing system or a visual direction is already documented and sufficient.

## Inputs

Product and audience, surface and primary task, existing system, brand/accessibility/performance constraints, and visual ambition.

## Workflow

For meaningful greenfield or substantial visual work, use this flow:

1. **Understand product.** Inspect product context, audience, primary task, and existing conventions.
2. **Classify surface.** Identify the surface type and whether reference research is needed.
3. **Inspect real references.** Route with [design discovery sources](../../references/design-sources.md), favoring product references for product UX. A reference counts only when it was retrieved and examined during this task; prior model knowledge does not count as inspected research.
4. **Decompose elements.** For each meaningful reference, record its site/project name, exact URL when available, discovery source, and observations that actually support the proposed use. Observe only the relevant categories: composition, hierarchy, grid, typography, spacing, color, navigation, product presentation, cards, interaction, motion, section transitions, or content structure.
5. **Map elements.** Identify which concrete elements will inform the work, rather than extracting only an abstract mood. Significant open-ended visual work normally inspects multiple useful references, but do not impose an arbitrary count when fewer are sufficient.
6. **Decide preserve, adapt, or invent.** Use **PRESERVE** when a reference already solves the problem and no concrete project reason requires change. Use **ADAPT** only for a recorded reason such as brand/system constraints, product semantics, accessibility, responsiveness, performance, or reconciliation with another reference. Use **INVENT** only for a product-specific need the references do not solve or to reconcile selected references. Invention is optional.
7. **Present a Design Synthesis Proposal.** Use the [Reference Lock](../../templates/reference-lock.md) to explain the evidence, element map, product-specific decisions, and final combination in human-readable form. Major visual choices--palette, typography, hero, cards, radius language, motion, motifs, and section composition--must have provenance: reference, existing brand/design system, product requirement, or accessibility/technical constraint.
8. **Set the checkpoint status.** Default the Reference Lock Human Approval status to `PENDING`. The checkpoint may be skipped only for tiny visual fixes, work fully governed by an existing system, an already-approved direction, or an explicit user instruction to proceed without intermediate review. An ordinary request for eventual implementation--for example, "design and implement this," "create this page," "build a new landing page," or "make a portfolio and implement it"--does **not** waive the checkpoint. A valid waiver clearly says not to ask for approval, to proceed without checkpoints, to make the decisions and implement directly, to work autonomously without waiting, or equivalent explicit language. Record only that case as `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`.
9. **Human checkpoint.** When the status is `PENDING`, present the Design Synthesis Proposal and stop the turn for approval or modification. Do not require a questionnaire: the human can say, for example, "Use A's hero instead," "Keep B's card colors," or "Proceed."
10. **Enforce the hard pre-implementation gate.** For significant unsettled visual work, before the Reference Lock status is `APPROVED` or `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`, the agent may inspect repository files and constraints, retrieve and analyze references, prepare the proposal, and report it to the human. It must **not** modify application source files or stylesheets, replace markup, create implementation components, begin visual implementation, or make implementation edits justified by the unapproved direction. When status is `PENDING`, the proposal must be shown to the human and the turn must stop there.
11. **Lock direction and hand off.** After actual human approval, set status to `APPROVED` and record concise approval evidence or requested changes. Only an `APPROVED` or `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION` lock may hand off its synthesis to [frontend-design](../frontend-design/SKILL.md); follow it with visual verification.

External research must materially affect the proposal. If research is appropriate but no usable references can be inspected, say so and do not fabricate a Reference Lock.

Default to moderate-to-high reference fidelity. Preserve a strong reference's composition, proportions, hierarchy, spacing rhythm, interaction concept, card or section structure, typography treatment, or color treatment when they fit. Adapt only the dimensions that conflict with concrete project constraints; do not make cosmetic changes merely to appear original.

Implement independently. Do not copy source code, proprietary images or assets, logos or brand marks as the user's own, or large blocks of copy. Layout approaches, composition, hierarchy, spacing, typography treatments, interaction patterns, and product-presentation techniques may inform the work.

## Stop conditions

Stop when an approval is pending and wait for the human, when the direction is approved and actionable, local conventions make external research unnecessary, usable references cannot be inspected, or a product/brand decision needs human input. If implementation constraints conflict with an approved direction, return the conflict to the human rather than silently redesigning it.

## Output and verification

Return the inspected reference evidence, element-level PRESERVE / ADAPT / INVENT map, Design Synthesis Proposal, explicit Human Approval status, final synthesis, and open risks. Verify cited references support the stated observations, major aesthetic choices have provenance, the pre-implementation gate was honored, and the direction does not drift into unsourced generic styling.

## Related

[frontend-design](../frontend-design/SKILL.md), [research](../research/SKILL.md), [DESIGN.md](../../templates/DESIGN.md)
