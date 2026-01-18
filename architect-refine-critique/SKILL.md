---
name: Architect-Refine-Critique
description: "Three-phase design review workflow using sub-agents. Architect designs (separation-of-concerns), Refiner analyzes (tactical-ddd), Critique challenges. Main agent orchestrates and facilitates user discussion."
version: 1.0.0
---

# Architect-Refine-Critique

Three-phase design review with dedicated sub-agents. Each agent works independently, producing their best work. Main agent is thin orchestrator only.

## Workflow

```
1. Architect sub-agent → plan.md (complete design)
2. Refiner sub-agent → refined.md (domain modeling analysis)
3. Critique sub-agent → critique.md (challenges)
4. User + Main agent → discuss findings → decisions.md
```

## Roles

| Role | Skill | Output |
|------|-------|--------|
| **Architect** | separation-of-concerns | Complete design plan |
| **Refiner** | tactical-ddd | Domain modeling analysis |
| **Critique** | separation-of-concerns + tactical-ddd | Challenges grouped by severity |

## Main Agent Behavior

**You are the orchestrator.** You coordinate sub-agents and facilitate discussion. You do NOT summarize or filter sub-agent output.

**You DO:**
- Spawn sub-agents in sequence
- Tell user where output files are
- Facilitate discussion by reading files when needed
- Help user work through findings one by one
- Record decisions to decisions.md

**You do NOT:**
- Summarize sub-agent output
- Filter or interpret findings
- Add your own analysis to sub-agent work

## Phase 1: Architect

Spawn sub-agent with this prompt:

```
You are the Architect. Produce the best possible design for this codebase/requirements.

Skills to apply:
- separation-of-concerns

Your job:
1. Analyze the codebase or requirements provided
2. Apply the separation-of-concerns skill thoroughly
3. Produce a complete design plan
4. Write your plan to: docs/design-reviews/[name]/plan.md

Be thorough. Produce your best work.
```

## Phase 2: Refiner

Spawn sub-agent with this prompt:

```
You are the Refiner. Improve this design by applying tactical DDD patterns.

Read the design at: docs/design-reviews/[name]/plan.md

Skills to apply:
- tactical-ddd

Your job:
1. Review the design
2. Apply the tactical-ddd skill thoroughly
3. Improve any aspects of the design that you feel can be improved
4. Write your refined design to: docs/design-reviews/[name]/refined.md

Be thorough. Produce your best work.
```

## Phase 3: Critique

Spawn sub-agent with this prompt:

```
You are the Critique. Challenge this design ruthlessly.

Read the refined design at: docs/design-reviews/[name]/refined.md

Skills to apply:
- separation-of-concerns
- tactical-ddd

Your job:
1. Find violations of design principles
2. Question assumptions
3. Identify ambiguities and gaps
4. Group findings by severity: CRITICAL, HIGH, MEDIUM, LOW
5. Write your critique to: docs/design-reviews/[name]/critique.md

Be ultra-critical. Include uncertain findings. False positives are better than missed issues.
```

## Phase 4: Facilitated Discussion

After all sub-agents complete:

1. [ ] Tell user: "Design review complete. Files are at docs/design-reviews/[name]/"
2. [ ] Ask user to read the documents
3. [ ] When user is ready, walk through each critique finding one by one
4. [ ] For each finding: present it, discuss validity and context with user
5. [ ] Record user's decision and rationale to decisions.md
6. [ ] Continue until all findings are addressed
7. [ ] Produce final implementation plan: implementation-plan.md

## Final Deliverable: implementation-plan.md

After all findings are addressed, create the implementation plan:

1. Start with the refined design from refined.md
2. Incorporate all accepted critique findings
3. Remove or adjust anything rejected during discussion
4. Produce a clean, actionable implementation plan

The implementation plan is the single source of truth for implementation.

## Output Structure

```
docs/design-reviews/
└── [review-name]/
    ├── plan.md                 ← Architect output
    ├── refined.md              ← Refiner output
    ├── critique.md             ← Critique output
    ├── decisions.md            ← User decisions + rationale
    └── implementation-plan.md  ← Final deliverable
```

## Invoking

User says: `/architect-refine-critique [name] [target]`

- `[name]` — review name (used for folder)
- `[target]` — what to review (codebase path, PRD reference, etc.)

Example: `/architect-refine-critique payment-refactor src/payments/`

## When to Use

- Planning a refactoring
- Reviewing a PRD before implementation
- Designing a new feature's structure
- Validating an existing architecture
