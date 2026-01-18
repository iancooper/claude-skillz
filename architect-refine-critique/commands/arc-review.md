---
description: Review critique findings and record decisions for a design review
---

# Review Design Critique

Facilitated discussion of critique findings from an `/arc` design review.

## Usage

`/arc-review [name]`

- `[name]` — The review name used in `/arc [name] [target]`

## Example

```
/arc-review payment-refactor
```

## Prerequisites

Run `/arc [name] [target]` first to generate:
- `docs/design-reviews/[name]/design.md`
- `docs/design-reviews/[name]/refined.md`
- `docs/design-reviews/[name]/critique.md`

## What Happens

1. Read the critique at `docs/design-reviews/[name]/critique.md`
2. Present findings ONE BY ONE to you
3. For each finding:
   - Show the finding (what's wrong, why it matters, suggested fix)
   - Wait for YOUR decision
   - Record your decision and rationale
4. Write decisions to `docs/design-reviews/[name]/decisions.md`
5. Produce implementation plan at `docs/design-reviews/[name]/implementation.md`

## Your Role

You make the decisions. I present findings and record what you decide:
- **Accept** - Agree with the critique, will fix
- **Reject** - Disagree, explain why
- **Defer** - Valid but not now, explain when
- **Partial** - Accept some aspects, reject others

## Output

```
docs/design-reviews/[name]/
├── decisions.md      ← Your decisions + rationale
└── implementation.md ← Final implementation plan
```

---

# Instructions for Claude

You are facilitating a design review discussion. The USER makes decisions, you record them.

## Your Job

1. Read `docs/design-reviews/[name]/critique.md`
2. Present findings ONE AT A TIME
3. WAIT for user response before proceeding
4. Record THEIR decision, not yours
5. After all findings reviewed, write decisions.md and implementation.md

## CRITICAL RULES

- **DO NOT** decide for the user
- **DO NOT** skip findings
- **DO NOT** batch multiple findings together
- **DO NOT** summarize or filter findings
- **DO NOT** proceed without user input on each finding

## Flow

```
You: "Finding 1 (CRITICAL): [description]. What's your decision?"
User: "Accept, we should fix this because..."
You: [Record decision] "Finding 2 (HIGH): [description]. What's your decision?"
User: "Reject, this isn't applicable because..."
You: [Record decision] "Finding 3..."
...continue until all findings addressed...
You: "All findings reviewed. Writing decisions.md and implementation.md."
```

## Decisions.md Structure

```markdown
# [name] Design Review Decisions

Reviewed: docs/design-reviews/[name]/critique.md
Date: [date]

## Decisions

### Finding 1: [title]
- **Severity:** CRITICAL
- **Decision:** Accept
- **Rationale:** [user's explanation]
- **Action:** [what will be done]

### Finding 2: [title]
...
```

## Implementation.md Structure

```markdown
# [name] Implementation Plan

Based on decisions from design review.

## Accepted Changes

1. [Change from accepted finding]
2. ...

## Deferred Items

1. [Item] - Deferred until [when]
2. ...

## Implementation Order

1. [First change]
2. [Second change]
...
```
