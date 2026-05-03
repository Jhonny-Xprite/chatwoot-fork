# 🎨 Design Tokens Documentation

## Overview

This directory contains the design token system for Chatwoot CRM Fork. Tokens define all visual properties: colors, spacing, typography, shadows, and z-index.

**Current Health Score: 38/100 → Target: 75/100**

---

## Token Categories

### 1. Colors (`_next-colors.scss`)
- **Status:** ✅ Excellent (92/100)
- **System:** Radix UI 8-color palette (12 steps each)
- **Coverage:** 94 tokens defined, 85% used
- **Features:** Light/Dark mode support, semantic aliases

**Palettes:**
- Slate (grayscale)
- Iris (primary)
- Blue (accent)
- Ruby (error)
- Amber (warning)
- Teal (success)
- Gray (neutral)
- Violet (secondary)

**Usage:**
```scss
color: rgb(var(--slate-12));
background: rgb(var(--iris-9));
border-color: rgb(var(--blue-6));
```

---

### 2. Semantic Colors (`_semantic-color-tokens.scss`)
- **Status:** ✅ New (created Phase 3)
- **System:** Intent-based color mapping
- **Purpose:** Enable global color scheme changes without modifying component code
- **Intents:** primary, secondary, error, success, warning, neutral, info
- **Features:** 8 variants per intent (bg, bg-hover, border, border-strong, text, text-subtle, badge, solid)

**Color Intent Mapping:**

| Intent | Palette | Use Case |
|--------|---------|----------|
| Primary | Iris (blue) | Brand color, main actions, primary buttons |
| Secondary | Violet (purple) | Alternative actions, less emphasis |
| Success | Teal (green) | Positive actions, confirmations, achievements |
| Warning | Amber (orange/yellow) | Cautions, alerts, attention needed |
| Error | Ruby (red) | Errors, deletions, destructive actions |
| Info | Blue | Information, neutral communication |
| Neutral | Slate (gray) | Default, disabled, neutral states |

**Token Structure:**
Each intent has 8 variants:
- `--color-{intent}-bg` → Light background
- `--color-{intent}-bg-hover` → Hover state
- `--color-{intent}-border` → Standard border
- `--color-{intent}-border-strong` → Strong border/outline
- `--color-{intent}-text` → Primary text
- `--color-{intent}-text-subtle` → Secondary/subtle text
- `--color-{intent}-badge` → Badge background
- `--color-{intent}-solid` → Solid button background

**Component-Specific Tokens:**
- Button colors: `--color-button-primary-bg`, `--color-button-primary-text`, etc.
- Form colors: `--color-input-bg`, `--color-input-border`, `--color-input-border-focus`
- Label colors: `--color-label-bg`, `--color-label-text`
- Alert colors: `--color-alert-error-bg`, `--color-alert-success-text`, etc.

**Usage Examples:**

```scss
// Before (hardcoded specific colors)
.button-primary {
  background: rgb(var(--iris-9));
  color: rgb(var(--slate-1));
}

// After (semantic intent)
.button-primary {
  background: var(--color-button-primary-bg);
  color: var(--color-button-primary-text);
}
```

**Key Benefits:**
1. **Intent is clear:** "primary button" vs. "iris-9"
2. **Easy to swap:** Change `--color-primary-solid`, all primaries update globally
3. **Dark mode:** Automatic (Radix handles inversion)
4. **Component tokens:** Specific `--color-button-*` for button-only colors
5. **Future-proof:** Brand color changes require only token updates

**Dark Mode Behavior:**
Semantic tokens automatically invert in dark mode:
- Light: `--color-primary-bg` = iris-3 (very light iris)
- Dark: `--color-primary-bg` = iris-2 (automatically adjusted by Radix)

**Tailwind Integration:**
```html
<button class="bg-semantic-primary text-white">Primary Button</button>
<div class="bg-semantic-error text-error-text">Error State</div>
```

---

### 3. Spacing (`_spacing-tokens.scss`)
- **Status:** 🟡 New (created Phase 1)
- **System:** 4px baseline scale
- **Scale:** 0, 0.5, 1, 2, 3, 4, 6, 8, 12, 16, 24, 32
- **Tokens:** 12 numeric + 8 semantic + component-specific

**Semantic Names:**
- `--space-xs` → 4px
- `--space-sm` → 8px
- `--space-md` → 16px (default)
- `--space-lg` → 24px
- `--space-xl` → 32px
- ... up to `--space-5xl` (128px)

**Component-Specific:**
- `--padding-xs/sm/md/lg/xl`
- `--gap-xs/sm/md/lg/xl`
- `--margin-xs/sm/md/lg/xl`

**Usage:**
```scss
padding: var(--padding-md);
margin: var(--margin-lg);
gap: var(--gap-sm);
```

