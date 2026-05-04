import { ref } from 'vue';

/**
 * Debounce dragover events to prevent excessive handler calls
 * Drag generates ~100 dragover events/sec, debounce to ~10 calls/sec
 */
export const useDebouncedDragover = (handler, delayMs = 100) => {
  let timeoutId = null;
  const isDebouncing = ref(false);

  const debouncedHandler = event => {
    isDebouncing.value = true;

    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => {
      handler(event);
      isDebouncing.value = false;
    }, delayMs);
  };

  const cancel = () => {
    clearTimeout(timeoutId);
    isDebouncing.value = false;
  };

  return {
    debouncedHandler,
    cancel,
    isDebouncing,
  };
};
