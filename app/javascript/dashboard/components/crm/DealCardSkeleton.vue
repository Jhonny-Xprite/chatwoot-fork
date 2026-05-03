<template>
  <div
    class="p-4 mb-3 bg-n-alpha-3 dark:bg-n-slate-1 border border-n-slate-3 dark:border-n-slate-2 rounded-xl shadow-sm overflow-hidden relative shimmer-container flex flex-col gap-3"
  >
    <div class="flex items-start gap-3">
      <div
        class="w-10 h-10 rounded-full bg-n-slate-3 dark:bg-n-slate-2 flex-shrink-0"
      />
      <div class="flex-1 min-w-0 py-1">
        <div class="h-4 w-3/4 rounded bg-n-slate-3 dark:bg-n-slate-2 mb-2" />
        <div class="h-3 w-1/2 rounded bg-n-slate-3/60 dark:bg-n-slate-2/60" />
      </div>
    </div>
    <div class="h-10 w-full rounded-lg bg-n-slate-2/50 dark:bg-n-slate-2/30" />
    <div class="flex gap-1">
      <div class="h-5 w-12 rounded-md bg-n-slate-3 dark:bg-n-slate-2" />
      <div class="h-5 w-16 rounded-md bg-n-slate-3 dark:bg-n-slate-2" />
    </div>
    <div class="h-px bg-n-slate-2 w-full mt-1" />
    <div class="flex items-center justify-between">
      <div class="h-6 w-24 rounded-lg bg-n-slate-3 dark:bg-n-slate-2" />
      <div class="h-4 w-12 rounded bg-n-slate-3 dark:bg-n-slate-2" />
    </div>

    <!-- Shimmer Overlay -->
    <div class="shimmer-overlay" />
  </div>
</template>

<style scoped>
.shimmer-container {
  /* Ensuring consistent pulse while shimmer runs */
  animation: pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}

.shimmer-overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(var(--white-alpha-tokens), 0.05) 20%,
    rgba(var(--white-alpha-tokens), 0.2) 50%,
    rgba(var(--white-alpha-tokens), 0.05) 80%,
    transparent 100%
  );
  animation: shimmer 1.5s infinite;
  transform: translateX(-100%);
}

:global(.dark) .shimmer-overlay {
  background: linear-gradient(
    90deg,
    transparent 0%,
    rgba(255, 255, 255, 0.01) 20%,
    rgba(255, 255, 255, 0.03) 50%,
    rgba(255, 255, 255, 0.01) 80%,
    transparent 100%
  );
}

@keyframes shimmer {
  100% {
    transform: translateX(100%);
  }
}

@keyframes pulse {
  50% {
    opacity: 0.8;
  }
}
</style>
