---
description: Three-phase design review (Architect → Refine → Critique) with sub-agents
---

# Architect-Refine-Critique

Run a three-phase design review using dedicated sub-agents.

## Usage

`/arc [name] [target]`

- `[name]` — Review name (creates folder at docs/design-reviews/[name]/)
- `[target]` — What to review (path, PRD, or description)

## Examples

```
/arc payment-refactor src/payments/
/arc user-auth-design docs/prd/user-auth.md
/arc api-restructure "the current API layer"
```

## What Happens

1. **Architect** sub-agent creates structural plan → `plan.md`
2. **Refiner** sub-agent adds tactical detail → `refined.md`
3. **Critique** sub-agent challenges the design → `critique.md`
4. You review and discuss findings with me
5. Decisions recorded → `decisions.md`

## Output

```
docs/design-reviews/[name]/
├── plan.md        ← Structure, boundaries
├── refined.md     ← Responsibilities, naming
├── critique.md    ← Challenges by severity
└── decisions.md   ← Your decisions + rationale
```
