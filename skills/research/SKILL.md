---
name: research
description: Gather and compare evidence for an engineering question before a decision when local context is insufficient.
---

# Research

## Use when

An answer or design choice needs evidence that local repository inspection cannot provide.

## Do not use when

The relevant code, tests, configuration, or established project decision already answers the question.

## Inputs

Question, decision it informs, relevant repository context, constraints, and time/risk bounds.

## Workflow

1. Frame the question and evidence needed; inspect local evidence first.
2. Select authoritative sources using [engineering source selection](../../references/engineering-sources.md).
3. Gather, compare, and date/version evidence; identify conflicts and gaps.
4. Produce findings labeled **FACT**, **INFERENCE**, **ASSUMPTION**, and **DECISION**.
5. Recommend a next engineering action only when the evidence supports it.

## Stop conditions

Stop when the decision is supported, local evidence makes research unnecessary, or a material uncertainty needs an owner decision. Do not turn research into implementation.

## Output and verification

Return the question, sources, categorized findings, uncertainty, and supported next action. Verify links, distinguish source claims from interpretation, and avoid unsupported certainty.

## Related

[architecture](../architecture/SKILL.md), [design-research](../design-research/SKILL.md), [AGENTS.md](../../AGENTS.md)
