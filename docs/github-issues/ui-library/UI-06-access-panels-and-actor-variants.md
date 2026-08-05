# [UI-06] Implement access panel patterns and actor variants in `@jachegai/ui`

## Goal
Package the recurring access portal layout used by seller, courier, and admin into reusable components and recipes. This issue must turn the repeated split-screen + hero + outlined access card structure into a flexible API that the new system can reuse for new flows without reauthoring the markup.

## Why this matters
The inventory shows a clear product rule: access portals are not generic login screens. They are role-branded landing structures with a shared skeleton and actor-specific CTA, helper text, and hero tone. This is one of the highest-signal reusable patterns in the entire visual system.

## Dependencies
- [UI-01] reset `@jachegai/ui` package and define the reusable library contract
- [UI-02] implement brand tokens, typography scale, spacing scale, and viewport rules
- [UI-03] implement core primitives and form controls in `@jachegai/ui`
- [UI-04] implement shells, surfaces, overlay/modal structures, dense footer, and trust band patterns

## Scope
- Implement reusable patterns for:
  - `AccessHero`
  - `AccessPanel`
  - `AccessLayout`
  - actor variants for seller, courier, admin, and generic/public use
- Support content slots for title, subtitle, fields, helper actions, legal copy, and badges.
- Support mobile stacking without losing the visual structure.

## Where to work
- `web/packages/ui/src/patterns/`
- `web/packages/ui/src/recipes/`
- `web/packages/ui/src/index.ts`

## How to implement
1. Extract the common structure across seller/admin/courier inventory screens.
2. Build an `AccessLayout` that composes a hero region and a panel region.
3. Expose actor variants through props or theme tokens, not duplicated components.
4. Add recipe examples for seller portal, courier portal, and admin restricted access.

## Patterns and guardrails
- The actor variants must share structure while allowing different accents and copy.
- Do not hardcode login-specific behavior into the visual component itself.
- The visual pattern must be reusable later for onboarding, invite acceptance, or gated settings flows.
- Preserve thick outlined panels and heavy hero typography.

## Example implementation
```tsx
<AccessLayout
  variant="seller"
  hero={
    <AccessHero
      title="Entregando gelada no preço de supermercado."
      subtitle="Leve seu depósito para o digital e venda mais bebidas."
      badgeText="+10k depósitos ativos"
    />
  }
  panel={
    <AccessPanel
      title="Login do lojista"
      subtitle="Acesse seu painel para gerenciar sua loja."
      footerHint="Solicite sua conta"
    >
      <Field label="E-mail corporativo"><Input /></Field>
      <Field label="Senha"><PasswordInput /></Field>
      <Button variant="seller">Entrar no painel</Button>
    </AccessPanel>
  }
/>
```

## Do Not Do
- Do not implement separate one-off seller/admin/courier pages in the package.
- Do not bake business auth logic into the visual pattern layer.
- Do not simplify the portal into a generic centered card login.

## Acceptance criteria
- [ ] Access portal patterns are implemented in `@jachegai/ui`.
- [ ] Seller, courier, and admin variants are supported without duplicated public component names.
- [ ] Mobile stacking behavior is implemented.
- [ ] Example compositions for at least seller, courier, and admin are included.
- [ ] Frontend build passes.

## Verification
- `cd web && npm run build`
- render seller/courier/admin portal examples with the package exports

## Out of scope
- Full auth flow wiring.
- Product-specific API calls.

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
