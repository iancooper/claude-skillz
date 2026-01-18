---
description: Three-phase design review (Architect → Refine → Critique)
---

# /arc

`/arc [name] [target]`

Runs three sub-agents sequentially:
1. Architect → `design.md`
2. Refiner → `refinements.md` + `refined.md`
3. Critique → `critique.md`

Then tells you to run `/arc-review [name]`.

## Output

```
docs/design-reviews/[name]/
├── design.md
├── refinements.md
├── refined.md
└── critique.md
```
