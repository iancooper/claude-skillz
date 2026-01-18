---
name: Separation of Concerns
description: "Enforces code organization using features/ (verticals), platform/ (horizontals), and entrypoints/ (api, cli, consumers). Triggers on: code organization, file structure, where does this belong, new file creation, refactoring."
version: 1.7.0
---

# Separation of Concerns

## Mandatory Top-Level Structure

```
features/      ← verticals
platform/      ← horizontals
entrypoints/   ← api, cli, consumers
```

🚨 **All three MUST exist. Start here when implementing, refactoring, or reviewing.**

---

## Principles

1. **Separate external clients from domain-specific code**
2. **Separate feature-specific from shared capabilities**
3. **Separate intent from execution**
4. **Separate functions that depend on different state**
5. **Separate functions that don't have related names**

## Mental Model: Verticals and Horizontals

**Vertical** = all code for ONE feature, grouped together
**Horizontal** = capabilities used by MULTIPLE features

Top-level folders distinguish them:
- `features/` — verticals (work in these)
- `platform/` — horizontals (build on these)
- `entrypoints/` — how traffic enters (api, cli, consumers)

```
features/         platform/              entrypoints/
├── checkout/     ├── domain/            ├── api/
├── refunds/      │   └── tax-calc/      ├── cli/
├── inventory/    └── infra/             └── consumers/
└── shipping/         └── ext-clients/
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
platform/infra/external-clients/order-total.ts   ← domain logic in infra
features/checkout/stripe-api.ts                  ← external client in feature

✅ GOOD:
platform/infra/external-clients/stripe.ts        ← generic: charge, refund, subscribe
features/checkout/payment-processing.ts          ← OUR domain logic using stripe
```

---

## Principle 2: Separate feature-specific from shared capabilities

**What:** Code that belongs to one feature stays in that feature's folder. Code used across features lives in a shared location named for what it IS.

**Why:** When shared logic is buried in one feature, other features either import across boundaries (coupling) or duplicate the logic (divergence). Both cause bugs.

**How:**
- Ask: "Does this conceptually belong to one feature?"
- YES → keep in features/
- NO → extract to platform/, name it for what it IS

```
❌ BAD - buried in one feature:
features/checkout/tax-calculator.ts
features/refunds/refund.ts           ← imports ../checkout/tax-calculator

❌ BAD - duplicated:
features/checkout/tax-calculator.ts
features/refunds/tax-calculator.ts   ← rules diverge over time

✅ GOOD - extracted to platform:
features/checkout/
features/refunds/
platform/domain/tax-calculation/     ← shared domain logic
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

Top-level: `features/` and `platform/`. Both can be layered internally:

- **use-cases/** - orchestration, commands, workflows
- **domain/** - business rules, models, value objects
- **infra/** - external services, persistence, frameworks

Entry points grouped under `entrypoints/`:
- **api/** - HTTP controllers
- **cli/** - CLI commands
- **consumers/** - event/message consumers

```
/food-delivery/
├── features/
│   ├── order-placement/       ← VERTICAL
│   │   ├── use-cases/
│   │   ├── domain/
│   │   └── infra/
│   │
│   └── driver-tracking/       ← VERTICAL
│       ├── use-cases/
│       ├── domain/
│       └── infra/
│
├── platform/
│   ├── domain/
│   │   ├── delivery-fee/      ← shared business rules
│   │   └── conventions/       ← our rules for the domain
│   └── infra/
│       └── external-clients/  ← generic wrappers
│
└── entrypoints/               ← HOW TRAFFIC ENTERS
    ├── api/                   ← HTTP (calls into features)
    ├── cli/                   ← command line
    └── consumers/             ← events/messages
```

### Platform code rules

- Ask: "Does this conceptually belong to one feature?"
- YES → `features/`
- NO → `platform/`, named for what it IS

### Detection: Inside a feature or in platform?

**Look at the siblings:**
- Siblings are layers (use-cases/, domain/, infra/) → **INSIDE a feature**
- Siblings are capabilities (delivery-fee/, external-clients/) → **PLATFORM**

---

## Code Review Tips

### For each function

1. Does it rely on the same state and have a similar name to other functions in the class/file? Does the name align with the class/file name?
2. If inside a feature, is it only used inside that feature?

### For each file

1. Does the file name seem related to other files in the same directory?

### For each directory

1. Does the directory name describe what all files inside have in common?
2. Are the sibling directories related? (all features, all layers, or all platform capabilities - not mixed)
3. If inside a feature, is it only imported within that feature?
4. Does it contain what it should based on its name? (use-cases/ has orchestration, domain/ has business rules, infra/ has external integrations)
