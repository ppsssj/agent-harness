# agent-harness

A harness-agnostic workflow layer for AI-assisted software engineering. It gives coding agents reusable procedures for investigating, deciding, implementing, verifying, and reporting work; it is not a prompt collection, autonomous framework, LLM wrapper, or replacement for an agent.

## Why

Coding agents can act before understanding, produce generic visual work, patch symptoms, skip verification, or report success without evidence. `agent-harness` makes the engineering behavior repeatable:

`UNDERSTAND -> RESEARCH -> EVIDENCE -> DECIDE -> PLAN -> EXECUTE -> VERIFY -> REPORT`

## Architecture

- [AGENTS.md](AGENTS.md) is the canonical operating contract.
- [skills/](skills/) contains eight concise, task-specific procedures.
- [references/](references/) holds source-selection and reusable decision guidance.
- [templates/](templates/) provides project and report structures.
- [evals/](evals/README.md) describes how future versions can assess skill quality.

`CLAUDE.md` is deliberately a small adapter; other harnesses can add similar adapters without changing the contract or skills.

## v0.1 skills

| Skill | Use it for |
| --- | --- |
| [research](skills/research/SKILL.md) | Evidence gathering and supported recommendations |
| [design-research](skills/design-research/SKILL.md) | Reference-driven visual direction |
| [frontend-design](skills/frontend-design/SKILL.md) | Designing and building UI in an existing project |
| [architecture](skills/architecture/SKILL.md) | Material technical decisions and migration planning |
| [implementation](skills/implementation/SKILL.md) | A scoped, understood code change |
| [root-cause](skills/root-cause/SKILL.md) | Debugging from symptom to proven cause |
| [verification](skills/verification/SKILL.md) | Selecting and reporting fresh mechanical checks |
| [pr](skills/pr/SKILL.md) | Preparing a reviewable change without merging it |

## Example workflows

```text
Feature:          research -> architecture -> implementation -> verification -> pr
Bug:              root-cause -> implementation -> verification -> pr
Visual frontend:  design-research -> DESIGN.md -> frontend-design -> verification -> pr
```

Small, obvious changes may start with implementation after local inspection. Architectural, cross-cutting, visual, security-sensitive, or high-risk work needs the relevant discovery or planning skill first.

## Design philosophy

Meaningful visual work is reference-driven, not generated from generic model priors. [design-research](skills/design-research/SKILL.md) routes a task to appropriate discovery sources, decomposes the useful principles of references, and records a traceable Reference Lock. It then synthesizes an original direction under product, system, accessibility, and performance constraints. It never asks agents to copy a site or visual identity.

## Harness agnosticism

The repository specifies behavior, evidence, and artifacts, not proprietary commands or tool calls. An agent should use the strongest capabilities its host exposes and report unavailable checks honestly. See [AGENTS.md](AGENTS.md) for the contract.

## Roadmap

Possible additions after v0.1 include security, accessibility, performance, database, deployment, production smoke-testing, incident analysis, an eval runner, and skill quality measurement. They are not implemented here.

## Sources

The v0.1 research log, adaptations, and license notes are in [docs/SOURCES.md](docs/SOURCES.md).
