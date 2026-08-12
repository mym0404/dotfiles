---
title: Dayjs Usage Patterns
impact: HIGH
impactDescription: Ensures consistent date/time handling with proper plugin setup, locale support, and type-safe operations
tags: dayjs, date, time, duration, formatting
---

## Dayjs Usage Patterns

Use dayjs as the sole date/time library. Never mix with raw `Date` or `Date.now()`. Register plugins and locales in a single boot entry point. If the project already defines a standard dayjs plugin set, register all listed plugins there unless a concrete, documented runtime constraint requires leaving one out.

### Plugin Setup

All plugin imports and registrations go in one boot/init file. Name plugin imports as `dayjs` + PascalCase plugin name + `Plugin`. Prefer the full project-approved plugin set over partial registration.

**Incorrect:**

```typescript
// Partial registration in the boot file
import dayjs from 'dayjs';
import dayjsDurationPlugin from 'dayjs/plugin/duration';

dayjs.extend(dayjsDurationPlugin);
```

Why it fails: A centralized boot file exists, but it does not register the full plugin set the project expects. Features that rely on omitted plugins start failing later, and dayjs behavior becomes inconsistent across modules.

**Correct:**

```typescript
// src/bootlogic/bootlogic.ts (single entry point)
import 'dayjs/locale/ko';
import 'dayjs/locale/en';
import dayjs from 'dayjs';
import dayjsArraySupportPlugin from 'dayjs/plugin/arraySupport';
import dayjsDurationPlugin from 'dayjs/plugin/duration';
import dayjsIsoWeekPlugin from 'dayjs/plugin/isoWeek';
import dayjsRelativeTimePlugin from 'dayjs/plugin/relativeTime';
import dayjsIsoTimeZonePlugin from 'dayjs/plugin/timezone';
import dayjsIsoUTCPlugin from 'dayjs/plugin/utc';

// Register the full project-approved plugin set in one place.
dayjs.extend(dayjsDurationPlugin);
dayjs.extend(dayjsArraySupportPlugin);
dayjs.extend(dayjsIsoWeekPlugin);
dayjs.extend(dayjsIsoUTCPlugin);
dayjs.extend(dayjsIsoTimeZonePlugin);
dayjs.extend(dayjsRelativeTimePlugin);
dayjs.locale(currentLocale);
```

Plugin import naming:

| Plugin | Import Alias |
| --- | --- |
| `dayjs/plugin/duration` | `dayjsDurationPlugin` |
| `dayjs/plugin/utc` | `dayjsIsoUTCPlugin` |
| `dayjs/plugin/timezone` | `dayjsIsoTimeZonePlugin` |
| `dayjs/plugin/isoWeek` | `dayjsIsoWeekPlugin` |
| `dayjs/plugin/relativeTime` | `dayjsRelativeTimePlugin` |
| `dayjs/plugin/arraySupport` | `dayjsArraySupportPlugin` |

If the codebase documents a dayjs plugin list, treat that list as the default boot set and register all of it in the central dayjs boot file.

### Timestamp Operations

Use `dayjs().valueOf()` for unix timestamps in milliseconds. Never use `Date.now()` or `new Date().getTime()`.

**Incorrect:**

```typescript
const now = Date.now();
const futureMs = now + 60 * 1000;
const elapsed = Date.now() - startTime;
```

**Correct:**

```typescript
const now = dayjs().valueOf();
const futureMs = dayjs().valueOf() + Const.restoreSeconds * 1000;
const elapsed = dayjs().valueOf() - startUnixMs;
```

### Time Arithmetic

Use dayjs methods (`.add()`, `.diff()`, `.isBefore()`) instead of raw ms arithmetic when computing relative time.

**Incorrect:**

```typescript
const oneYearLater = Date.now() + 365 * 24 * 60 * 60 * 1000;
const diffSec = (targetMs - Date.now()) / 1000;
const isExpired = targetMs < Date.now();
```

**Correct:**

```typescript
const oneYearLater = dayjs().add(1, 'year').valueOf();
const diffSec = dayjs(targetMs).diff(dayjs(), 'second');
const isExpired = dayjs(targetMs).isBefore(dayjs());
```

### Formatting

Use `.format()` with explicit format strings.

```typescript
dayjs(timestamp).format('YYYY/MM/DD HH:mm');
```

### Duration

Use `dayjs.duration()` for representing time spans. Wrap in utility functions for common units.

```typescript
export const durationSec = (sec: number) => dayjs.duration(sec, 'second');
export const durationMs = (ms: number) => dayjs.duration(ms, 'millisecond');
```

Reference:
[dayjs documentation](https://day.js.org/)
[dayjs plugins](https://day.js.org/docs/en/plugin/plugin)
