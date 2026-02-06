---
name: separation-of-concerns
description: "Enforces code organization using features/ (verticals), platform/ (horizontals), and shell/ (thin wiring). Triggers on: code organization, file structure, where does this belong, new file creation, refactoring."
version: 4.0.0
---

# Separation of Concerns

## Principles

1. **Separate external clients from domain-specific code**
2. **Separate feature-specific from shared capabilities**
3. **Separate intent from execution**
4. **Separate functions that depend on different state**
5. **Separate functions that don't have related names**
6. **Co-locate by change, not by kind**

## Mental Model: Verticals and Horizontals

**Vertical** = all code for ONE feature, grouped together
**Horizontal** = capabilities used by MULTIPLE features

All three top-level folders are mandatory: [SoC-013]
- `features/` — verticals, containing some combination of entrypoint/, commands/, queries/, domain/, infra/
  - commands/ orchestrates write operations (state mutations or external side-effects); MUST go through domain/ for business rules
  - queries/ usually queries database directly but can query domain if easier
  - domain/ contains business rules (required if commands/ exists)
  - entrypoint/ only needed when exposing external interface (HTTP, CLI, events)
  - infra/ feature-specific infrastructure (mappers, middleware, persistence implementations)
- `platform/` — horizontals, contains `domain/` and `infra/`
  - domain/ depends on nothing — never imports from infra/ [SoC-004]
  - infra/ CAN depend on domain/ (implements domain contracts)
- `shell/` — thin wiring/routing only (no business logic) [SoC-012]

**Note on terminology:** CLI subcommands (like `git commit`) are wired in shell/. Write operations in commands/ are CQRS commands — different concepts.

```
features/              platform/              shell/
├── checkout/          ├── domain/            └── cli.ts
│   ├── entrypoint/    │   └── tax-calc/
│   ├── commands/      └── infra/
│   ├── queries/           ├── external-clients/
│   ├── domain/            ├── http/
│   └── infra/             ├── persistence/
│       ├── mappers/       ├── config/
│       └── persistence/   └── logging/
└── refunds/
    ├── entrypoint/
    ├── commands/
    ├── queries/
    └── domain/
```

---

## Where Does This Code Belong? [SoC-001]

🚨 **When unsure where code belongs, follow this decision tree.** Stop at the first match.

### Q1: Does it wire things together at startup?

Registers routes, bootstraps a framework, connects to a message broker, registers CLI subcommands with a framework.

