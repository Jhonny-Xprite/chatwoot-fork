<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div class="flex-1 p-6 bg-n-surface-1">
    <div class="max-w-6xl mx-auto">
      <div class="mb-8">
        <h2 class="text-2xl font-bold text-n-slate-12">
          {{ t('CRM.DASHBOARD.TITLE') }}
        </h2>
        <p class="text-n-slate-11">
          {{ t('CRM.DASHBOARD.SUBTITLE') }}
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div
          v-for="index in 3"
          :key="index"
          class="p-6 bg-white dark:bg-n-slate-1 border border-n-weak rounded-2xl shadow-sm"
        >
          <div class="text-n-slate-10 text-sm font-medium mb-1">
            {{ t('CRM.DASHBOARD.METRIC_LABEL', { index }) }}
          </div>
          <div class="text-3xl font-black text-n-slate-12">
            {{ t('CRM.DASHBOARD.METRIC_VALUE') }}
          </div>
        </div>
      </div>

      <div
        class="p-8 border-2 border-dashed border-n-weak rounded-3xl flex flex-col items-center justify-center text-center"
      >
        <div
          class="w-16 h-16 bg-n-alpha-2 rounded-full flex items-center justify-center mb-4"
        >
          <span class="i-lucide-bar-chart-3 text-3xl text-n-slate-10" />
        </div>
        <h3 class="text-lg font-bold text-n-slate-12 mb-2">
          {{ t('CRM.DASHBOARD.EMPTY_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 max-w-sm">
          {{ t('CRM.DASHBOARD.EMPTY_SUBTITLE') }}
        </p>
      </div>
    </div>
  </div>
</template>
