# Agent Operating Contract

This is the canonical contract for agents working in a repository that adopts agent-harness. Adapters may point here; they must not replace it with vendor-specific rules.

## Core loop

`UNDERSTAND -> RESEARCH -> EVIDENCE -> DECIDE -> PLAN -> EXECUTE -> VERIFY -> REPORT`

Classify the task first. Inspect the relevant local repository, behavior, architecture, conventions, constraints, and, when debugging, the failure reproduction before editing. Do not overwrite user work or broaden a targeted task with unrelated cleanup.

## Evidence and research

Evidence precedes modification. Prefer local repository evidence when it answers the question. When external knowledge materially affects a decision, research selectively using the order in [references/engineering-sources.md](references/engineering-sources.md). Clearly label facts, inferences, assumptions, and decisions. Do not browse merely to appear thorough.

## Decisions and plans

State invariants before significant work: security boundaries, public contracts, data integrity, auth, network/filesystem policy, and relevant performance constraints. Small obvious edits may proceed after inspection. Make an explicit plan for architectural, cross-cutting, security-sensitive, high-risk, or substantial visual changes. Choose the smallest justified change; add dependencies only with a reason.

If new evidence invalidates the plan, stop and return to research or architecture instead of forcing the implementation.

## Debugging

Follow: symptom -> reproduction -> evidence -> hypotheses -> root cause -> minimal fix -> regression protection -> verification. Never patch before establishing a root cause. If reproduction is unavailable, say what remains unproven.

## Completion and reporting

Do not claim a change is fixed, complete, passing, production-ready, or secure without fresh evidence. Run the strongest relevant mechanical checks available and report failures and unavailable gates. A report distinguishes observed facts, assumptions, decisions, remaining uncertainty, and verification evidence.

## Skill discovery

Read the relevant skill before applying it. Use [research](skills/research/SKILL.md) for evidence questions, [design-research](skills/design-research/SKILL.md) before significant greenfield visual work, [frontend-design](skills/frontend-design/SKILL.md) for UI implementation, [root-cause](skills/root-cause/SKILL.md) for bugs, [architecture](skills/architecture/SKILL.md) for material decisions, [implementation](skills/implementation/SKILL.md) for scoped changes, [verification](skills/verification/SKILL.md) before completion, and [pr](skills/pr/SKILL.md) for review preparation.

Existing repository instructions and conventions are constraints; surface conflicts with this contract rather than silently ignoring either one.
