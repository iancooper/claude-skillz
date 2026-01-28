# Separation of Concerns — Automated Enforcement

The separation of concerns skill defines structural and dependency rules for organizing TypeScript projects into `features/`, `platform/`, and `shell/`. These rules can be automatically enforced using [dependency-cruiser](https://github.com/sverweij/dependency-cruiser).

## What It Enforces

dependency-cruiser statically analyzes your TypeScript imports and validates them against architectural rules. The example configuration below covers these checklist items from the skill:

| Rule | What it catches |
|------|----------------|
| `root-structure` | Files outside `features/`, `platform/`, `shell/` |
| `platform-structure` | Anything in `platform/` that isn't `domain/` or `infra/` |
| `feature-structure` | Feature subfolders that aren't `entrypoint/`, `commands/`, `queries/`, `domain/` |
| `entrypoint-no-domain` | Entrypoints importing directly from `domain/` |
| `entrypoint-restricted-deps` | Entrypoints importing from anything other than `commands/`, `queries/`, `platform/infra/` |
| `no-cross-feature-imports` | One feature importing from another feature |
| `commands-no-cross-feature` | Commands importing from other features |
| `commands-must-use-domain` | Commands that don't import from their feature's `domain/` (required rule) |
| `queries-no-commands` | Queries importing from `commands/` |
| `no-circular` | Circular dependencies anywhere |

Rules that require human judgment (e.g. "commands contain no business rules", "queries never mutate state", "entrypoint is thin") are not automatable and remain in the skill checklist.

## Setup

```bash
npm install --save-dev dependency-cruiser
```

Copy the example configuration below into `.dependency-cruiser.mjs` at your project root.

## Example Configuration

```javascript
export default {
  forbidden: [
    {
      name: "root-structure",
      severity: "error",
      comment: "Package root must only contain features/, platform/, shell/",
      from: { path: "src/(?!features/|platform/|shell/).+" },
      to: {}
    },
    {
      name: "platform-structure",
      severity: "error",
      comment: "platform/ contains only domain/ and infra/",
      from: { path: "platform/(?!domain/|infra/)[^/]+/.+" },
      to: {}
    },
    {
      name: "feature-structure",
      severity: "error",
      comment: "Features contain only entrypoint/, commands/, queries/, domain/",
      from: { path: "features/[^/]+/(?!entrypoint/|commands/|queries/|domain/)[^/]+/.+" },
      to: {}
    },
    {
      name: "entrypoint-no-domain",
      severity: "error",
      comment: "Entrypoint must never import from domain/",
      from: { path: "features/[^/]+/entrypoint/.+" },
      to: { path: "(features/[^/]+/domain/|platform/domain/).+" }
    },
    {
      name: "entrypoint-restricted-deps",
      severity: "error",
      comment: "Entrypoint may only import from commands/, queries/, platform/infra/",
      from: { path: "features/([^/]+)/entrypoint/.+" },
      to: {
        path: "(features|platform|shell)/",
        pathNot: "(features/$1/(commands|queries)/|platform/infra/)"
      }
    },
    {
      name: "no-cross-feature-imports",
      severity: "error",
      comment: "Features must not import from other features",
      from: { path: "features/([^/]+)/.+" },
      to: {
        path: "features/([^/]+)/.+",
        pathNot: "features/$1/.+"
      }
    },
    {
      name: "commands-no-cross-feature",
      severity: "error",
      comment: "Commands forbidden from other features",
      from: { path: "features/([^/]+)/commands/.+" },
      to: {
        path: "features/([^/]+)/.+",
        pathNot: "features/$1/.+"
      }
    },
    {
      name: "queries-no-commands",
      severity: "error",
      comment: "Queries must not import from commands/",
      from: { path: "features/[^/]+/queries/.+" },
      to: { path: "features/[^/]+/commands/.+" }
    },
    {
      name: "no-circular",
      severity: "error",
      comment: "No circular dependencies",
      from: {},
      to: { circular: true }
    }
  ],

  required: [
    {
      name: "commands-must-use-domain",
      severity: "error",
      comment: "Every command MUST import from domain/",
      module: { path: "features/([^/]+)/commands/[^/]+\\.ts$" },
      to: { path: "features/$1/domain/.+" }
    }
  ],

  options: {
    doNotFollow: { path: "node_modules" },
    tsPreCompilationDeps: true,
    tsConfig: { fileName: "tsconfig.json" },
    exclude: ["dist/", "\\.spec\\.", "\\.test\\.", "\\.d\\.ts$"]
  }
};
```

## Usage

```bash
npx depcruise --config .dependency-cruiser.mjs src/
```

Clean output on a compliant project:

```
✔ no dependency violations found (46 modules, 111 dependencies cruised)
```

Violation output:

```
error no-cross-feature-imports: src/features/checkout/commands/place-order.ts
  → src/features/refunds/domain/refund.ts

error commands-must-use-domain: src/features/checkout/commands/cancel-order.ts

x 2 dependency violations (2 errors, 0 warnings). 46 modules, 111 dependencies cruised.
```

The process exits non-zero on violations, so it fails CI automatically.

## HTML Report

```bash
npx depcruise --config .dependency-cruiser.mjs --output-type err-html -f violations.html src/
```

Generates a standalone HTML page listing all violations grouped by rule, with violation counts and rule explanations.

## Adapting the Configuration

The `from.path` patterns use regex, not globs. Adjust them to match your source layout:

- **Monorepo with multiple packages:** Change `src/` to match your package paths (e.g. `packages/[^/]+/src/`)
- **Different source root:** Replace `src/` in the `root-structure` rule with your root
- **tsconfig location:** Update `options.tsConfig.fileName` to point to your tsconfig
