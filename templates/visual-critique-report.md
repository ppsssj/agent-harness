# Visual Critique

Use after significant visual implementation. Scale it to the task; omit sections that do not apply.

## Render Evidence

| Viewport / state | Evidence | Notes |
| --- | --- | --- |
| Desktop |  |  |
| Mobile |  |  |

Record how each state was rendered (screenshot, browser automation, capture). If rendering is unavailable, mark it unavailable and set the final status to `VISUAL_NOT_AVAILABLE`; source or DOM inspection is not render evidence.

## Approved Synthesis Integrity

Status: intact / drift detected

Compare against the approved [Reference Lock](reference-lock.md) Major Visual Decision Map and note any unsourced drift.

## Findings

| Finding | Classification | Evidence | Action |
| --- | --- | --- | --- |
|  | TECHNICAL_DEFECT / WITHIN_LOCK_REFINEMENT / DIRECTIONAL_WEAKNESS / INTENTIONAL_VARIANCE |  |  |

Address the highest-impact one to three findings per pass. A DIRECTIONAL_WEAKNESS goes to targeted design research, not a silent redesign.

## Intentional Variance

Asymmetries or unequal visual mass deliberately left unchanged, and why they are not defects.

## Refinement

What was adjusted, which classification permitted it, and whether renewed approval was required. For a directional revision, state:

- What stays:
- What changes:
- Why:
- Supporting reference:
- Approval status:

## Re-render Comparison

Pass number, what improved, regressed, or remains unresolved.

## Final Visual Status

Status: VISUAL_PASS / VISUAL_PASS_WITH_CAVEATS / VISUAL_BLOCKED / VISUAL_NOT_AVAILABLE

Remaining non-blocking weaknesses:
