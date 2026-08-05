# [UI-04] Implement shells, surfaces, overlay/modal structures, dense footer, and trust band patterns

## Goal
Build the structural patterns that define the skin of the product: top bar, marketing shell, modal/overlay container, surface sections, dense footer, and trust band. These are not full screens; they are reusable page-building blocks that the new system will compose.

## Why this matters
The inventory is visually held together less by tiny atoms and more by a few heavy structural patterns: yellow chrome at the top, white/bright content plates, dark footer density, thick-outlined panels, and the lower trust band. If these structures are not packaged, each app surface will drift immediately.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules
- [UI-03] implement core primitives and form controls in `@jachegai/ui`

## Scope
- Implement reusable patterns for:
  - `TopBar`
  - `BrandLockup`
  - `MarketingShell`
  - `SectionSurface`
  - `Overlay`
  - `ModalCard`
  - `DenseFooter`
  - `TrustBand`
- Support composition of both public pages and actor access portals.
- Support mobile collapse behavior.

## Where to work
- `web/packages/ui/src/patterns/`
- `web/packages/ui/src/styles/`
- `web/packages/ui/src/index.ts`
- `web/packages/ui/README.md`

## How to implement
1. Translate recurring structural markup from the inventory into composable React patterns.
2. Keep data/content props separate from visual structure.
3. Ensure footer and trust band can be reused across landing, seller, courier, and admin experiences.
4. Make overlay and modal patterns capable of supporting the location modal and future confirmation dialogs.

## Patterns and guardrails
- The top bar must reflect the inventory styling, not the current white shell.
- Footer density is a feature, not noise. Preserve the heavy informational structure.
- Overlays must support blurred/dimmed backgrounds and centered cards.
- Do not turn these patterns into hardcoded full pages.

## Example implementation
```tsx
<MarketingShell
  topBar={<TopBar brand={<BrandLockup />} nav={navItems} actions={actions} />}
  footer={<DenseFooter columns={footerColumns} newsletter={newsletterProps} />}
  trustBand={<TrustBand items={trustItems} />}
>
  <SectionSurface>
    <Overlay>
      <ModalCard>{content}</ModalCard>
    </Overlay>
  </SectionSurface>
</MarketingShell>
```

## Do Not Do
- Do not keep app-local copies of the top bar/footer once these patterns exist.
- Do not build them as one-off components tied to a single route.
- Do not collapse the footer into a minimalist generic footer.

## Acceptance criteria
- [ ] Reusable top bar, shell, overlay/modal, dense footer, and trust band patterns exist in `@jachegai/ui`.
- [ ] Patterns are content-driven and reusable across actor apps.
- [ ] Mobile/tablet collapse behavior is implemented in the package.
- [ ] Frontend build passes with the new pattern exports.

## Verification
- `cd web && npm run build`
- render these patterns in a local demo or showcase composition

## Out of scope
- Actor-specific portal content.
- Commerce-specific cards and summaries.

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
