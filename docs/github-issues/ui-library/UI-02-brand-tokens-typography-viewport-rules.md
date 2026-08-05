# [UI-02] Implement brand tokens, typography scale, spacing scale, and viewport rules in `@jachegai/ui`

## Goal
Convert the inventory-derived visual language into reusable, package-owned design tokens and responsive rules. This issue must define the actual CSS token layer that the new system will use to look like the old skin while staying adaptable to new flows.

The output of this issue must give the project a stable language for color, typography, radii, spacing, shadows, border weight, surface elevation, and actor-specific accent variants.

## Why this matters
Without a token layer, every later component issue will hardcode values and drift visually. The inventory shows very strong consistency: yellow top bars, heavy italic headlines, thick dark outlines, white access panels, dark footer surfaces, and specific accent colors by actor. Those choices must live in tokens, not in arbitrary component-local styles.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract

## Scope
- Implement `tokens.css` and shared responsive base rules.
- Define typography scales for hero, section title, utility label, card title, body, and microcopy.
- Define spacing/radius/shadow scales based on recurring inventory proportions.
- Define actor accents for seller, courier, admin, and neutral public surfaces.
- Define breakpoint rules for desktop, tablet, and mobile composition.

## Where to work
- `web/packages/ui/src/styles/tokens.css`
- `web/packages/ui/src/styles/base.css`
- `web/packages/ui/src/styles/`
- `web/packages/ui/README.md`

## How to implement
1. Extract canonical values from the inventory screenshots already cataloged in the repo.
2. Define token groups for:
   - brand colors
   - text colors
   - surface colors
   - accent colors per actor
   - spacing
   - radius
   - border widths
   - shadows
   - type sizes and line-heights
3. Add responsive rules for:
   - headline shrink strategy
   - stacked layout behavior on tablet/mobile
   - dense footer collapse
   - modal width handling
4. Document which tokens are stable foundations versus actor/theme variants.

## Patterns and guardrails
- Values must reflect the screenshots, not generic SaaS defaults.
- Do not use Inter/system-default visual tone as the design language.
- Tokens must be expressive enough to style both public marketing surfaces and operational panels.
- Viewport behavior belongs in the package styles, not ad-hoc inside app pages.

## Example implementation
```css
:root {
  --color-brand-yellow: #ffe119;
  --color-surface-dark: #232323;
  --color-surface-panel: #ffffff;
  --color-accent-seller: #3092cf;
  --color-accent-courier: #fc8559;
  --color-accent-admin: #222c40;

  --font-display-size-xl: clamp(3rem, 6vw, 5.5rem);
  --font-display-spacing: -0.08em;
  --radius-panel-xl: 2rem;
  --shadow-panel-hard: 8px 8px 0 rgba(32, 32, 32, 0.95);
}
```

## Do Not Do
- Do not copy token names from `legacy/jachegai/frontend-v2` blindly.
- Do not define only colors and skip type/spacing/border/shadow scales.
- Do not make breakpoints an afterthought.
- Do not encode actor accents directly in app-specific CSS files.

## Acceptance criteria
- [ ] `@jachegai/ui` has a real token layer for color, typography, spacing, radius, borders, and shadows.
- [ ] Actor accents for seller, courier, admin, and neutral/public surfaces are defined.
- [ ] Base responsive rules for desktop, tablet, and mobile are implemented in the package.
- [ ] Token docs explain intended usage.
- [ ] Frontend build passes with the token layer integrated.

## Verification
- `cd web && npm run build`
- inspect token and breakpoint definitions in `web/packages/ui/src/styles/*`

## Out of scope
- Full component implementation.
- App migration.
- Visual QA of every screen.

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
