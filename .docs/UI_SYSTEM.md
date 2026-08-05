# UI System

This document is the single entrypoint for the JaChegai frontend design system, reusable UI library, and inventory-derived visual rules.

## Status

The UI system is official and active.

It is still evolving, but it is already the canonical frontend foundation for the rebuild.

That means:

- `web/packages/ui/` is the official design-system and shared component library.
- real app surfaces should compose from `@jachegai/ui`.
- missing patterns should be added to the library instead of recreated ad hoc in route files.
- the visual source of truth is the inventory under `legacy/inventory/`.

## Source Of Truth

### Operational rules

- [AGENTS.md](/home/passoz/dev/jachegai-next/AGENTS.md)
  - see `## 9A. Design System And UI Library Rules`

### Package contract

- [web/packages/ui/README.md](/home/passoz/dev/jachegai-next/web/packages/ui/README.md)

This README defines:

- package layering
- public contract
- token groups
- composition rules
- example consumption

### Rebuild plan context

- [docs/REBUILD_PLAN.md](/home/passoz/dev/jachegai-next/docs/REBUILD_PLAN.md)

Relevant sections:

- `2026-05-19 Legacy Inventory Design System Slice`
- `2026-05-19 Reusable UI Library Slice`

### Detailed issue-by-issue backlog

- [UI-01](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-01-reset-ui-package-and-contract.md)
- [UI-02](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-02-brand-tokens-typography-viewport-rules.md)
- [UI-03](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-03-primitives-and-form-controls.md)
- [UI-04](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-04-shells-surfaces-overlays-and-footer.md)
- [UI-05](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-05-commerce-discovery-and-cart-patterns.md)
- [UI-06](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-06-access-panels-and-actor-variants.md)
- [UI-07](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-07-operational-data-display-patterns.md)
- [UI-08](/home/passoz/dev/jachegai-next/docs/github-issues/ui-library/UI-08-migrate-showcase-and-add-composition-recipes.md)

These issue docs define:

- scope
- guardrails
- example implementation direction
- acceptance criteria
- verification commands

## Visual Reference

- [legacy/inventory/inventory.md](/home/passoz/dev/jachegai-next/legacy/inventory/inventory.md)

The inventory is visual evidence, not implementation authority.

Rules:

- follow the inventory for visual language, proportion, contrast, hierarchy, and recurring patterns
- do not copy old architecture from legacy
- do not expose `Legacy*` names in public component APIs

## Current Implementation Locations

### Shared library

- [web/packages/ui/src/primitives](/home/passoz/dev/jachegai-next/web/packages/ui/src/primitives)
- [web/packages/ui/src/patterns](/home/passoz/dev/jachegai-next/web/packages/ui/src/patterns)
- [web/packages/ui/src/recipes](/home/passoz/dev/jachegai-next/web/packages/ui/src/recipes)
- [web/packages/ui/src/styles](/home/passoz/dev/jachegai-next/web/packages/ui/src/styles)
- [web/packages/ui/src/index.ts](/home/passoz/dev/jachegai-next/web/packages/ui/src/index.ts)

### Showcase and verification surface

- [web/apps/landing/src/legacy-design-system.tsx](/home/passoz/dev/jachegai-next/web/apps/landing/src/legacy-design-system.tsx)

Purpose:

- prove that the library can compose public, access, commerce, and operational patterns
- provide a live visual inspection route

### Real app adoption

- [web/apps/landing/src/page.tsx](/home/passoz/dev/jachegai-next/web/apps/landing/src/page.tsx)
- [web/apps/customer/src/page.tsx](/home/passoz/dev/jachegai-next/web/apps/customer/src/page.tsx)
- [web/apps/seller/src/page.tsx](/home/passoz/dev/jachegai-next/web/apps/seller/src/page.tsx)
- [web/apps/courier/src/page.tsx](/home/passoz/dev/jachegai-next/web/apps/courier/src/page.tsx)
- [web/apps/admin/src/page.tsx](/home/passoz/dev/jachegai-next/web/apps/admin/src/page.tsx)

Important:

- adoption is uneven
- `landing` already reflects the DS direction directly
- the remaining app surfaces should continue migrating toward DS composition

## Mandatory Rules For Future Work

- Extend `@jachegai/ui` before adding reusable route-local UI.
- Keep viewport behavior inside the shared package when the pattern is reusable.
- Use the showcase and real surfaces as visual verification, not just TypeScript/build success.
- When visual quality and inventory fidelity conflict with convenience, choose inventory fidelity.

## Verification

Minimum checks:

```bash
cd web && npx tsc --noEmit
cd web && npm run build
```

Recommended manual checks:

- inspect `/legacy-design-system`
- inspect `/`
- compare against `legacy/inventory/*.png`

