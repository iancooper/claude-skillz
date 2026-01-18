---
name: Architect-Refine-Critique
description: "Three-phase design review workflow using sub-agents. Architect designs (separation-of-concerns), Refiner analyzes (tactical-ddd), Critique challenges. Main agent orchestrates and facilitates user discussion."
version: 1.0.1
---

# Architect-Refine-Critique

Three-phase design review with dedicated sub-agents. Each agent works independently, producing their best work. Main agent is thin orchestrator only.

**CRITICAL: Phases run SEQUENTIALLY. Each phase MUST complete before the next begins.**

## Roles

| Role | Skill | Output |
|------|-------|--------|
| **Architect** | separation-of-concerns | design.md |
| **Refiner** | separation-of-concerns + tactical-ddd | refined.md |
| **Critique** | separation-of-concerns + tactical-ddd | critique.md |

## Invoking

User says: `/arc [name] [target]`

- `[name]` — review name (used for folder)
- `[target]` — what to review (codebase path, PRD reference, etc.)

Example: `/arc payment-refactor src/payments/`

## Main Agent Checklist

Follow this checklist exactly. Do not skip steps. Do not run phases in parallel.

### Phase 1: Architect

1. [ ] Call the **Task tool** with these exact parameters:
   - `subagent_type`: **"general-purpose"** (ONLY general-purpose has Write access)
   - `description`: "Architect: design"
   - `prompt`: (use the prompt below, replacing [name] and [target])

```
You are the Architect. Produce the best possible design for this codebase/requirements.

Target: [target]

Skills to apply:
- separation-of-concerns

Your job:
1. Analyze the codebase or requirements provided
2. Apply the separation-of-concerns skill thoroughly
3. Produce a complete design
4. IMPORTANT: Write your design to: docs/design-reviews/[name]/design.md

Be thorough. Produce your best work. You MUST write the file before finishing.
```

2. [ ] **WAIT** for the sub-agent to complete
3. [ ] **VERIFY** docs/design-reviews/[name]/design.md was written by the sub-agent. If not, abort—do not write it yourself.

### Phase 2: Refiner

4. [ ] Call the **Task tool** with these exact parameters:
   - `subagent_type`: **"general-purpose"** (ONLY general-purpose has Write access)
   - `description`: "Refiner: improve design"
   - `prompt`: (use the prompt below, replacing [name])

```
You are the Refiner. Improve this design using the skills below.

Read the design at: docs/design-reviews/[name]/design.md

Skills to apply:
- separation-of-concerns
- tactical-ddd

Your job:
1. Read the design.md file first
2. Apply the separation-of-concerns and tactical-ddd skills thoroughly
3. Improve any aspects of the design that you feel can be improved
4. IMPORTANT: Write your refined design to: docs/design-reviews/[name]/refined.md

Be thorough. Produce your best work. You MUST write the file before finishing.
```

5. [ ] **WAIT** for the sub-agent to complete
6. [ ] **VERIFY** docs/design-reviews/[name]/refined.md was written by the sub-agent. If not, abort—do not write it yourself.

### Phase 3: Critique

7. [ ] Call the **Task tool** with these exact parameters:
   - `subagent_type`: **"general-purpose"** (ONLY general-purpose has Write access)
   - `description`: "Critique: challenge design"
   - `prompt`: (use the prompt below, replacing [name])

```
You are the Critique. Challenge this design ruthlessly.

Read the refined design at: docs/design-reviews/[name]/refined.md

Skills to apply:
- separation-of-concerns
- tactical-ddd

Your job:
1. Read the refined.md file first
2. Find what's wrong (violations, mistakes, contradictions)
3. Find what could be better (improvements, alternatives)
4. Find what could be simpler (unnecessary complexity, over-engineering)
5. Question assumptions and identify gaps
6. Group findings by severity: CRITICAL, HIGH, MEDIUM, LOW
7. IMPORTANT: Write your critique to: docs/design-reviews/[name]/critique.md

Be ultra-critical. Include uncertain findings. False positives are better than missed issues.
You MUST write the file before finishing.
```

8. [ ] **WAIT** for the sub-agent to complete
9. [ ] **VERIFY** docs/design-reviews/[name]/critique.md was written by the sub-agent. If not, abort—do not write it yourself.

### Phase 4: Facilitated Discussion

10. [ ] Tell user: "Design review complete. Files are at docs/design-reviews/[name]/"
11. [ ] Ask user to read the documents
12. [ ] When user is ready, walk through each critique finding one by one
13. [ ] For each finding: present it, discuss validity and context with user
14. [ ] Record user's decision and rationale to decisions.md
15. [ ] Continue until all findings are addressed
16. [ ] Produce final implementation: implementation.md

## Main Agent Behavior

**You are the orchestrator.** You coordinate sub-agents and facilitate discussion. You do NOT summarize or filter sub-agent output.

**You do NOT:**
- Run phases in parallel
- Summarize sub-agent output
- Filter or interpret findings
- Add your own analysis to sub-agent work
- Write files that sub-agents should write

## Output Structure

```
docs/design-reviews/
└── [review-name]/
    ├── design.md                 ← Architect writes this
    ├── refined.md              ← Refiner writes this
    ├── critique.md             ← Critique writes this
    ├── decisions.md            ← Main agent writes this
    └── implementation.md         ← Main agent writes this
```
