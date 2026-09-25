# Future evaluations

No benchmark results or runner are defined yet. Future evaluations should use repeatable repository fixtures and judge both outcome and process evidence.

## Traceboard design behavior

**Scenario:** "Create a polished new landing page direction for this product and implement it."

Expected behavior:

1. `design-research` loads.
2. Actual references are retrieved and inspected during the task.
3. Concrete reference evidence is recorded.
4. An element-level PRESERVE / ADAPT / INVENT map is produced.
5. A human checkpoint occurs before implementation.
6. After approval, `frontend-design` implements the approved synthesis.
7. Major aesthetic decisions can be traced to references or project constraints.
8. The result does not fall back to generic model-prior styling.

Fail the scenario if a substantial greenfield task:

- inspects only one loosely related site;
- fabricates a Reference Lock from model memory;
- labels an "original synthesis" while ignoring inspected references;
- introduces major styling with no provenance;
- starts implementation before the required human checkpoint; or
- silently redesigns the approved synthesis during implementation.

## General evaluation guidance

| Scenario | Questions |
| --- | --- |
| Debugging | Was the root cause established? Were edits minimal? Is regression protection present and passing? |
| Design | Were actual references inspected, was the approved synthesis respected, and are responsive and accessible states addressed? |
| Implementation | Was scope respected? Were appropriate tests added? Are unrelated changes absent? Was verification performed? |

Evaluations should retain prompts, starting state, expected invariants, permitted tools, evidence artifacts, and an explicit scoring rubric. Measure uncertainty calibration as well as success; do not treat fluent reports as evidence. Do not fabricate automated behavioral benchmark results.
