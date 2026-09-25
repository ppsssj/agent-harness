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
4. **Decompose elements.** For each meaningful reference, record its site/project name, exact URL when available, discovery source, and observations that actually support the proposed use. Observe only the relevant categories: composition, hierarchy, grid, typography, spacing, color, navigation, product presentation, cards, interaction, motion, section transitions, or content structure. Evidence must support the specificity of the proposed treatment: an observation of "large type" does not support an unobserved condensed grotesk, extreme scale, tight tracking, and mono-label system.
5. **Map elements.** Identify which concrete elements will inform the work, rather than extracting only an abstract mood. Significant open-ended visual work normally inspects multiple useful references, but do not impose an arbitrary count when fewer are sufficient.
6. **Decide preserve, adapt, or invent.** Use **PRESERVE** when a reference already solves the problem and no concrete project reason requires change. Use **ADAPT** only for a recorded reason such as brand/system constraints, product semantics, accessibility, responsiveness, performance, or reconciliation with another reference. Use **INVENT** only for an identified product-specific need the references do not solve or to reconcile selected references. Before proposing INVENT, identify the unmet need, explain why the references are insufficient, and include the invention in the proposal; never assign INVENT after implementation to justify an aesthetic choice. Invention is optional.
7. **Create the Major Visual Decision Map.** Before the proposal, use the [Reference Lock](../../templates/reference-lock.md) to map each page-defining decision that is relevant: background or tonal treatment, primary text, accent role, typography character, hero, navigation, project/content presentation, surfaces, section composition, contrast sections, metadata, motion, or recurring motif. Record the proposed treatment, specific provenance, and PRESERVE / ADAPT / INVENT decision. Major decisions need valid provenance: **REFERENCE**, **EXISTING BRAND / DESIGN SYSTEM**, **PRODUCT REQUIREMENT**, or **ACCESSIBILITY / TECHNICAL CONSTRAINT**. This is decision-level provenance, not pixel-level copying: a reference-supported warm off-white field may be calibrated to a suitable hex, and a reference-supported condensed display treatment may use a suitable font, size, line-height, or tracking.
8. **Gate unsourced decisions.** Inspect the Major Visual Decision Map before presenting the proposal. If an important decision lacks sufficient provenance, do not fill it from model prior. Inspect another reference, derive it from an existing project constraint, document a real prospective product need for INVENT, or leave it unresolved and ask the human. Significant unresolved decisions block implementation.
9. **Present a Design Synthesis Proposal.** Create the Reference Lock before application source or style implementation, in this order: Reference Evidence, Element Map, Major Visual Decision Map, Design Synthesis Proposal, Human Approval, implementation. Explain the evidence, maps, product-specific decisions, and final combination in human-readable form.
10. **Set the checkpoint status.** Default the Reference Lock Human Approval status to `PENDING`. The checkpoint may be skipped only for tiny visual fixes, work fully governed by an existing system, an already-approved direction, or an explicit user instruction to proceed without intermediate review. An ordinary request for eventual implementation--for example, "design and implement this," "create this page," "build a new landing page," or "make a portfolio and implement it"--does **not** waive the checkpoint. A valid waiver clearly says not to ask for approval, to proceed without checkpoints, to make the decisions and implement directly, to work autonomously without waiting, or equivalent explicit language. Record only that case as `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`.
11. **Human checkpoint.** When the status is `PENDING`, present the Design Synthesis Proposal and stop the turn for approval or modification. Do not require a questionnaire: the human can say, for example, "Use A's hero instead," "Keep B's card colors," or "Proceed."
12. **Enforce the hard pre-implementation gate.** For significant unsettled visual work, before the Reference Lock status is `APPROVED` or `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`, the agent may inspect repository files and constraints, retrieve and analyze references, prepare the Reference Lock and proposal, and report it to the human. It must **not** modify application source files or stylesheets, replace markup, create implementation components, begin visual implementation, or make implementation edits justified by the unapproved direction. When status is `PENDING`, the proposal must be shown to the human and the turn must stop there.
13. **Lock direction and hand off.** After actual human approval, set status to `APPROVED` and record concise approval evidence or requested changes. Only an `APPROVED` or `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION` lock with complete element and Major Visual Decision Maps may hand off its synthesis to [frontend-design](../frontend-design/SKILL.md); follow it with [visual-critique](../visual-critique/SKILL.md) of the rendered result and then verification. [DESIGN.md](../../templates/DESIGN.md) may be finalized after approval, but its recorded decisions must come from the approved pre-implementation synthesis.

**Targeted return from visual critique.** When visual-critique reports a DIRECTIONAL_WEAKNESS, do not restart from zero. Keep the approved decisions that still work, and research only the observed weakness--for example project presentation, hero composition, section rhythm, or interaction structure--unless evidence justifies reopening the whole direction. New references follow the same inspection, specificity, PRESERVE / ADAPT / INVENT, and provenance rules. Record the revision in the Reference Lock as what stays, what changes, why, and which reference supports the change; update the Major Visual Decision Map, set Human Approval back to `PENDING` unless the original user explicitly waived checkpoints, present the revised synthesis, and stop for approval.

External research must materially affect the proposal. If research is appropriate but no usable references can be inspected, say so and do not fabricate a Reference Lock.

Default to moderate-to-high reference fidelity. Preserve a strong reference's composition, proportions, hierarchy, spacing rhythm, interaction concept, card or section structure, typography treatment, or color treatment when they fit. Adapt only the dimensions that conflict with concrete project constraints; do not make cosmetic changes merely to appear original.

Implement independently. Do not copy source code, proprietary images or assets, logos or brand marks as the user's own, or large blocks of copy. Layout approaches, composition, hierarchy, spacing, typography treatments, interaction patterns, and product-presentation techniques may inform the work.

## Stop conditions

Stop when an approval is pending and wait for the human, a major decision is unresolved or unsupported, the direction is approved and actionable, local conventions make external research unnecessary, usable references cannot be inspected, or a product/brand decision needs human input. If implementation constraints conflict with an approved direction, return the conflict to the human rather than silently redesigning it.

## Output and verification

Return the inspected reference evidence, element-level PRESERVE / ADAPT / INVENT map, Major Visual Decision Map, Design Synthesis Proposal, explicit Human Approval status, final synthesis, and open risks. Verify cited references support the stated observations at the specificity proposed, every major visual decision has valid provenance, the Reference Lock preceded implementation, the pre-implementation gate was honored, and the direction does not drift into unsourced generic styling.

## Related

[frontend-design](../frontend-design/SKILL.md), [visual-critique](../visual-critique/SKILL.md), [research](../research/SKILL.md), [DESIGN.md](../../templates/DESIGN.md)
