# [UI-07] Implement operational data-display patterns for seller, courier, and admin flows in `@jachegai/ui`

## Goal
Build reusable operational patterns for the new system: metric strips, approval/status pills, queue cards, data tables, summary rows, and progress/timeline blocks. These are the building blocks needed to compose seller dashboards, courier queues, and admin moderation/credentialing views.

## Why this matters
The inventory does not only contain marketing and login surfaces. It also implies a dense operational layer with tables, approval states, compact metrics, and queue-style content. If these patterns stay app-local, the new system will fragment between actor areas.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules
- [UI-03] implement core primitives and form controls in `@jachegai/ui`
- [UI-04] implement shells, surfaces, overlay/modal structures, dense footer, and trust band patterns

## Scope
- Implement reusable operational patterns for:
  - `MetricStrip`
  - `MetricCard`
  - `StatusPill`
  - `DataTable`
  - `QueueCard`
  - `ApprovalCard`
  - `Timeline`
  - `SummaryRow`
- Ensure components are generic enough for seller, courier, and admin data models.
- Provide viewport behavior for dense data on tablet/mobile.

## Where to work
- `web/packages/ui/src/patterns/`
- `web/packages/ui/src/recipes/`
- `web/packages/ui/src/index.ts`

## How to implement
1. Define operational display primitives and higher-level patterns.
2. Support density management on narrow screens by stacking or collapsing appropriately.
3. Make `StatusPill` variant-driven so flows can express neutral/warning/success/restricted states consistently.
4. Add example recipes for admin credentialing, seller inventory summary, and courier queue list.

## Patterns and guardrails
- Avoid generic enterprise-table defaults that lose the product’s visual identity.
- Operational surfaces must still look like the same product family as public and auth surfaces.
- Preserve strong headings, contrast, and pill language.
- Components must accept real app data rather than hardcoded legacy labels.

## Example implementation
```tsx
<DataTable
  columns={[
    { key: 'name', label: 'Operação' },
    { key: 'owner', label: 'Responsável' },
    {
      key: 'status',
      label: 'Etapa',
      render: (row) => <StatusPill tone={row.statusTone}>{row.statusLabel}</StatusPill>,
    },
  ]}
  rows={rows}
/>

<MetricStrip>
  <MetricCard label="Pedidos hoje" value="42" />
  <MetricCard label="Pendências" value="7" />
</MetricStrip>
```

## Do Not Do
- Do not implement data tables as raw `<table>` markup inside app pages.
- Do not hardcode seller/admin/courier wording into generic components.
- Do not drop responsive handling for dense operational content.

## Acceptance criteria
- [ ] Reusable operational data-display patterns exist in `@jachegai/ui`.
- [ ] Components support seller, courier, and admin use cases without actor-specific naming in the public API.
- [ ] Responsive behavior exists for dense operational content.
- [ ] Example recipes for admin, seller, and courier operational sections are included.
- [ ] Frontend build passes.

## Verification
- `cd web && npm run build`
- render at least one admin, one seller, and one courier operational example using the package

## Out of scope
- Wiring real data fetching.
- Full page migration.

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
