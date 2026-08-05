# [UI-01] Reset `@jachegai/ui` package and define the reusable library contract

## Goal
Replace the current placeholder `web/packages/ui/src/index.ts` implementation with a real library skeleton designed for the JaChegai rebuild. The package must stop exposing Tailwind-flavored demo code and become the canonical place for reusable UI primitives, patterns, CSS tokens, and composition-ready exports.

This issue is the package reset and contract definition step. It does not aim to implement the whole design system yet; it must establish the file layout, export boundaries, CSS loading model, naming rules, and testing hooks that every later UI issue depends on.

## Why this matters
Right now the `@jachegai/ui` package is not fit for the new system. It contains placeholder components with utility-class assumptions that do not match the inventory-derived visual language and are not safe to scale across `landing`, `customer`, `seller`, `courier`, and `admin`.

If this package contract is weak, every later app will leak duplicated styles and ad-hoc markup. If this package contract is strong, the new system can compose screens instead of restyling them from scratch.

## Dependencies
- None.

## Scope
- Replace the current placeholder `@jachegai/ui` package structure.
- Define the package directory layout for `styles/`, `primitives/`, `patterns/`, `recipes/`, and `testing/` exports.
- Define CSS import strategy for tokens and shared base styles without Tailwind.
- Define naming rules: no `Legacy*` component names in public exports.
- Add package-level README describing purpose, layering, and consumption rules.

## Where to work
- `web/packages/ui/package.json`
- `web/packages/ui/src/index.ts`
- `web/packages/ui/src/`
- `web/packages/ui/README.md`
- `web/tsconfig.json` if package resolution needs cleanup

## How to implement
1. Remove placeholder Tailwind-style implementation from `web/packages/ui/src/index.ts`.
2. Create package structure similar to:
   - `src/styles/tokens.css`
   - `src/styles/base.css`
   - `src/primitives/`
   - `src/patterns/`
   - `src/recipes/`
   - `src/testing/`
3. Export only package-owned components and helpers from `src/index.ts`.
4. Add a clear layering rule:
   - primitives: buttons, inputs, pills, surfaces, layout atoms
   - patterns: auth panel, summary card, footer, trust band, etc.
   - recipes: ready-to-compose actor sections, not full screens
5. Add README guidance explaining that apps compose screens from the package and should not recreate inventory-derived UI in app-local files unless a new pattern is being proven.

## Patterns and guardrails
- Use React + TypeScript + project-owned CSS only.
- Do not introduce Tailwind.
- Do not introduce shadcn or another UI framework as the visual base.
- Public exports must use product-oriented names like `TopBar`, `AccessPanel`, `SummaryCard`, `TrustBand`, not `LegacyTopBar`.
- Keep package APIs explicit and typed.

## Example implementation
```ts
// web/packages/ui/src/index.ts
export * from "./primitives/Button";
export * from "./primitives/Input";
export * from "./primitives/Surface";
export * from "./patterns/TopBar";
export * from "./patterns/Footer";
export * from "./patterns/TrustBand";
export * from "./recipes/PublicDiscoverySection";
```

```css
/* web/packages/ui/src/styles/base.css */
@import "./tokens.css";

:root {
  color: var(--color-text-primary);
}

* {
  box-sizing: border-box;
}
```

## Do Not Do
- Do not keep the current placeholder `Layout` and `Button` as-is.
- Do not introduce Tailwind classes into package exports.
- Do not export app-specific page components from `@jachegai/ui`.
- Do not start implementing the full visual inventory in this issue.

## Acceptance criteria
- [ ] `@jachegai/ui` no longer exposes placeholder Tailwind-style components.
- [ ] Package structure clearly separates styles, primitives, patterns, recipes, and testing helpers.
- [ ] Public export surface is intentional and documented.
- [ ] README explains how new app screens should consume the library.
- [ ] No public component name contains `Legacy`.
- [ ] Frontend build passes after the package reset.

## Verification
- `cd web && npm run build`
- `rg -n "bg-|px-|py-|rounded|max-w-|min-h-screen" web/packages/ui/src`

## Out of scope
- Final visual tokens and typography values.
- Implementation of the full component set.
- Migration of app screens to consume the new library.

## Source of truth
- `SPEC.md`
- `AGENTS.md`
- `docs/REBUILD_PLAN.md`
- `legacy/inventory/inventory.md`
- `legacy/inventory/*.png`

## Anti-Migué Delivery Contract
This issue is a contract, not a vague task. Any implementing agent — including agents other than the planner/orchestrator — must follow these delivery rules exactly.

### Do not self-close
- The implementing agent must **not** mark this issue as completed on its own.
- The correct terminal status for the implementer is **`review-required`** or equivalent handoff for verification.
- Completion requires separate review/verification against this issue body.

### Required delivery format
Any implementation handoff for this issue must include all of the following:

```txt
STATUS: review-required

Checklist:
- [x] <acceptance criterion 1>
- [x] <acceptance criterion 2>
- [x] <acceptance criterion N>

Changed files:
- path/file1
- path/file2

Commands run:
- <command>
- <command>

Evidence:
- <tests executed>
- <observed result>
- <functional validation>

Scope deviations:
- none
or
- <explicit deviation>

Pending items:
- none
or
- <explicit pending item>
```

### Hard completion gate
This issue is **not done** unless all of the following are true:
- [ ] Every acceptance criterion in this issue is explicitly checked off in the delivery handoff.
- [ ] The implementer lists the exact changed files.
- [ ] The implementer lists the exact commands executed.
- [ ] Test/build/verification evidence is included.
- [ ] Any scope deviation is explicitly declared.
- [ ] A separate reviewer/verifier confirms the work against this issue body.

### Anti-scope-creep rule
- Do not treat adjacent cleanup, refactors, or architectural “improvements” as free extras.
- If something important is missing from the issue, block and report it instead of silently changing scope.
- “It should be working” is not acceptable evidence.
