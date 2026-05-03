// ═══════════════════════════════════════════════════════════════════════════
// COLOR HELPER — Dynamic Color Utilities
// ═══════════════════════════════════════════════════════════════════════════
//
// Provides utilities for handling dynamic colors (label.color, stage.color)
// while maintaining design token system integration and ESLint compliance.
//
// Usage:
//   const bgStyle = getDynamicColorStyle(label.color, 'background');
//   const borderStyle = getDynamicColorStyle(stage.color, 'border');
//
// ═══════════════════════════════════════════════════════════════════════════

// Validates if a color string is a valid hex color
export const isValidHexColor = color => {
  if (!color || typeof color !== 'string') return false;
  return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/.test(color.trim());
};

// Validates if a color string is a valid rgb/rgba color
export const isValidRgbColor = color => {
  if (!color || typeof color !== 'string') return false;
  return /^rgba?\s*\(\s*\d+\s*,\s*\d+\s*,\s*\d+/i.test(color.trim());
};

// Validates if a color string is any valid CSS color
export const isValidCssColor = color => {
  if (!color || typeof color !== 'string') return false;
  const trimmed = color.trim();
  // Check for hex, rgb, rgba, or named colors
  return (
    isValidHexColor(trimmed) ||
    isValidRgbColor(trimmed) ||
    CSS.supports('color', trimmed)
  );
};

// Gets a style object for dynamic color backgrounds
export const getDynamicColorStyle = (color, property = 'backgroundColor') => {
  if (!color || !isValidCssColor(color)) {
    return {};
  }
  return {
    [property]: color,
  };
};

// Gets a background style object for labels/badges
export const getLabelBackgroundStyle = labelColor => {
  return getDynamicColorStyle(labelColor, 'backgroundColor');
};

// Gets a background style object for stage indicators
export const getStageColorStyle = stageColor => {
  return getDynamicColorStyle(stageColor, 'backgroundColor');
};

// Converts hex color to rgb
export const hexToRgb = hex => {
  if (!isValidHexColor(hex)) return null;
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
};

// Converts rgb object to hex
export const rgbToHex = (r, g, b) => {
  return (
    '#' +
    [r, g, b]
      .map(x => {
        const hex = x.toString(16);
        return hex.length === 1 ? '0' + hex : hex;
      })
      .join('')
      .toUpperCase()
  );
};

// Extracts RGB values from rgb/rgba string
export const extractRgbValues = rgbString => {
  if (!isValidRgbColor(rgbString)) return null;
  const matches = rgbString.match(/\d+/g);
  if (!matches || matches.length < 3) return null;
  return {
    r: parseInt(matches[0], 10),
    g: parseInt(matches[1], 10),
    b: parseInt(matches[2], 10),
  };
};

// Gets contrast-appropriate text color (light or dark) for a background color
export const getContrastTextColor = bgColor => {
  const rgb = isValidHexColor(bgColor)
    ? hexToRgb(bgColor)
    : extractRgbValues(bgColor);
  if (!rgb) return 'var(--n-slate-12)'; // Fallback to dark text

  // Calculate luminance
  const luminance = (0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b) / 255;
  // Return light or dark text based on background brightness
  return luminance > 0.5 ? 'var(--n-slate-12)' : 'var(--n-slate-1)';
};

// Applies color variables to CSS for dynamic theming
export const applyDynamicColorVariables = colorMap => {
  const root = document.documentElement;
  Object.entries(colorMap).forEach(([key, value]) => {
    if (isValidCssColor(value)) {
      root.style.setProperty(`--dynamic-${key}`, value);
    }
  });
};

// Removes dynamic color variables from CSS
export const removeDynamicColorVariables = keys => {
  const root = document.documentElement;
  keys.forEach(key => {
    root.style.removeProperty(`--dynamic-${key}`);
  });
};

export default {
  isValidHexColor,
  isValidRgbColor,
  isValidCssColor,
  getDynamicColorStyle,
  getLabelBackgroundStyle,
  getStageColorStyle,
  hexToRgb,
  rgbToHex,
  getContrastTextColor,
  extractRgbValues,
  applyDynamicColorVariables,
  removeDynamicColorVariables,
};
