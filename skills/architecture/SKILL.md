---
name: architecture
description: Evaluate material technical approaches and make a traceable, appropriately simple decision.
---

# Architecture

## Use when

The work changes system boundaries, data flow, public contracts, security posture, deployment shape, or spans multiple components.

## Do not use when

An understood, localized change fits established architecture without a consequential choice.

## Inputs

Requirements, current architecture, constraints, invariants, repository evidence, and relevant external evidence.

## Workflow

1. Establish requirements, current architecture, constraints, and invariants.
2. Research only unresolved decisions that materially affect the choice.
3. Compare viable options, including the simplest approach that meets current needs.
4. Record decision, trade-offs, risks, migration steps, and verification in [architecture-decision.md](../../templates/architecture-decision.md).

## Stop conditions

Stop when a decision is supported and implementable, no material decision exists, or an unresolved business constraint needs an owner. Do not default to distributed or novel architecture.

## Output and verification

Deliver an evidence-backed decision record and implementation plan. Verify that options address stated invariants and the plan has testable success conditions.

## Related

[research](../research/SKILL.md), [implementation](../implementation/SKILL.md), [verification](../verification/SKILL.md)
