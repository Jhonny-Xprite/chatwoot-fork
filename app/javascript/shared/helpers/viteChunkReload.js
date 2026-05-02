const CHUNK_RELOAD_KEY = 'cw-vite-chunk-reload';
const CHUNK_ERROR_PATTERNS = [
  'Failed to fetch dynamically imported module',
  'Importing a module script failed',
  'Unable to preload CSS',
];

const getErrorMessage = error => error?.message || error?.toString?.() || '';

const isChunkLoadError = error =>
  CHUNK_ERROR_PATTERNS.some(pattern =>
    getErrorMessage(error).includes(pattern)
  );

export const installViteChunkReload = router => {
  sessionStorage.removeItem(CHUNK_RELOAD_KEY);

  const reloadOnce = error => {
    if (!isChunkLoadError(error)) {
      return;
    }

    if (sessionStorage.getItem(CHUNK_RELOAD_KEY)) {
      sessionStorage.removeItem(CHUNK_RELOAD_KEY);
      return;
    }

    sessionStorage.setItem(CHUNK_RELOAD_KEY, '1');
    window.location.reload();
  };

  router.onError(reloadOnce);
  window.addEventListener('vite:preloadError', event => {
    reloadOnce(event?.payload || event?.error || event);
  });
};
