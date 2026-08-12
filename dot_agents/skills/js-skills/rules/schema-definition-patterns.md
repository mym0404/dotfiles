---
title: Schema Definition Patterns
impact: HIGH
impactDescription: Keeps Zod schema definitions current, logically grouped, composable, and aligned with domain model creation
tags: zod, schema, naming, composition, inference, createModel, zod4
---

## Schema Definition Patterns

Use one cohesive schema flow: verify current Zod APIs with Context7, group related schemas and helpers by domain ownership, infer types from schemas, reuse meaningful fragments, and create instances through schema-validated model factories.

### Naming, Grouping, and Type Inference

Follow consistent naming for schema files, schema constants, and inferred types. The primary rule is logical grouping, not forced file splitting. Never define a duplicate TypeScript type beside the schema.

**Incorrect:**

```typescript
// File: misc.ts
export const schema = z.object({ ... });
export const sourceSchema = z.object({ ... });
export const resolvedSchema = z.object({ ... });

export type ProfileType = {
  ...
};
```

Why it fails: The file name hides ownership, schema names are too generic to search, and the duplicated type can drift from the schema.

**Correct:**

```typescript
// File: ProductProfile.ts
export const productProfileSourceSchema = z.object({
  ...
});

export const productProfileResolvedSchema = z.object({
  ...
});

export type ProductProfileSource = z.infer<typeof productProfileSourceSchema>;
export type ProductProfileResolved = z.infer<typeof productProfileResolvedSchema>;
```

Rules:

- Prefer file names that reflect the domain concept or cohesive schema family, such as `ProductProfile.ts`.
- Schema constants should be specific and searchable, such as `productProfileSourceSchema`.
- Inferred types should come from schemas with `z.infer`.
- It is fine to export multiple related schemas from one file when they describe the same concept, such as source, resolved, derived, or request/response variants.
- If a schema or schema family is broadly reused across the codebase, it is also fine to split it into its own dedicated file for shared ownership and discoverability.
- Do not split files just to satisfy a one-schema-per-file rule.
- Tightly coupled parser helpers, labels, or UI maps may stay in the same module when they clearly belong to that concept and are not broadly shared.

### Latest Zod Definition API

Check Context7 before introducing or changing schema definition patterns. Prefer current Zod 4 helpers over deprecated chains. Keep simple format validators inline, and avoid extra strictness or transformation unless there is a concrete business requirement.

**Incorrect:**

```typescript
const recordIdSchema = z.string().uuid();
const createdAtSchema = z.string().datetime();
const callbackUrlSchema = z.string().url();

export const webhookSchema = z
  .object({
    id: recordIdSchema,
    createdAt: createdAtSchema,
    callbackUrl: callbackUrlSchema,
    tags: z.array(z.string()).min(1),
  })
  .strict()
  .transform(value => ({
    ...value,
    createdAt: dayjs(value.createdAt),
  }));
```

Why it fails: It uses deprecated format validators, extracts trivial single-use validators, adds strictness and length constraints without domain justification, and converts serialized datetime values at the schema boundary.

**Correct:**

```typescript
const webhookEventSchema = z.object({
  type: z.string(),
  payload: z.string(),
});

export const webhookSchema = z.object({
  id: z.uuid(),
  createdAt: z.iso.datetime(),
  callbackUrl: z.url(),
  tags: z.array(z.string()).optional(),
  events: z.array(webhookEventSchema).optional(),
});
```

Rules:

- Prefer `z.url()`, `z.uuid()`, and `z.iso.datetime()` over deprecated chains such as `z.string().url()`, `z.string().uuid()`, and `z.string().datetime()`.
- Keep simple field-level format validators inline. Do not extract single-use schemas such as `const urlSchema = z.url()`.
- Extract repeated, meaningful schema fragments and reuse them.
- Do not default to `z.strictObject()` or `.strict()`. Use strict object validation only when unknown keys are a real business error.
- Do not add constraints such as `.min(1)` unless the domain explicitly requires them.
- Use `preprocess`, `transform`, `pipe`, and `coerce` only when the input source genuinely requires normalization or coercion.
- Validate serialized datetimes with `z.iso.datetime()`. Do not model schema boundary values as `Date`, `Dayjs`, or codec-driven wrappers.

### Reusable Enum-Like Values

When literal values must be shared between runtime code and a schema, define them once as a const assertion array and derive both the Zod schema and the TypeScript type from that source.

**Incorrect:**

```typescript
type Status = 'pending' | 'active' | 'inactive';

const statusSchema = z.enum(['pending', 'active', 'inactive']);
```

Why it fails: The literal values are duplicated and can drift when one side changes first.

**Correct:**

```typescript
export const allStatuses = ['pending', 'active', 'inactive'] as const;
export type Status = (typeof allStatuses)[number];

export const recordSchema = z.object({
  status: z.enum(allStatuses),
});
```

### Composition and Reuse

Compose schemas through nesting, extending, picking, and partial derivation. Do not re-list the same fields across related schemas.

**Incorrect:**

```typescript
export const personalRecordOmrSchema = z.object({
  name: z.string().max(10),
  xrayCode: z.int(),
  jumin: z.string().regex(/^\d{6}-\d{7}$/),
  highSchool: z.int().optional(),
});
```

Why it fails: Re-listing fields duplicates validation logic and makes schema drift likely.

**Correct:**

```typescript
export const personalRecordOmrSchema = personalRecordSchema
  .pick({
    name: true,
    xrayCode: true,
    jumin: true,
    highSchool: true,
  })
  .partial();
```

```typescript
const detailedScoreSchema = z.object({
  aptitudeScore: z.number().optional(),
  licenseScore: z.number().optional(),
  totalScore: z.number().optional(),
});

export const divisionPreferenceSchema = baseModelSchema.extend({
  basicRecordId: z.uuid(),
  firstPreferenceScores: detailedScoreSchema.optional(),
  secondPreferenceScores: detailedScoreSchema.optional(),
});
```

Related derived schemas can live beside the base schema when that grouping makes the domain easier to understand. Prefer splitting only when a schema family grows independent responsibilities or is reused by clearly separate modules.

### Model Creation

Instantiate domain entities through `createModel` so schema validation and base field generation happen in one path.

**Incorrect:**

```typescript
const record = {
  id: crypto.randomUUID(),
  createdAt: new Date().toISOString(),
  sequence: 1,
  name: 'John',
  sn: '12345678',
};
```

Why it fails: Base field creation is duplicated and the instance bypasses schema validation.

**Correct:**

```typescript
const record = createModel(basicRecordSchema, {
  sequence: 1,
  name: 'John',
  sn: '12345678',
  xrayCode: 100,
  division: 'engineering',
  jumin: '900101-1234567',
});
```

```typescript
export const createModel = <T extends ZodType>(
  schema: T,
  value: Omit<z.infer<T>, keyof BaseModel>,
) => {
  return schema.parse(value);
};
```

Reference:
[Zod 4](https://zod.dev/v4)
[Zod API](https://zod.dev/api)
[Zod Type Inference](https://zod.dev/?id=type-inference)
[TypeScript const assertions](https://www.typescriptlang.org/docs/handbook/release-notes/typescript-3-4.html#const-assertions)
