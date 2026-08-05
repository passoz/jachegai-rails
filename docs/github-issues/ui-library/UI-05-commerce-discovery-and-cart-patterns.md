# [UI-05] Implement commerce discovery and cart patterns in `@jachegai/ui`

## Goal
Convert the public discovery, category, store-card, empty-state, and cart-summary patterns into reusable components for the new system. These must let future product screens compose catalog and checkout surfaces without rewriting the visual language.

## Why this matters
The inventory proves that commerce behavior is carried by a handful of repeatable shapes: category chips, large section headers, discovery lists, empty states, and the unmistakable yellow summary card. These patterns must become reusable or the new landing/customer flow will fork visually from day one.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules
- [UI-03] implement core primitives and form controls in `@jachegai/ui`
- [UI-04] implement shells, surfaces, overlay/modal structures, dense footer, and trust band patterns

## Scope
- Implement reusable patterns for:
  - `SectionHeader`
  - `CategoryChip`
  - `CategoryGrid`
  - `StoreCard`
  - `EmptyStatePanel`
  - `SummaryCard`
  - `CartSummary`
  - `CouponField`
- Ensure APIs can serve both current MVP data and future expanded flows.

## Where to work
- `web/packages/ui/src/patterns/`
- `web/packages/ui/src/recipes/`
- `web/packages/ui/src/index.ts`

## How to implement
1. Build category and discovery patterns from the public inventory screens.
2. Build summary/cart patterns from `customer_cart` and checkout references.
3. Keep data contracts generic enough for real API payloads.
4. Provide recipe-level examples for a public discovery block and an empty cart block.

## Patterns and guardrails
- Do not collapse the cart summary into a generic side card; preserve the yellow block identity.
- Empty states should support large icon/glyph + heading + subcopy + CTA.
- Category chips should support icon slot + label without hardcoding old category names.
- Patterns should be reusable by both public discovery and authenticated customer flows.

## Example implementation
```tsx
<SectionHeader title="Depósitos Próximos" actionLabel="Ver todos" />
<CategoryGrid>
  {categories.map((item) => (
    <CategoryChip key={item.id} icon={item.icon} label={item.name} />
  ))}
</CategoryGrid>

<CartSummary
  subtotal={0}
  delivery={0}
  total={0}
  couponSlot={<CouponField value={coupon} onChange={setCoupon} />}
  actionLabel="Finalizar"
/>
```

## Do Not Do
- Do not hardcode old catalog data into component internals.
- Do not implement cart patterns as one-off markup inside customer pages.
- Do not treat empty states as simple `<p>no data</p>` placeholders.

## Acceptance criteria
- [ ] Public discovery and cart/summary patterns exist in `@jachegai/ui`.
- [ ] APIs are generic enough for current MVP and future catalog/cart flows.
- [ ] Category, store, empty-state, and summary components render responsively.
- [ ] Frontend build passes with the new exports in place.

## Verification
- `cd web && npm run build`
- render public-discovery and empty-cart examples using the package

## Out of scope
- Actor access portals.
- Operational/admin data display.

## Source of truth
- `SPEC.md`
- `AGENTS.md`
- `docs/REBUILD_PLAN.md`
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
