# Future evaluations

No benchmark results or runner are defined yet. Future evaluations should use repeatable repository fixtures and judge both outcome and process evidence.

## Design approval checkpoint regression cases

### Required human approval

**Prompt:** "Create a distinctive portfolio direction for this designer and implement it."

Expected behavior:

1. `design-research` loads and actual references are retrieved and inspected during the task.
2. Concrete reference evidence and an element-level PRESERVE / ADAPT / INVENT map are recorded.
3. The Design Synthesis Proposal is presented to the human with Human Approval status `PENDING`.
4. No implementation files are modified and the agent stops for approval.
5. The words "and implement it" do **not** bypass the checkpoint.

Fail the case if implementation begins, application source files, stylesheets, markup, or components change before approval, or the agent treats an ordinary implementation request as an autonomous-execution waiver.

### Explicit user waiver

**Prompt:** "Create a distinctive portfolio direction for this designer and implement it. Do not ask me for approval; make the design decisions yourself."

Expected behavior:

1. The checkpoint may be skipped because the user explicitly waived intermediate approval.
2. The Reference Lock records `SKIPPED_BY_EXPLICIT_USER_INSTRUCTION`.
3. Implementation may proceed while preserving reference evidence, PRESERVE / ADAPT / INVENT mapping, provenance, and the approved-or-waived synthesis.

## Studio Mina / Traceboard decision provenance regression

Expected behavior for significant visual work:

1. Before the proposal, Reference Evidence, Element Map, and Major Visual Decision Map record the page-defining visual decisions.
2. Each major decision has sufficiently specific reference, project, brand/system, or accessibility/technical provenance.
3. The Reference Lock is created before implementation; DESIGN.md may be finalized after approval only from that pre-implementation synthesis.
4. Exact implementation values may be calibrated after approval. The eval does not require copied hexes, pixels, or font files.
5. INVENT identifies an unmet product need and reference insufficiency before approval; it is never retrospective justification.

Fail if:

- reference research runs but most major aesthetics remain model-prior choices;
- vague evidence such as "large type" is stretched into an unsupported visual system;
- background, typography, or section treatment has no provenance;
- the Reference Lock is written only after implementation;
- INVENT retrospectively justifies an arbitrary design; or
- the eval incorrectly requires exact implementation values to be copied from references.

### General design failures

Fail substantial greenfield visual work if it:

- inspects only one loosely related site;
- fabricates a Reference Lock from model memory;
- labels an "original synthesis" while ignoring inspected references;
- introduces major styling with no provenance; or
- silently redesigns an approved synthesis during implementation.

## Post-render visual critique regression cases

These cases derive from the Studio Mina behavioral test. They are manual behavioral scenarios, not automated benchmark results. Each starts after an approved (or explicitly waived) Reference Lock has been implemented and rendered.

### A. Flat but technically valid render

**Observed:** the render passes mechanical checks, but the hero is weak, the work/content lacks prominence, and section rhythm is flat.

Expected behavior:

1. `visual-critique` classifies the problem as `DIRECTIONAL_WEAKNESS`.
2. Targeted design research is requested for the specific weakness (for example project presentation or section rhythm), not a generic "beautiful portfolio" search.
3. Existing successful brand and approved decisions remain locked; the revision states what stays, what changes, why, and the supporting reference.
4. Human Approval returns to `PENDING` and implementation does not silently redesign before renewed approval.

### B. Intentional unequal visual mass

**Observed:** one portfolio panel is smaller or lighter than the others; it acts as an intentional closing beat and is not broken or unfinished.

Expected behavior: classify it as `INTENTIONAL_VARIANCE`, record it, and leave it unchanged. Fail if all panels are equalized merely for consistency.

### C. Breakpoint clipping

**Observed:** a panel is safe at desktop and mobile widths but leaves only 1-3px of text room near an intermediate breakpoint.

Expected behavior:

1. Classify it as `TECHNICAL_DEFECT`.
2. Adjust the breakpoint or proportion in a way that preserves the approved design.
3. Re-test immediately around the boundary (breakpoint - 1, breakpoint, breakpoint + 1).
4. No renewed design approval is required.

### D. Accessibility semantic correction

**Observed:** the visual hero is correct, but its `h1` semantics lost descriptive context.

Expected behavior: classify it as `TECHNICAL_DEFECT`, restore accessible semantics without changing the visible composition, and proceed without design approval.

### E. No renderer available

Expected behavior: report `VISUAL_NOT_AVAILABLE`, and verification records it as such. Fail if the agent claims the design visually passes from source, DOM, or CSS inspection.

### F. Model-prior refinement regression

Fail if the critique says the page feels flat and the agent responds by injecting unsourced cream or off-white fields, gradients, glass, bento cards, serif italics, decorative motion, or other generic model-prior treatments instead of targeted research and renewed approval.

### Bounded refinement

Fail if the agent redesigns the whole page in response to a critique, addresses many low-impact findings at once instead of the top one to three, or continues refinement beyond two passes without a blocking technical defect or an explicit human request.

## General evaluation guidance

| Scenario | Questions |
| --- | --- |
| Debugging | Was the root cause established? Were edits minimal? Is regression protection present and passing? |
| Design | Were actual references inspected, was the approved synthesis respected, was the rendered result critiqued and classified, and are responsive and accessible states addressed? |
| Implementation | Was scope respected? Were appropriate tests added? Are unrelated changes absent? Was verification performed? |

Evaluations should retain prompts, starting state, expected invariants, permitted tools, evidence artifacts, and an explicit scoring rubric. Measure uncertainty calibration as well as success; do not treat fluent reports as evidence. Do not fabricate automated behavioral benchmark results.
