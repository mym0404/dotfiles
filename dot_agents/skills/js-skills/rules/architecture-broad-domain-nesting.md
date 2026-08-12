---
title: Organize Code by Feature and Keep Feature-Specific Code Inside feature/{domain}
impact: HIGH
impactDescription: Keeps feature ownership clear by grouping code by feature, keeping feature-specific code inside feature folders, keeping shared code in feature/common, and nesting submodules under the owning feature
tags: typescript, javascript, architecture, domain, folder, feature
---

## Organize Code by Feature and Keep Feature-Specific Code Inside feature/{domain}

When a codebase is organized by folders, prefer feature-first structure. Top-level feature folders should represent real product/application features, feature-specific code such as `model`, `types`, and `ui` should live under `feature/{domain}`, shared cross-feature code should live under `feature/common`, and submodules should stay inside the feature that owns them instead of becoming new sibling roots.

Default to `feature/{domain}`. Only when a child area is genuinely large enough and tightly coupled to its parent feature, allow one nested split as `feature/{parent}/feature/{child}/...`. Do not let nested feature depth exceed 2.

**Incorrect:**

```text
src/model/auth/User.ts
src/types/auth/Role.ts
src/ui/auth/LoginPage.tsx
src/feature/campaign-logs/
src/feature/campaign-results/
src/feature/hooks/
src/feature/utils/
src/feature/components/
src/feature/campaigns/feature/results/feature/export/
```

Why it fails: Related code gets split by technical type instead of ownership. Shared and feature-specific pieces are mixed together, feature-owned folders escape their feature boundary, parent-owned areas such as `campaign-logs` or `campaign-results` drift into fake top-level features, and nested feature depth grows beyond what remains easy to scan.

**Correct:**

```text
src/
  feature/
    common/
      hooks/
      providers/
      utils/
      ui/
        components/
    auth/
      model/
      types/
      ui/
        pages/
    campaigns/
      model/
      types/
      hooks/
      providers/
      repositories/
      logic/
      ui/
        components/
        pages/
      feature/
        logs/
        results/
    accounts/
      model/
      types/
      hooks/
      providers/
      repositories/
      logic/
      ui/
        pages/
```

Feature folders may contain only the subfolders they actually need. Common examples are:

- `model/`
- `types/`
- `utils/`
- `hooks/`
- `providers/`
- `repositories/`
- `logic/`
- `ui/components/`
- `ui/pages/`

Apply this rule as follows:

- Split primary application code by feature ownership first.
- Put feature-specific folders such as `model`, `types`, and feature-local `ui` inside `feature/{domain}/`.
- Put cross-feature reusable code in `feature/common/`.
- Keep parent-owned submodules such as `logs`, `results`, `forms`, or `templates` under the owning feature.
- Only when separation is unavoidable, split a child area as `feature/{parent}/feature/{child}/`.
- Do not nest `feature/.../feature/.../feature/...`; maximum nested feature depth is 2.
- Do not create new top-level feature folders just because a nested area has multiple files.

Use this pattern when:

- a module belongs clearly to one feature
- some helpers are reused widely enough to justify `feature/common/`
- a nested area shares lifecycle, ownership, or vocabulary with its parent feature

Reference:
[Bounded Context](https://martinfowler.com/bliki/BoundedContext.html)
