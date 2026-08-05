# [UI-03] Implement core primitives and form controls in `@jachegai/ui`

## Goal
Build the reusable component primitives that every later pattern depends on. This includes buttons, icon buttons, pills/badges, text inputs, password inputs, textareas, selects, field wrappers, labels, helper/error states, and basic surface components.

These primitives must express the inventory-derived style directly: thick emphasis where needed, clean white fields, compressed labels, and actor-aware CTA variants.

## Why this matters
If the primitive layer is weak, every pattern will reimplement button logic, field spacing, border rules, and state rendering. The inventory already shows these primitives repeatedly across login surfaces, search, checkout, modal input, newsletter, and operational panels.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules

## Scope
- Build `Button`, `IconButton`, `Badge`, `Pill`, `Input`, `PasswordInput`, `Textarea`, `Select`, `Field`, `FieldHint`, `FieldError`, and `Surface` primitives.
- Support visual variants needed by the inventory, especially:
  - dark CTA on yellow
  - seller blue CTA
  - courier coral CTA
  - admin deep-navy CTA
  - quiet/disabled muted action
- Add consistent focus/hover/disabled states.

## Where to work
- `web/packages/ui/src/primitives/`
- `web/packages/ui/src/styles/`
- `web/packages/ui/src/index.ts`
- `web/packages/ui/README.md`

## How to implement
1. Create primitives with typed props and variant APIs.
2. Keep markup minimal and predictable.
3. Implement CSS classes in the package instead of inline visual logic spread across apps.
4. Ensure each primitive behaves well on desktop and mobile widths.
5. Export only stable APIs; avoid leaking internal styling helpers.

## Patterns and guardrails
- Button variants must map to inventory patterns, not generic `primary/secondary` only.
- Inputs must support labels that look like the screenshot style.
- Disabled states must preserve the legacy tone instead of becoming browser-default gray controls.
- Primitives should be composable by patterns without requiring app-local CSS patches.

## Example implementation
```tsx
<Field label="E-mail Corporativo" hint="Use o e-mail de operação da loja.">
  <Input value={email} onChange={setEmail} />
</Field>

<Button variant="seller">Entrar no Painel</Button>
<Button variant="courier">Começar Agora</Button>
<Button variant="admin">Entrar no Sistema</Button>
<Button variant="dark">Alterar Localização</Button>
<Button variant="muted" disabled>Confirmar Localização</Button>
```

## Do Not Do
- Do not style buttons directly inside page files.
- Do not hardcode actor-specific colors in app markup.
- Do not skip disabled/focus/error states.
- Do not use browser-default field rendering.

## Acceptance criteria
- [ ] All primitive controls needed by the inventory are implemented in `@jachegai/ui`.
- [ ] Button variants cover public, seller, courier, admin, dark, and muted actions.
- [ ] Field wrappers support labels, hints, and errors with consistent spacing.
- [ ] Inputs and controls render correctly across desktop, tablet, and mobile widths.
- [ ] Frontend build passes with the primitive exports in place.

## Verification
- `cd web && npm run build`
- consume primitives in at least one local demo or showcase composition

## Out of scope
- Complex composed patterns like auth panels or full footers.
- Migration of app routes.

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