→ **shell/**

**Test:** If you deleted this code, would the app still have all its logic but no way to start?

❌ **Not shell/ if:** It parses input, formats output, contains business logic, or loads/saves data. Those are deeper layers.

### Q2: Does it translate between external and internal formats?

Parses HTTP requests, CLI arguments, or queue messages into internal types. Formats internal results into HTTP responses, CLI output (tables, JSON, plain text), or outgoing messages. Maps domain errors to status codes or exit codes. Handles interactive prompts, progress bars, spinners.

→ **entrypoint/**

**Test:** If you changed protocols (HTTP → CLI, CLI → queue consumer, etc.), would you rewrite this code but keep commands/ and domain/ unchanged?

❌ **Not entrypoint/ if:** It loads data, modifies state, persists results, talks to a database, or enforces business rules. If you see load→modify→save, that's commands/, not entrypoint/.

### Q3: Does it orchestrate a write operation?

Loads data, invokes domain logic to modify it, then persists the result. Or coordinates a side-effect through an external service (payment, email, deployment). Always goes through domain/ for business rules.

→ **commands/**

**Test:** Does it change state? Would "Undo" make sense for this operation?

❌ **Not commands/ if:** It parses external input (HTTP requests, CLI args, queue messages) — that's entrypoint/. It contains the business rules themselves — that's domain/. It only reads data — that's queries/. Commands must define their own input parameter objects — they cannot depend on external input types (no HttpRequest, no CLI arg objects, no raw message payloads). [SoC-007]

### Q4: Does it read and return data without modifying anything?

Loads data, transforms/aggregates it, returns a result. No side effects, no state changes.

→ **queries/**

**Test:** Could you run this 100 times with the same input and get the same result (assuming no external writes)?

❌ **Not queries/ if:** It writes, deletes, sends emails, triggers side effects, or enforces invariants.

### Q5: Is it business logic specific to ONE feature?

Validation rules, state transitions, invariants, domain calculations that only this feature cares about. Repository interfaces (domain contracts for persistence) also live here.

→ **features/{name}/domain/**

**Test:** Does another feature need this? If no → feature domain. If yes → keep reading.

❌ **Not feature domain/ if:** It orchestrates persistence (that's commands/) or is needed by multiple features (that's platform/domain/ or a dedicated domain library package).

### Q6: Is it infrastructure specific to ONE feature?

Repository implementations, response mappers, format adapters, feature-specific middleware. Implements domain contracts or handles protocol/format concerns for this feature only.

→ **features/{name}/infra/**

Typical subfolders: `mappers/` (response/format mapping), `middleware/` (feature-specific middleware), `persistence/` (repository implementations).

**Test:** Is this technical plumbing (not business rules) that only this feature needs?

❌ **Not feature/infra/ if:** It contains business rules (that's domain/). It's used by multiple features (that's platform/infra/). It parses external input or invokes commands (that's entrypoint/).

### Q7: Is it shared across features?

**Contains project-specific domain language** (your entity names, your business concepts, your workflow terms)?

→ **platform/domain/** (or a dedicated domain library package)

**Test:** Would a new developer need to understand your business to understand this code?

❌ **Not platform/domain/ if:** It's generic infrastructure with no project-specific concepts.

Shared value objects (Money, Email, Address) that enforce validation → platform/domain/ or a dedicated domain library.

**Shared technical concerns** (HTTP clients, database wrappers, logging, config, response formatters, shared middleware)?

→ **platform/infra/**

Platform/infra/ includes both generic utilities and project-specific conventions for infrastructure concerns (response formatters, error handling middleware).

Typical subfolders: `external-clients/` (third-party wrappers), `persistence/` (database clients), `http/` (shared formatters, middleware), `messaging/` (queue clients), `config/`, `logging/`.

**Test:** Is it infrastructure that multiple features or entrypoints use?

❌ **Not platform/infra/ if:** It contains business rules or domain invariants. That's platform/domain/.

---

## Entrypoint [SoC-006]

*If unsure whether code belongs here, use the decision tree above.*

**What:** Thin translation layer between external world and commands/queries.

**Pattern:**
1. Parse external input into command or query object
2. Invoke command or query
3. Map result to external response

```typescript
class OrderController {
  constructor(
    private placeOrder: PlaceOrderCommand,
    private getOrderSummary: GetOrderSummaryQuery
  ) {}

  post(req: HttpRequest): HttpResponse {
    const cmd = parseOrderCommand(req.body)
    const result = this.placeOrder.execute(cmd)
    return mapToHttpResponse(result)
  }

  get(req: HttpRequest): HttpResponse {
    const orderId = req.params.id
    const summary = this.getOrderSummary.execute(orderId)
    return mapToHttpResponse(summary)
  }
}
```

When entrypoint/ grows large, extract infrastructure helpers (response mappers, middleware, format adapters) to features/{name}/infra/.

**Dependency Rules:** [SoC-002]
- ✅ CAN depend on: commands/, queries/
- ✅ CAN depend on: features/{name}/infra/ (feature-specific mappers, middleware)
- ✅ CAN depend on: platform/infra/ (formatters, loggers, config, shared middleware — NOT database clients or persistence)
- ❌ FORBIDDEN: domain/ (entrypoint never imports domain directly)
- ❌ FORBIDDEN: platform/domain/

> **DependencyCruiser:** Enforce that entrypoint/ can only access platform/infra/ subfolders: http/, logging/, config/. Block access to persistence/, external-clients/.

**Behavioral Rules:**
- ❌ NO orchestration (that's commands/)
- ❌ NO domain logic (that's domain/)
- ❌ NO data fetching (that's queries/)
- ❌ NO database access (entrypoint never talks to a database — that's commands/ or queries/)
- ✅ Owns input parsing and output mapping
- ✅ Owns output formatting decisions (which format, how to render — may delegate to shared formatters in platform/infra/)
- ✅ Owns interactive prompts (confirmations, progress bars, spinners)
- ✅ Owns exit code mapping (domain result → process exit code)

---

## Commands [SoC-005]

*If unsure whether code belongs here, use the decision tree above.*

**What:** Orchestrate write operations that mutate state or coordinate external side-effects. Commands MUST go through the domain layer for business rules.

**Why strict layering:** Commands change state. Domain invariants must be enforced. Skipping domain/ means business rules can be violated.

**Pattern:**
1. Receive command input (already parsed by entrypoint)
2. Load domain aggregates/entities
3. Execute domain logic (validation, state transitions)
4. Persist changes
5. Return result

```typescript
class ApproveRefundCommand {
  constructor(private refundRepository: RefundRepository) {}

  execute(input: ApproveRefundInput): Refund {
    const refund = this.refundRepository.get(input.refundId)
    refund.approve(input.approvedBy, input.reason)
    this.refundRepository.save(refund)
    return refund
  }
}
```

**Dependency Rules:** [SoC-002]
- ✅ MUST depend on: domain/ (this is the point)
- ✅ CAN depend on: platform/infra/, platform/domain/
- ✅ CAN depend on: features/{name}/infra/ (repository implementations)
- ❌ FORBIDDEN: entrypoint/ (commands are invoked BY entrypoint, never import from it)
- ❌ FORBIDDEN: other features' commands/, queries/, or domain/

**Behavioral Rules:**
- ✅ All business logic delegated to domain/ [SoC-005]
- ❌ NO business rules in command itself [SoC-005]
- ❌ NO direct database queries (use repositories from domain/)
- ✅ Each command has a dedicated input type matching the command name — no sharing of input DTOs [SoC-007]
- ❌ NO dependency on external input types (no HttpRequest, no CLI arg objects, no raw message payloads) [SoC-007]
- ❌ commands/ contains ONLY command files — no helpers, utilities, or nested folders [SoC-009]

**Naming:** Imperative verb phrase, no prefix — domain action words. `place-order.ts`, `cancel-subscription.ts`, `approve-refund.ts`. Commands are instructions, so the name is the action itself. Menu test: would this appear on a UI menu?

---

## Queries [SoC-008]

*If unsure whether code belongs here, use the decision tree above.*

**What:** Handle read operations. Queries usually query the database directly but can query domain if easier.

**Why minimal layering:** Queries don't mutate state. No invariants to protect. Optimize for read performance and simplicity.

**Pattern:**
1. Receive query input (already parsed by entrypoint)
2. Fetch data (directly from repository/database, or via domain)
3. Map to response DTO
4. Return result

```typescript
class GetOrderSummaryQuery {
  constructor(private db: DatabaseClient) {}

  execute(orderId: string): OrderSummary {
    const row = this.db.query('SELECT ... FROM orders WHERE id = ?', [orderId])
    if (!row) throw new OrderNotFoundError(orderId)
    return new OrderSummary(row.id, row.status, Money.from(row.total))
  }
}
```

**Dependency Rules:** [SoC-002]
- ✅ CAN depend on: domain/ (read-only — load and query state, never mutate)
- ✅ CAN depend on: platform/infra/, platform/domain/
- ✅ CAN depend on: features/{name}/infra/ (repository implementations)
- ❌ FORBIDDEN: entrypoint/ (queries are invoked BY entrypoint, never import from it)
- ❌ FORBIDDEN: commands/

**Behavioral Rules:**
- ✅ Read-only, no side effects [SoC-008]
- ✅ Can query database directly (no repository required)
- ✅ Can load and query domain objects for their state
- ❌ NO state mutations [SoC-008]
- ❌ NO business rule enforcement (queries trust the data)
- ❌ queries/ contains ONLY query files — no helpers, utilities, or nested folders [SoC-009]

**Naming:** Verb phrase with read-operation prefix: `get-order-summary.ts`, `list-pending-refunds.ts`, `search-products.ts`. Queries are requests for information, so standard prefixes (get, list, search, find) make the read-only intent clear.

**Query-only features:** Features that only read data need only `queries/`. No domain/ required since no invariants to protect. If queries need to be shared across features, extract to a dedicated query library package — cross-feature imports are forbidden [SoC-003].

---

## Principle 1: Separate external clients from domain-specific code [SoC-011]

**What:** Generic wrappers for external services (APIs, databases, SDKs) live separately from code that uses them in domain-specific ways.

**Why:** Domain logic mixed with external service details is harder to understand and evolve. Separating them keeps domain logic pure and focused.

**How:**
- Ask: "Would the creators of this external service recognize this code?"
- YES → platform/infra/external-clients/
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

## Principle 2: Separate feature-specific from shared capabilities [SoC-003]

**What:** Code that belongs to one feature stays in that feature's folder. Code used across features lives in a shared location — platform/ or a dedicated domain library package.

**Why:** When shared logic is buried in one feature, other features either import across boundaries (coupling) or duplicate the logic (divergence). Both cause bugs.

**How:**
- Ask: "Does this conceptually belong to one feature?"
- YES → keep in features/
- NO → extract to platform/ or a dedicated domain library, name it for what it IS

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

## Principle 6: Co-locate by change, not by kind [SoC-010]

**What:** Files used together live together. Never group by category.

**Why:** Type-based grouping scatters related code. One change = many folders. Co-location means one change = one folder.

**How:**
- Ask: "If I change this feature, which files change together?"
- Group those files in one folder

Forbidden everywhere: `types/`, `models/`, `validators/`, `assertions/`, `schemas/`, `interfaces/`, `value-objects/`, and their single-file equivalents.

**Exception:** Shared test fixtures used across multiple test files may live in a `fixtures/` file or folder.

---

## Package Structure

```
/food-delivery/
├── features/
│   ├── order-placement/
│   │   ├── entrypoint/        ← thin translation layer
│   │   ├── commands/          ← write operations, strict layering
│   │   ├── queries/           ← read operations, minimal layering
│   │   ├── domain/            ← business rules (required for commands)
│   │   └── infra/             ← feature-specific infrastructure
│   │       ├── mappers/       ← response/format mapping
│   │       └── persistence/   ← repository implementations
│   │
│   └── order-dashboard/       ← read-only feature (no writes = no domain needed)
│       ├── entrypoint/        ← external HTTP API
│       └── queries/           ← direct DB queries, no business rules
│
├── platform/
│   ├── domain/                ← shared business rules (depends on nothing)
│   └── infra/                 ← shared technical concerns
│       ├── external-clients/  ← third-party service wrappers
│       ├── persistence/       ← database clients, connection pools
│       ├── http/              ← shared formatters, error handling middleware
│       ├── messaging/         ← queue clients, event bus
│       ├── config/            ← configuration loading
│       └── logging/           ← structured logging
│
└── shell/
    └── cli.ts
```

---

## Audit Checklist

When designing, implementing, refactoring, or reviewing code, verify each applicable rule.

**For code/architecture reviews:** Evaluate each file against SoC-001 through SoC-013. Verdict per rule: **PASS**, **FAIL** (cite file:line), or **N/A**.

| Code | Rule | Applies to |
|------|------|-----------|
| SoC-001 | Always follow the code placement decision tree | All files |
| SoC-002 | Dependencies point inward | All layer files |
| SoC-003 | Features never cross-import | features/ |
| SoC-004 | Domain never does I/O | domain/ |
| SoC-005 | No business logic in commands | commands/ |
| SoC-006 | Entrypoints are thin translation layers | entrypoint/ |
| SoC-007 | Commands own their inputs | commands/ |
| SoC-008 | Queries read, never write | queries/ |
| SoC-009 | No helpers in commands or queries | commands/, queries/ |
| SoC-010 | Co-locate by change, not kind | All |
| SoC-011 | External wrappers in platform/infra | platform/ |
| SoC-012 | Shell wires, nothing else | shell/ |
| SoC-013 | The vertical slice folder structure is mandatory | Root |

Each code references detailed rules in the sections above. Do not proceed until all applicable rules pass.
