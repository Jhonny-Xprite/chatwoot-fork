// ═══════════════════════════════════════════════════════════════════════════
// useColorStyle — Vue Composable for Dynamic Color Styling
// ═══════════════════════════════════════════════════════════════════════════
//
// Provides computed properties for dynamic color styles in Vue components.
// Ensures ESLint compliance by returning computed properties instead of
// static inline styles.
//
// Usage in components:
//   import { useColorStyle } from 'dashboard/composables/useColorStyle';
//   const { getLabelStyle, getStageStyle } = useColorStyle();
//   const bgStyle = computed(() => getLabelStyle(props.label.color));
//
// In template:
//   <div :style="bgStyle"></div>
//
// ═══════════════════════════════════════════════════════════════════════════

import { computed } from 'vue';
import {
  isValidCssColor,
  getLabelBackgroundStyle,
  getStageColorStyle,
  getContrastTextColor,
} from 'dashboard/helpers/colorHelper';

export const useColorStyle = () => {
  // Returns a computed style object for a label color
  const getLabelStyle = labelColor =>
    computed(() => {
      if (!labelColor || !isValidCssColor(labelColor)) {
        return {};
      }
      return getLabelBackgroundStyle(labelColor);
    });

  // Returns a computed style object for a stage color
  const getStageStyle = stageColor =>
    computed(() => {
      if (!stageColor || !isValidCssColor(stageColor)) {
        return {};
      }
      return getStageColorStyle(stageColor);
    });

  // Returns computed style objects for label (background + text contrast)
  const getLabelStyleWithText = labelColor => {
    const bgStyle = getLabelStyle(labelColor);
    const textColor = computed(() => getContrastTextColor(labelColor || ''));

    return computed(() => ({
      ...bgStyle.value,
      color: textColor.value,
    }));
  };

  // Returns computed style objects for stage (background only)
  const getStageStyleWithBorder = stageColor => {
    const bgStyle = getStageStyle(stageColor);

    return computed(() => ({
      ...bgStyle.value,
      borderColor: stageColor || 'var(--n-slate-4)',
    }));
  };

  // Helper to create inline color dot style (for indicators)
  const getColorDotStyle = color =>
    computed(() => {
      if (!color || !isValidCssColor(color)) {
        return { backgroundColor: 'var(--n-slate-4)' };
      }
      return { backgroundColor: color };
    });

  return {
    getLabelStyle,
    getStageStyle,
    getLabelStyleWithText,
    getStageStyleWithBorder,
    getColorDotStyle,
  };
};

export default useColorStyle;
