# 🎨 Design System Guidelines

**Last Updated:** 2026-05-03  
**Status:** Phase 5 - Mature  
**Health Score:** 62/100 → Target: 75/100

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Design Token Hierarchy](#design-token-hierarchy)
3. [Component Integration](#component-integration)
4. [Color Usage](#color-usage)
5. [Spacing System](#spacing-system)
6. [Typography](#typography)
7. [Elevation & Shadows](#elevation--shadows)
8. [Z-Index Stacking](#z-index-stacking)
9. [Dark Mode](#dark-mode)
10. [Common Patterns](#common-patterns)
11. [What NOT to Do](#what-not-to-do)
12. [Migration Guide](#migration-guide)
13. [Testing & Validation](#testing--validation)

---

## Quick Start

### For New Components

```vue
<script setup>
import { computed } from 'vue';
import { useColorStyle } from 'dashboard/composables/useColorStyle';

const props = defineProps({
  color: String,
  size: { type: String, default: 'md' }
});

const { getColorDotStyle } = useColorStyle();
const colorStyle = computed(() => getColorDotStyle(props.color).value);
</script>

<template>
  <div class="p-4 shadow-md rounded-lg">
    <!-- Use Tailwind classes (preferred) -->
    <button class="px-4 py-2 rounded-lg shadow-normal">
      Save
    </button>
    
    <!-- Or computed style objects (for dynamic values) -->
    <div :style="colorStyle" class="w-4 h-4 rounded-full" />
  </div>
</template>

<style scoped>
/* Use CSS variables for static styles */
.card {
  padding: var(--padding-lg);
  box-shadow: var(--shadow-normal);
  border-radius: var(--radius-lg);
  color: rgb(var(--slate-12));
}
</style>
```

### Token Files Reference

```
app/javascript/dashboard/assets/scss/
├── _design-tokens.scss          ← Import this in main stylesheet
├── _next-colors.scss            ← Radix UI color palettes
├── _semantic-color-tokens.scss  ← Intent-based colors (primary, error, etc.)
├── _spacing-tokens.scss         ← Spacing scale (px, py, gap, etc.)
├── _typography-tokens.scss      ← Font sizes, weights, line-heights
├── _shadow-tokens.scss          ← Elevation system
└── _z-index-tokens.scss         ← Stacking context layers
```

---

## Design Token Hierarchy

```
Level 1: Raw Radix Palette (--iris-1 to --iris-12)
  ↓
Level 2: Semantic Colors (--color-primary-bg, --color-error-text)
  ↓
Level 3: Component Tokens (--color-button-primary-bg)
  ↓
Level 4: Dynamic Colors (via useColorStyle composable)
  ↓
Level 5: Tailwind Classes (most preferred)
```

**Usage Priority:**
1. 🥇 **Tailwind classes** — `class="p-4 shadow-md text-lg"`
2. 🥈 **Component-specific tokens** — `var(--color-button-primary-bg)`
3. 🥉 **Semantic tokens** — `var(--color-primary-solid)`
4. 🏅 **Dynamic colors** — `useColorStyle()` composable
5. ❌ **Raw palettes** — Only in exceptional cases

---

## Component Integration

### Example 1: Label Component (Dynamic Color)

```vue
<script setup>
import { computed } from 'vue';
import { useColorStyle } from 'dashboard/composables/useColorStyle';

const props = defineProps({
  label: {
    type: Object,
    required: true,
    // label.color = hex color from API (e.g., "#FF5733")
  }
});

const { getColorDotStyle } = useColorStyle();
const colorDotStyle = computed(() => 
  getColorDotStyle(props.label.color).value
);
</script>

<template>
  <div class="flex items-center gap-2 px-3 py-1 rounded-lg bg-slate-100">
    <!-- Dynamic color indicator -->
    <span
      class="w-2 h-2 rounded-full"
      :style="colorDotStyle"
    />
    {{ props.label.name }}
  </div>
</template>
```

### Example 2: Pipeline Stage (Static + Dynamic)

```vue
<script setup>
import { computed } from 'vue';
import { useColorStyle } from 'dashboard/composables/useColorStyle';

const props = defineProps({
  stage: { type: Object, required: true }
});

const { getColorDotStyle } = useColorStyle();
const stageIndicatorStyle = computed(() =>
  getColorDotStyle(props.stage.color).value
);
</script>

<template>
  <div class="p-4 shadow-normal rounded-2xl">
    <!-- Stage indicator with dynamic color -->
    <div class="flex items-center gap-2">
      <div
        class="w-2 h-6 rounded-full"
        :style="stageIndicatorStyle"
      />
      <h3 class="text-sm font-bold">{{ props.stage.name }}</h3>
    </div>
  </div>
</template>
```

---

## Color Usage

### Semantic Color Intents

Use semantic names, not raw palettes:

```scss
// ❌ WRONG
.button {
  background: rgb(var(--iris-9));
  color: rgb(var(--slate-1));
}

// ✅ CORRECT
.button {
  background: var(--color-button-primary-bg);
  color: var(--color-button-primary-text);
}
```

### Available Semantic Intents

| Intent | Use Case | Primary Token |
|--------|----------|---|
| `primary` | Main actions, brand color | `--color-primary-solid` |
| `secondary` | Alternative actions | `--color-secondary-solid` |
| `success` | Positive actions, confirmations | `--color-success-solid` |
| `error` | Errors, destructive actions | `--color-error-solid` |
| `warning` | Cautions, alerts | `--color-warning-solid` |
| `info` | Information, neutral | `--color-info-solid` |
| `neutral` | Defaults, disabled | `--color-neutral-solid` |

### Dynamic Color Validation

Always validate dynamic colors before using:

```vue
<script setup>
import { isValidCssColor } from 'dashboard/helpers/colorHelper';

const props = defineProps({
  customColor: String
});

// This is safe - invalid colors return empty object
const customStyle = computed(() => ({
  background: isValidCssColor(props.customColor) 
    ? props.customColor 
    : 'var(--n-slate-3)'
}));
</script>
```

---

## Spacing System

### Spacing Tokens (4px baseline)

```scss
--space-0:   0
--space-1:   0.25rem (4px)
--space-2:   0.5rem  (8px)
--space-3:   0.75rem (12px)
--space-4:   1rem    (16px)
--space-6:   1.5rem  (24px)
--space-8:   2rem    (32px)
--space-12:  3rem    (48px)
--space-16:  4rem    (64px)
```

### Semantic Spacing Names

```scss
--space-xs:  4px   (extra small)
--space-sm:  8px   (small)
--space-md:  16px  (medium - default)
--space-lg:  24px  (large)
--space-xl:  32px  (extra large)
```

### Component-Specific Spacing

```vue
<div class="p-4 m-2 gap-3">
  <!-- p-4 = 16px padding (--space-4 / --padding-md) -->
  <!-- m-2 = 8px margin (--space-2 / --margin-sm) -->
  <!-- gap-3 = 12px gap (--space-3 / --gap-sm) -->
</div>
```

---

## Typography

### Font Sizes

| Token | Value | Use Case |
|-------|-------|----------|
| `--font-size-xs` | 12px | Small labels, captions |
| `--font-size-sm` | 14px | Buttons, small text |
| `--font-size-base` | 16px | Body text, default |
| `--font-size-lg` | 18px | Subheadings |
| `--font-size-xl` | 20px | Headings |
| `--font-size-2xl` | 24px | Page titles |

### Font Weights

```scss
--font-weight-regular:   400
--font-weight-medium:    500
--font-weight-semibold:  600
--font-weight-bold:      700
```

### Line Heights (per size)

```scss
--line-height-xs:    1.25
--line-height-sm:    1.375
--line-height-base:  1.5
--line-height-lg:    1.5
--line-height-xl:    1.4
```

### Typography Presets

```scss
--text-button:  sm + semibold
--text-label:   xs + semibold
--text-body:    base + regular
--text-h1:      2xl + bold
--text-h2:      xl + bold
--text-h3:      lg + semibold
```

---

## Elevation & Shadows

### Shadow Levels

```scss
--shadow-subtle:   0 1px 2px 0 rgb(0 0 0 / 0.05)
--shadow-normal:   0 4px 6px -1px rgb(0 0 0 / 0.1)
--shadow-strong:   0 10px 15px -3px rgb(0 0 0 / 0.1)
--shadow-floating: 0 20px 25px -5px rgb(0 0 0 / 0.1)
```

### Component-Specific Shadows

```scss
--shadow-card:          subtle
--shadow-button:        subtle (hover: normal)
--shadow-dropdown:      strong
--shadow-modal:         floating
--shadow-toast:         strong
--shadow-sticky-header: normal
```

### Usage

```vue
<div class="shadow-normal rounded-lg p-4">
  <!-- Default card shadow -->
</div>

<div class="shadow-lg rounded-lg">
  <!-- Elevated card (Tailwind: shadow-lg = --shadow-strong) -->
</div>

<div class="shadow-xl rounded-lg">
  <!-- Floating card (Tailwind: shadow-xl = --shadow-floating) -->
</div>
```

---

## Z-Index Stacking

### Layer Structure

```scss
--z-base:      0-9   (normal flow, page background)
--z-content:   10-19 (sticky headers, floating buttons)
--z-dropdown:  20-29 (dropdowns, menus)
--z-popover:   30-39 (popovers, tooltips)
--z-modal:     40-49 (modals, dialogs)
--z-toast:     50-59 (toasts, notifications)
```

### Specific Tokens

```scss
--z-sticky:          11  (sticky headers)
--z-floating:        12  (FAB button)
--z-dropdown:        20  (dropdown menu)
--z-modal-backdrop:  40  (modal scrim)
--z-modal:           41  (modal itself)
--z-toast:           50  (toast notification)
```

### Usage

```vue
<div class="z-10">Sticky header</div>
<div class="z-20">Dropdown menu</div>
<div class="z-40">Modal dialog</div>
<div class="z-50">Toast notification</div>
```

---

## Dark Mode

### Automatic Dark Mode Support

All tokens automatically support light/dark modes via Radix palette:

```scss
// Light mode (default)
:root {
  --slate-12: 28 32 36;  // Dark text
}

// Dark mode
.dark {
  --slate-12: 237 238 240;  // Light text
}
```

### Enabling Dark Mode

```html
<!-- Add class to html or body -->
<html class="dark">
  <!-- All tokens automatically invert -->
</html>
```

### Dark Mode Best Practices

✅ Let tokens handle color inversion automatically  
✅ Test components in both light and dark modes  
✅ Use semantic tokens (colors adjust automatically)  
❌ Don't hardcode different colors for dark mode  
❌ Don't add custom dark mode classes (tokens handle it)

---

## Common Patterns

### Pattern 1: Button with Icon

```vue
<template>
  <button class="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-semantic-primary text-white">
    <i class="i-lucide-check" />
    Save
  </button>
</template>
```

### Pattern 2: Card with Shadow

```vue
<template>
  <div class="p-4 rounded-lg shadow-normal bg-white dark:bg-n-slate-1">
    <h3 class="text-lg font-semibold text-n-slate-12">Card Title</h3>
    <p class="text-base text-n-slate-11 mt-2">Card content</p>
  </div>
</template>
```

### Pattern 3: Badge with Dynamic Color

```vue
<script setup>
import { useColorStyle } from 'dashboard/composables/useColorStyle';

const props = defineProps({ label: Object });
const { getColorDotStyle } = useColorStyle();
const colorStyle = computed(() => getColorDotStyle(props.label.color).value);
</script>

<template>
  <span class="inline-flex items-center gap-1 px-2 py-1 rounded-full text-xs font-semibold"
    :style="{ backgroundColor: colorStyle.backgroundColor || 'var(--n-slate-3)', color: 'white' }">
    <span :style="colorStyle" class="w-1.5 h-1.5 rounded-full" />
    {{ props.label.name }}
  </span>
</template>
```

### Pattern 4: Form Input

```vue
<template>
  <div class="flex flex-col gap-2">
    <label class="text-xs font-semibold text-n-slate-12">Email Address</label>
    <input
      type="email"
      class="px-3 py-2 rounded-lg border border-n-slate-3 focus:border-n-iris-6 focus:outline-none bg-white"
      placeholder="your@email.com"
    />
  </div>
</template>
```

---

## What NOT to Do

### ❌ DON'T: Hardcode Colors

```vue
<!-- WRONG -->
<div style="background: #FF5733; color: #FFFFFF;">
  Content
</div>
```

**WHY:** Breaks design consistency, hard to maintain, doesn't support dark mode.

**FIX:**
```vue
<!-- RIGHT -->
<div class="bg-semantic-error text-white">
  Content
</div>
```

### ❌ DON'T: Use Arbitrary Spacing

```vue
<!-- WRONG -->
<div style="padding: 23px; margin: 11px;">
  Content
</div>
```

**WHY:** Breaks spacing rhythm, not maintainable.

**FIX:**
```vue
<!-- RIGHT -->
<div class="p-6 m-3">
  Content
</div>
```

### ❌ DON'T: Inline Shadow Values

```scss
// WRONG
.card {
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
}
```

**FIX:**
```scss
// RIGHT
.card {
  box-shadow: var(--shadow-normal);
}
```

### ❌ DON'T: Static Inline Styles (ESLint Will Catch This)

```vue
<!-- WRONG - ESLint violation -->
<div :style="{ color: 'red', padding: '10px' }">
  Content
</div>
```

**FIX:**
```vue
<!-- RIGHT - Computed property -->
<script setup>
const dynamicStyle = computed(() => ({
  color: props.variant === 'error' ? 'red' : 'blue',
  padding: 'var(--padding-md)',
}));
</script>

<template>
  <div :style="dynamicStyle">Content</div>
</template>
```

---

## Migration Guide

### Converting Old Components

**Before (hardcoded):**
```vue
<template>
  <div style="padding: 16px; background: #F5F5F5; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
    <h3 style="font-size: 18px; font-weight: 600; color: #1C2024;">
      Title
    </h3>
  </div>
</template>
```

**After (tokenized):**
```vue
<template>
  <div class="p-4 bg-slate-2 shadow-normal rounded-lg">
    <h3 class="text-lg font-semibold text-slate-12">Title</h3>
  </div>
</template>
```

### Step-by-Step Migration

1. **Replace hardcoded colors** → Use semantic tokens
2. **Replace hardcoded spacing** → Use Tailwind spacing classes (p-4, m-2, gap-3)
3. **Replace inline shadows** → Use `var(--shadow-*)` or Tailwind shadow classes
4. **Replace font sizes** → Use `text-sm`, `text-base`, `text-lg` classes
5. **Test dark mode** → Verify component looks good with `class="dark"`

---

## Testing & Validation

### Run Violation Detector

```bash
npm run detect-violations
```

This scans for:
- ✓ Hardcoded hex colors (#FFF, #123456)
- ✓ Hardcoded rgb/rgba colors
- ✓ Hardcoded spacing (px, rem)
- ✓ Static inline styles
- ✓ Naming convention violations

### Manual Checklist

- [ ] Component uses Tailwind classes (preferred)
- [ ] No hardcoded colors (use semantic tokens)
- [ ] No hardcoded spacing (use Tailwind or tokens)
- [ ] Dynamic colors use `useColorStyle()` composable
- [ ] Component tested in light mode
- [ ] Component tested in dark mode
- [ ] Passes ESLint (no static inline styles)
- [ ] Accessible (proper contrast, semantic HTML)

### Dark Mode Testing

```bash
# Manually test dark mode:
1. Open DevTools
2. In Console: document.documentElement.classList.add('dark')
3. Component should still look good and readable
4. Test all interactive states (hover, focus, active)
```

---

## Resources

- **Token Files:** `app/javascript/dashboard/assets/scss/TOKENS.md`
- **Color Helper:** `app/javascript/dashboard/helpers/colorHelper.js`
- **Color Composable:** `app/javascript/dashboard/composables/useColorStyle.js`
- **Token Exporter:** `app/javascript/dashboard/helpers/tokenExporter.js`
- **Violation Detector:** `bin/detect-design-violations.js`

---

## Contact & Questions

For design system questions or improvements:
1. Check existing issues in the project
2. Review TOKENS.md for token definitions
3. Consult ColorHelper API for color utilities
4. Run violation detector for compliance checks

---

**Version:** 1.0 (Phase 5)  
**Last Updated:** 2026-05-03  
**Status:** ✅ Mature
