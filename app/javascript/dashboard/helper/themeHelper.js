import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = (isOSOnDarkMode, colorScheme) => {
  const selectedColorScheme =
    colorScheme || LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'auto';

  // Apply Apple Theme
  if (selectedColorScheme === 'apple') {
    document.body.classList.add('apple');
  } else {
    document.body.classList.remove('apple');
  }

  // Apply Linear Theme
  if (selectedColorScheme === 'linear') {
    document.body.classList.add('linear');
  } else {
    document.body.classList.remove('linear');
  }

  if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
  } else {
    document.body.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
  }
};
