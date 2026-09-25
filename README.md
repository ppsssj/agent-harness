# agent-harness

A harness-agnostic workflow layer for AI-assisted software engineering. It gives coding agents reusable procedures for investigating, deciding, implementing, verifying, and reporting work; it is not a prompt collection, autonomous framework, LLM wrapper, or replacement for an agent.

## Why

Coding agents can act before understanding, produce generic visual work, patch symptoms, skip verification, or report success without evidence. `agent-harness` makes the engineering behavior repeatable:

`UNDERSTAND -> RESEARCH -> EVIDENCE -> DECIDE -> PLAN -> EXECUTE -> VERIFY -> REPORT`

## Architecture

- [AGENTS.md](AGENTS.md) is the canonical operating contract.
- [skills/](skills/) contains nine concise, task-specific procedures.
- [references/](references/) holds source-selection and reusable decision guidance.
- [templates/](templates/) provides project and report structures.
- [evals/](evals/README.md) describes how future versions can assess skill quality.

`CLAUDE.md` is deliberately a small adapter; other harnesses can add similar adapters without changing the contract or skills.

## Skills

| Skill | Use it for |
| --- | --- |
| [research](skills/research/SKILL.md) | Evidence gathering and supported recommendations |
| [design-research](skills/design-research/SKILL.md) | Reference-driven visual direction |
| [frontend-design](skills/frontend-design/SKILL.md) | Designing and building UI in an existing project |
| [visual-critique](skills/visual-critique/SKILL.md) | Reviewing the rendered result of significant visual work and driving bounded refinement |
| [architecture](skills/architecture/SKILL.md) | Material technical decisions and migration planning |
| [implementation](skills/implementation/SKILL.md) | A scoped, understood code change |
| [root-cause](skills/root-cause/SKILL.md) | Debugging from symptom to proven cause |
| [verification](skills/verification/SKILL.md) | Selecting and reporting fresh mechanical checks |
| [pr](skills/pr/SKILL.md) | Preparing a reviewable change without merging it |

## Example workflows

```text
Feature:          research -> architecture -> implementation -> verification -> pr
Bug:              root-cause -> implementation -> verification -> pr
Visual frontend:  design-research -> DESIGN.md -> frontend-design -> visual-critique -> verification -> pr
Visual refinement: render -> critique -> classify -> fix or targeted research -> re-render -> compare
```

Visual critique classifies each rendered finding as a technical defect, a within-lock refinement, a directional weakness, or intentional variance. The first two are fixed without renewed approval; a directional weakness returns to targeted design research and a new human checkpoint. Refinement is bounded (normally at most two passes) and never a route for unsourced styling.

Small, obvious changes may start with implementation after local inspection. Architectural, cross-cutting, visual, security-sensitive, or high-risk work needs the relevant discovery or planning skill first.

## Design philosophy

Meaningful visual work is reference-led, not generated from generic model priors. [design-research](skills/design-research/SKILL.md) routes a task to appropriate discovery sources, records concrete observations in a traceable Reference Lock, and maps each important element as PRESERVE, ADAPT, or INVENT. It preserves strong reference decisions when they fit, adapts only for concrete project constraints, and independently implements the approved synthesis without copying code, proprietary assets, marks, or large blocks of copy.

Visual work is reference-led before implementation and render-reviewed after it. [visual-critique](skills/visual-critique/SKILL.md) inspects actual rendered captures rather than source code, fixes the highest-impact weaknesses deliberately, leaves intentional asymmetry alone, and reports `VISUAL_NOT_AVAILABLE` instead of a pass when no renderer is available.

## Harness agnosticism

The repository specifies behavior, evidence, and artifacts, not proprietary commands or tool calls. An agent should use the strongest capabilities its host exposes and report unavailable checks honestly. See [AGENTS.md](AGENTS.md) for the contract.

## Next milestone: installation and distribution

The next milestone is making the harness straightforward to adopt: a Windows-first installer, Codex/Claude adapters or supported global skill integration, and a `doctor` command to verify installation. These are not implemented in v0.1.

## Installation

v0.2 provides a Windows-first, ownership-aware installer for self-contained namespaced Codex and Claude Code skills. Start with a preview; applying changes is explicit. See [Installation](docs/INSTALLATION.md).

## Later roadmap

Potential later areas include security, accessibility, performance, database, deployment, production smoke-testing, incident analysis, an eval runner, and skill quality measurement. They are not implemented here.

## Sources

The v0.1 research log, adaptations, and license notes are in [docs/SOURCES.md](docs/SOURCES.md).
