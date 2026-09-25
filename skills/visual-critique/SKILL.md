---
name: visual-critique
description: Evaluate the actual rendered result of significant visual work, classify visual or responsive weaknesses, and drive bounded evidence-based refinement.
---

# Visual Critique

## Use when

Significant visual work has been implemented and its rendered result matters: a portfolio, landing page, marketing site, substantial product UI or dashboard redesign, or visual component-system work. [frontend-design](../frontend-design/SKILL.md) hands off here after the first implementation and render, before completion.

## Do not use when

The change is a tiny CSS fix, non-visual backend work, or a trivial component change fully governed by an existing design system. Those use ordinary [verification](../verification/SKILL.md) render checks without this loop.

## Inputs

The rendered surface, the approved [Reference Lock](../../templates/reference-lock.md) and [DESIGN.md](../../templates/DESIGN.md) or existing design system, product purpose, content, surface type, and the original human-checkpoint status.

## Workflow

1. **Capture render evidence.** Use the strongest rendering the host provides: browser screenshots, browser automation, or rendered captures. Choose representative viewports for the project, normally at least one desktop and one mobile state, plus relevant states such as menu or disclosure open, hover/focus, modal, table overflow, and empty/loading/error. When a problem appears near a breakpoint, test immediately around it (breakpoint - 1, breakpoint, breakpoint + 1). If rendering is unavailable, report `VISUAL_NOT_AVAILABLE` and stop the critique; DOM, CSS, or source inspection alone never yields a visual pass.
2. **Check synthesis integrity.** Compare the render to the approved Major Visual Decision Map. Record whether the approved synthesis is intact or has drifted toward unsourced model-prior styling.
3. **Critique by surface purpose.** Judge only the dimensions that matter for this surface: hierarchy, first-screen or primary-task clarity, compositional rhythm, section-to-section variance, visual mass, prominence of the work/product/content, repetitive composition, intentional versus accidental asymmetry, typography hierarchy and legibility, spacing rhythm, tonal transitions, grid alignment, interaction affordance, motion restraint, responsive behavior, clipping/overflow, reference-synthesis fidelity, and model-prior drift. A dashboard is not faulted for lacking portfolio drama; a portfolio is not judged like a settings screen.
4. **Classify every material finding before changing code.**
   - **TECHNICAL_DEFECT:** clipped text, horizontal overflow, broken breakpoint, font not loading, insufficient contrast, broken keyboard interaction, incorrect semantics, layout collision, or runtime/rendering bug. Fix it when the fix does not alter a major approved aesthetic decision; no renewed design approval is needed. Record the fix and re-verify.
   - **WITHIN_LOCK_REFINEMENT:** an implementation-level adjustment that preserves the approved direction, such as spacing calibration, modest proportional tuning, breakpoint adjustment, exact font size or line-height, grid-line opacity, readable max-width, or token tuning. Refine it without renewed approval when it neither introduces nor replaces a Major Visual Decision; record why it stays inside the lock.
   - **DIRECTIONAL_WEAKNESS:** a problem that cannot be fixed without changing or adding a Major Visual Decision, such as a weak hero composition, work/product lacking visual presence, flat intensity across the page, structurally weak section rhythm, an approved project presentation that fails when rendered, or a needed change to the major typography hierarchy. Do not silently redesign; return a targeted request to [design-research](../design-research/SKILL.md) (step 7).
   - **INTENTIONAL_VARIANCE:** visible imbalance or asymmetry that is deliberate. Visual imbalance is not, by itself, a defect. Before changing asymmetry, ask whether it looks broken or unfinished, harms hierarchy or usability, or contradicts the approved direction, or instead creates rhythm, distinguishes content, forms a transition, supports hierarchy, or matches the approved synthesis. Record intentional variance and leave it alone; do not normalize differences merely for consistency.
5. **Weakest area first.** Rank findings by impact and address normally no more than the top one to three material findings per pass. Prefer the smallest justified refinement followed by a re-render over a full redesign or a new aesthetic system.
6. **Guard against model priors.** A refinement must not add unsourced gradients, cream or off-white fields, glass cards, bento layouts, serif-italic accents, floating blobs, decorative motion, new colors, or new motifs. Such a treatment needs approved reference evidence, the existing brand or design system, a product need, an accessibility/technical constraint, or newly approved targeted research. Major Visual Decision provenance remains in force during refinement.
7. **Return directional weaknesses to targeted research.** State the observed weakness, the parts of the approved direction that still work, and what must be researched (for example project presentation, hero composition, section rhythm, or interaction structure), not a generic aesthetic search. Unless the original user explicitly waived design checkpoints (`SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`), the revision returns to `PENDING` and needs human approval before implementation. Renewed approval is required for any new Major Visual Decision or a changed hero direction, major typography system, project/content presentation, tonal system, substantial section composition, or visual motif.
8. **Re-render and compare.** After each pass, render the same viewports and states and record what improved, regressed, or remains unresolved. Continue only while material defects or weaknesses remain. By default run at most two refinement passes after the initial implementation, unless a blocking technical defect remains or the human asks for more; afterward report remaining non-blocking weaknesses. The limit never prevents a necessary technical or accessibility fix.

## Stop conditions

Stop when the visual state is acceptable, remaining caveats are recorded, the pass limit is reached, a directional weakness awaits renewed human approval, or rendering is unavailable.

## Output and verification

Record the critique in [visual-critique-report.md](../../templates/visual-critique-report.md), scaled to the task: render evidence, synthesis integrity, classified findings, intentional variance, refinements and whether approval was required, re-render comparison, and a final status of `VISUAL_PASS`, `VISUAL_PASS_WITH_CAVEATS`, `VISUAL_BLOCKED`, or `VISUAL_NOT_AVAILABLE`. Pass that status to verification as an evidence item; it is not a mechanical gate result and `VISUAL_NOT_AVAILABLE` is never reported as a pass.

## Related

[frontend-design](../frontend-design/SKILL.md), [design-research](../design-research/SKILL.md), [verification](../verification/SKILL.md)
