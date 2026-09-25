---
name: root-cause
description: Diagnose a defect from precise symptom through evidence to a minimal, regression-protected fix.
---

# Root Cause

## Use when

Investigating a bug, regression, failure, or unexpected runtime behavior.

## Do not use when

The requested change is deliberate and behavior is understood; use implementation instead.

## Inputs

Precise symptom, expected behavior, affected environment/version, reproduction information, logs, and relevant code paths.

## Workflow

1. State and reproduce the symptom.
2. Collect logs, errors, and runtime evidence; trace relevant control and data flow.
3. Form a small set of hypotheses and test them.
4. Establish the root cause, design the minimal fix, and add or identify regression protection.
5. Implement, run focused then broader relevant verification, and complete [root-cause-report.md](../../templates/root-cause-report.md).

## Stop conditions

Stop before patching if root cause is not established. In an emergency, mitigation may precede full root-cause proof only when explicitly labeled as mitigation, risk-justified, reversible where possible, and followed by continued diagnosis; it is not a root-cause fix. If reproduction is impossible, record the limitation and only report evidence-supported hypotheses.

## Output and verification

Return the report with evidence, root cause status, fix, regression protection, and fresh verification. Never state a cause as proven when it is only inferred.

## Related

[implementation](../implementation/SKILL.md), [verification](../verification/SKILL.md), [research](../research/SKILL.md)
