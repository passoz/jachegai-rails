# [UI-08] Migrate the showcase to `@jachegai/ui` and add composition recipes for the new app surfaces

## Goal
Finish the UI-library slice by making `/legacy-design-system` a real consumer of `@jachegai/ui`, then ship composition recipes that show how the new system should assemble screens for `landing`, `customer`, `seller`, `courier`, and `admin`.

This issue is the bridge from “component inventory exists” to “new system can compose real screens using the library.”

## Why this matters
A UI library is not ready until something real consumes it. The current showcase must stop being ad-hoc page markup and become a proof that the package can compose the public, auth, commerce, and operational patterns cleanly.

This issue is also where we prove that the old skin can live on top of new flows without leaking page-local styling back into the apps.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules
- [UI-03] implement core primitives and form controls in `@jachegai/ui`
- [UI-04] implement shells, surfaces, overlay/modal structures, dense footer, and trust band patterns
- [UI-05] implement commerce discovery and cart patterns in `@jachegai/ui`
- [UI-06] implement access panel patterns and actor variants in `@jachegai/ui`
- [UI-07] implement operational data-display patterns for seller, courier, and admin flows in `@jachegai/ui`

## Scope
- Refactor `/legacy-design-system` to consume `@jachegai/ui` exports instead of page-local bespoke markup.
- Add recipe-level examples for the five actor surfaces:
  - landing
  - customer
  - seller
  - courier
  - admin
- Document composition rules so future app pages are assembled from package patterns rather than recreated in route files.

## Where to work
- `web/apps/landing/src/legacy-design-system.tsx`
- `web/packages/ui/src/recipes/`
- `web/packages/ui/README.md`
- optional docs under `docs/`

## How to implement
1. Replace page-local markup in the showcase with imports from `@jachegai/ui`.
2. Create composition recipes for each actor surface, without turning the package into a page-router package.
3. Document which recipes are stable, which are examples, and which patterns apps are expected to compose directly.
4. Ensure the showcase remains the living proof of the library.

## Patterns and guardrails
- The showcase should be a library consumer, not the place where component logic still lives.
- App routes must be able to compose new flows by assembling package exports, not copying the showcase markup.
- Keep recipes flexible enough for new backend data and route shapes.

## Example implementation
```tsx
import {
  TopBar,
  DenseFooter,
  TrustBand,
  PublicDiscoverySection,
  AccessLayout,
  CartSummary,
  AdminCredentialingRecipe,
} from "@jachegai/ui";

export function LegacyDesignSystemPage() {
  return (
    <MarketingShell topBar={<TopBar {...topBarProps} />} footer={<DenseFooter {...footerProps} />}>
      <PublicDiscoverySection {...publicDiscoveryExample} />
      <AccessLayout {...sellerPortalExample} />
      <CartSummary {...cartSummaryExample} />
      <AdminCredentialingRecipe {...adminExample} />
      <TrustBand {...trustBandProps} />
    </MarketingShell>
  );
}
```

## Do Not Do
- Do not leave the showcase as a page of bespoke app-local div soup.
- Do not bake route logic into `@jachegai/ui`.
- Do not treat recipes as fixed pages that cannot accept different content/data.

## Acceptance criteria
- [ ] `/legacy-design-system` consumes `@jachegai/ui` instead of relying on page-local bespoke component structures.
- [ ] Composition recipes for landing, customer, seller, courier, and admin exist.
- [ ] Library documentation explains how new system screens should be assembled.
- [ ] Frontend build passes after the refactor.

## Verification
- `cd web && npm run build`
- manually inspect `/legacy-design-system`
- verify route code imports package exports instead of duplicating component markup

## Out of scope
- Full migration of all actor routes to the new package.
- Backend/API refactors.

## Source of truth
- `SPEC.md`
- `AGENTS.md`
- `docs/REBUILD_PLAN.md`
- `legacy/inventory/*.png`
- `web/apps/landing/src/legacy-design-system.tsx`

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