**Tailwind Integration:**
Tailwind classes automatically use these tokens:
```html
<div class="p-4 m-2 gap-3">
  <!-- p-4 = 16px (--space-4) -->
  <!-- m-2 = 8px (--space-2) -->
  <!-- gap-3 = 12px (--space-3) -->
</div>
```

---

### 4. Typography (`_typography-tokens.scss`)
- **Status:** 🟡 New (created Phase 1)
- **System:** 6-point typographic scale
- **Scales:** xs, sm, base, lg, xl, 2xl
- **Tokens:** 30+ (includes line-height, letter-spacing, font-weight)

**Font Sizes:**
- `--font-size-xs` → 12px
- `--font-size-sm` → 14px
- `--font-size-base` → 16px (default)
- `--font-size-lg` → 18px
- `--font-size-xl` → 20px
- `--font-size-2xl` → 24px

**Font Weight Tokens:**
- `--font-weight-regular` → 400
- `--font-weight-medium` → 500
- `--font-weight-semibold` → 600
- `--font-weight-bold` → 700

**Line Height (per size):**
- xs: 1.25
- sm: 1.375
- base: 1.5
- lg: 1.5
- xl: 1.4
- 2xl: 1.4

**Preset Combinations:**
- `--text-button` → sm + semibold
- `--text-label` → xs + semibold
- `--text-body` → base + regular
- `--text-h1` → 2xl + bold
- `--text-h2` → xl + bold
- `--text-h3` → lg + semibold

**Usage:**
```scss
font-size: var(--font-size-lg);
font-weight: var(--font-weight-semibold);
line-height: var(--line-height-lg);
```

**Tailwind Integration:**
```html
<h1 class="text-2xl font-bold">Heading</h1>  <!-- Uses --font-size-2xl + bold -->
<p class="text-base font-normal">Body</p>    <!-- Uses --font-size-base -->
<label class="text-xs font-semibold">Label</label>  <!-- Uses --font-size-xs + semibold -->
```

---

### 5. Shadows & Elevation (`_shadow-tokens.scss`)
- **Status:** 🟡 New (created Phase 1)
- **System:** 4-level elevation hierarchy
- **Levels:** subtle (1), normal (2), strong (3), floating (4)
- **Features:** Light/Dark mode parity

**Elevation Levels:**

| Level | Token | Use Case | Shadow |
|-------|-------|----------|--------|
| 1 | `--elevation-subtle` | Cards at rest, inputs | `0 1px 2px 0 rgb(0 0 0 / 0.05)` |
| 2 | `--elevation-normal` | Default, buttons hover | `0 4px 6px -1px rgb(0 0 0 / 0.1)` |
| 3 | `--elevation-strong` | Dropdowns, popovers | `0 10px 15px -3px rgb(0 0 0 / 0.1)` |
| 4 | `--elevation-floating` | Modals, dialogs, toast | `0 20px 25px -5px rgb(0 0 0 / 0.1)` |

**Component-Specific:**
- `--shadow-card` → subtle
- `--shadow-button` → subtle
- `--shadow-dropdown` → strong
- `--shadow-modal` → floating
- `--shadow-toast` → strong

**Dark Mode:** Shadows automatically strengthen in dark mode for visibility.

**Usage:**
```scss
box-shadow: var(--shadow-normal);
box-shadow: var(--elevation-strong);
```

**Tailwind Integration:**
```html
<div class="shadow-md">Normal elevation</div>
<div class="shadow-lg">Strong elevation</div>
<div class="shadow-xl">Floating elevation</div>
```

---

### 5. Z-Index Hierarchy (`_z-index-tokens.scss`)
- **Status:** 🟡 New (created Phase 1)
- **System:** Layered stacking context
- **Layers:** 6 (base, content, dropdown, popover, modal, toast)
- **Range:** 0-50 (10-unit spacing per layer)

**Layer Structure:**

| Layer | Range | Token | Use Case |
|-------|-------|-------|----------|
| Base | 0-9 | `--z-base` | Page background, normal flow |
| Content | 10-19 | `--z-content` | Sticky headers, floating buttons |
| Dropdown | 20-29 | `--z-dropdown` | Dropdowns, menus |
| Popover | 30-39 | `--z-popover` | Popovers, tooltips |
| Modal | 40-49 | `--z-modal` | Modal dialogs, drawers |
| Toast | 50-59 | `--z-toast` | Toasts, notifications |

**Specific Tokens:**
- `--z-sticky` → 11 (sticky headers)
- `--z-floating` → 12 (FAB button)
- `--z-dropdown` → 20 (dropdown menu)
- `--z-modal-backdrop` → 40 (modal scrim)
- `--z-modal` → 41 (modal itself)
- `--z-toast` → 50 (notification toast)

**Usage:**
```scss
z-index: var(--z-modal);
z-index: var(--z-dropdown);
```

