---
name: Separation of Concerns
description: "Enforces code organization using verticals (features) and horizontals (shared capabilities). Triggers on: code organization, file structure, where does this belong, feature vs shared, new file creation, refactoring."
version: 1.3.0
---

# Separation of Concerns

## Principles

1. **Separate external clients from domain-specific code**
2. **Separate feature-specific from shared capabilities**
3. **Separate intent from execution**
4. **Separate functions that depend on different state**
5. **Separate functions that don't have related names**

## Mental Model: Verticals and Horizontals

**Vertical** = all code for ONE feature, grouped together (checkout/, refunds/, shipping/)
**Horizontal** = shared code used by MULTIPLE features, named for what it IS (tax-calculation/, external-clients/)

```
checkout/     refunds/     inventory/     shipping/
    │             │             │             │
    └─────────────┴─────────────┴─────────────┘
                  │                   │
          external-clients/    tax-calculation/
          (generic wrappers)   (shared domain)
```

---

## Principle 1: Separate external clients from domain-specific code

**What:** Generic wrappers for external services (APIs, databases, SDKs) live separately from code that uses them in domain-specific ways.

**Why:** Domain logic mixed with external service details is harder to understand and evolve. Separating them keeps domain logic pure and focused.

**How:**
- Ask: "Would the creators of this external service recognize this code?"
- YES → external-clients/
- NO → your domain code

```
❌ BAD:
external-clients/order-total.ts      ← domain logic in external-clients
checkout/stripe-api.ts               ← external client in vertical

✅ GOOD:
external-clients/stripe.ts           ← generic: charge, refund, subscribe
checkout/payment-processing.ts       ← OUR domain logic using stripe
```

---

## Principle 2: Separate feature-specific from shared capabilities

**What:** Code that belongs to one feature stays in that feature's folder. Code used across features lives in a shared location named for what it IS.

**Why:** When shared logic is buried in one feature, other features either import across boundaries (coupling) or duplicate the logic (divergence). Both cause bugs.

**How:**
- Ask: "Does this conceptually belong to one feature?"
- YES → keep in that vertical
- NO → extract to horizontal, name it for what it IS

```
❌ BAD - buried in one vertical:
checkout/tax-calculator.ts
refunds/refund.ts                    ← imports ../checkout/tax-calculator

❌ BAD - duplicated:
checkout/tax-calculator.ts
refunds/tax-calculator.ts            ← rules diverge over time

✅ GOOD - extracted:
checkout/
refunds/
tax-calculation/tax-calculator.ts    ← horizontal, named for what it IS
```

---

## Principle 3: Separate intent from execution

**What:** High-level flow visible at one abstraction level. Implementation details in lower levels.

**Why:** When intent and execution are mixed, you can't see what the code does without reading every line. Changes to one step's implementation ripple through unrelated code.

**How:**
- Ask: "Can I see the high-level flow without reading every line?"
- NO → extract details into named functions/methods

```typescript
// ❌ BAD - can't see flow, details obscure intent
async function checkout(cart: Cart) {
  const ctx = new CheckoutContext()
  try {
    const validation = await validateCart(cart)
    if (!validation.success) { /* 10 lines of error handling */ }
    const payment = await processPayment(cart)
    if (!payment.success) { /* 10 lines of rollback */ }
    // ... 30 more lines
  } catch (e) { await cleanup(ctx); throw e }
}

// ✅ GOOD - flow visible, drill into details as needed
function checkout(cart: Cart, payment: PaymentDetails) {
  const validatedCart = cart.validate()
  const receipt = paymentService.process(validatedCart.total, payment)
  const order = Order.create(validatedCart, receipt)
  confirmationService.send(order)
  return order
}
```

---

## Principle 4: Separate functions that depend on different state

**What:** Functions that depend on different state (different fields, databases, services, config) belong in different modules.

**Why:** Different state dependencies mean different reasons to change, different testing strategies, and different failure modes.

**How:**
- List the fields/dependencies in a class
- For each method, note which it uses
- Methods cluster around different state? → split into separate classes

```
❌ BAD:
class OrderService {
  db, emailClient, templateEngine

  save()  → uses db
  find()  → uses db
  sendConfirmation() → uses emailClient, templateEngine
}

✅ GOOD:
class OrderRepository { db }
class OrderNotifications { emailClient, templateEngine }
```

---

## Principle 5: Separate functions that don't have related names

**What:** Functions in the same module should have names that relate to a common concept.

**Why:** Unrelated names signal unrelated responsibilities. If you can't name the module after what the functions have in common, they probably don't belong together.

**How:**
- Look at the function names in a module
- Can you describe what they have in common in one phrase?
- NO → split them into separate modules

```
❌ BAD - order-helpers.ts:
  calculateOrderTotal()
  formatOrderForInvoice()
  validateOrderForShipping()
  assessOrderFraudRisk()
  → all operate on "order" but change for different reasons:
    pricing rules, invoice formatting, shipping constraints, fraud detection

✅ GOOD - split by why they change:
  order-pricing.ts:      calculateTotal(), applyDiscounts()
  invoice-formatting.ts: formatForInvoice(), formatLineItems()
  shipping-validation.ts: validateForShipping(), checkWeightLimits()
  fraud-detection.ts:    assessFraudRisk(), flagSuspiciousPatterns()
```

---

## Package Structure

Verticals and horizontals can be layered internally:

- **use-cases/** - orchestration, commands, workflows
- **domain/** - business rules, models, value objects
- **infra/** - external services, persistence, frameworks
- **api/** - HTTP controllers (entry point)
- **cli/** - CLI commands (entry point)
- **consumers/** - event/message consumers (entry point)

```
/food-delivery/
├── order-placement/       ← VERTICAL
│   ├── use-cases/
│   ├── domain/
│   └── infra/
│
├── driver-tracking/       ← VERTICAL
│   ├── use-cases/
│   ├── domain/
│   └── infra/
│
├── api/                   ← ENTRY POINTS (call into verticals)
├── cli/
├── consumers/
│
├── domain/                ← SHARED (not owned by any vertical)
│   └── delivery-fee/
│
├── infra/                 ← SHARED (not owned by any vertical)
│   └── external-clients/
│
└── conventions/           ← OUR rules for using externals
```

### Shared code rules

**Within a package:** Code not owned by any specific vertical → put in root-level `domain/` or `infra/`
- Ask: "Does this conceptually belong to one vertical?" NO → root level

**Between packages:** Code not owned by any specific package → extract to a separate shared package

### Detection: Inside a vertical or at package level?

**Look at the siblings:**
- Siblings are layers (use-cases/, domain/, infra/) → **INSIDE a vertical**
- Siblings are verticals (order-placement/, shipping/) → **PACKAGE level (shared)**

---

## Code Review Tips

### For each function

1. Does it rely on the same state and have a similar name to other functions in the class/file? Does the name align with the class/file name?
2. If inside a vertical, is it only used inside that vertical?

### For each file

1. Does the file name seem related to other files in the same directory?

### For each directory

1. Does the directory name describe what all files inside have in common?
2. Are the sibling directories related? (all verticals, or all layers - not mixed)
3. If inside a vertical, is it only imported within that vertical?
4. Does it contain what it should based on its name? (use-cases/ has orchestration, domain/ has business rules, infra/ has external integrations)