**Tailwind Integration:**
```html
<div class="z-40">Modal</div>        <!-- --z-modal -->
<div class="z-20">Dropdown</div>     <!-- --z-dropdown -->
<div class="z-50">Toast</div>        <!-- --z-toast -->
```

---

## How to Use Tokens

### In Vue Components

**Using Tailwind classes (recommended):**
```vue
<template>
  <div class="p-4 m-2 gap-3 text-lg font-semibold shadow-md z-40">
    Tokenized component
  </div>
</template>
```

**Using CSS variables directly:**
```vue
<template>
  <div :style="{
    padding: 'var(--padding-md)',
    margin: 'var(--margin-sm)',
    fontSize: 'var(--font-size-lg)',
    boxShadow: 'var(--shadow-normal)',
    zIndex: 'var(--z-dropdown)'
  }">
    Component
  </div>
</template>
```

### In SCSS/CSS

```scss
.button {
  padding: var(--padding-md);
  font-size: var(--font-size-sm);
  font-weight: var(--font-weight-semibold);
  box-shadow: var(--shadow-subtle);
  z-index: var(--z-content);
  
  &:hover {
    box-shadow: var(--shadow-normal);
  }
}

.modal {
  z-index: var(--z-modal);
  box-shadow: var(--shadow-floating);
}
```

---

## Dark Mode

All tokens automatically support light and dark modes:

```scss
// Light mode (default)
:root {
  --slate-12: 28 32 36;      // Near black
  --shadow-normal: 0 4px 6px rgb(0 0 0 / 0.1);  // Visible shadow
}

// Dark mode (class="dark")
.dark {
  --slate-12: 237 238 240;   // Near white
  --shadow-normal: 0 4px 6px rgb(0 0 0 / 0.3);  // Stronger shadow
}
```

To enable dark mode for a component:
```html
<html class="dark">
  <!-- All tokens automatically switch -->
</html>
```

---

## File Structure

```
app/javascript/dashboard/assets/scss/
├── _design-tokens.scss          ← Main import file (import this)
├── _next-colors.scss            ← Color tokens (Radix UI)
├── _semantic-color-tokens.scss  ← Semantic color mapping (Intent-based)
├── _spacing-tokens.scss         ← Spacing scale
├── _typography-tokens.scss      ← Typography scale
├── _shadow-tokens.scss          ← Elevation system
├── _z-index-tokens.scss         ← Stacking context
├── _woot.scss                   ← Main stylesheet (imports _design-tokens.scss)
└── app.scss                     ← Entry point
```

---

## Migration Guide

### Converting Hardcoded Values

**Before (hardcoded):**
```scss
.card {
  padding: 16px;
  margin: 8px;
  box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  color: #1C2024;
}
```

**After (tokenized):**
```scss
.card {
  padding: var(--padding-md);
  margin: var(--margin-sm);
  box-shadow: var(--shadow-normal);
  color: rgb(var(--slate-12));
}
```

---

## Token Health Score

Progress: Phase 1 ✅ + Phase 2 ✅ + Phase 3 ✅ Complete

| Domain | Score | Target | Progress |
|--------|-------|--------|----------|
| Colors | 92/100 | 95/100 | ✅ Excellent |
| Spacing | 70/100 | 70/100 | ✅ Complete (Phase 1) |
| Typography | 65/100 | 65/100 | ✅ Complete (Phase 1) |
| Shadows | 70/100 | 70/100 | ✅ Complete (Phase 1) |
| Z-Index | 85/100 | 85/100 | ✅ Complete (Phase 1) |
| Semantic Colors | 95/100 | 95/100 | ✅ Complete (Phase 3) |
| **OVERALL** | **62/100** | **75/100** | 📈 +24 points (Phases 1-3) |

---

## Next Steps (Future Phases)

### Phase 4: Dynamic Color System

- Implement stage.color and label.color variables
- Dynamic theme customization
- Color picker integration

### Phase 5: Design System Maturity

- Export tokens (CSS, JSON, Figma)
- Setup Figma tokens plugin
- Automated violation detection
- Token versioning and changelog
- Automated violation detection

---

## Contributing

When adding new tokens:

1. **Choose the right category** (color, spacing, typography, shadow, z-index)
2. **Follow naming conventions** (`--category-name-size`)
3. **Update light AND dark modes** (if applicable)
4. **Document the token** in this file
5. **Add comment in the token file** explaining use case
6. **Test in both** light and dark modes

---

## Related Files

- Design System Discovery: `discover-design.md` (Phase 1 report)
- Design System Expansion Plan: `design-expansion-plan.md` (Phase overview)
- Tailwind Config: `tailwind.config.js` (integrates tokens)

---

**Version:** 1.0 (Phase 1)  
**Last Updated:** 2026-05-03  
**Status:** Active, expanding to full system
