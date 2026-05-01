<script setup>
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
</script>

<template>
  <div class="flex-1 p-6 bg-n-surface-1">
    <div class="max-w-4xl mx-auto">
      <div class="mb-8">
        <h2 class="text-2xl font-bold text-n-slate-12">
          {{ t('CRM.SETTINGS.TITLE') }}
        </h2>
        <p class="text-n-slate-11">
          {{ t('CRM.SETTINGS.SUBTITLE') }}
        </p>
      </div>

      <div class="space-y-6">
        <div
          class="p-6 bg-white dark:bg-n-slate-1 border border-n-weak rounded-2xl shadow-sm"
        >
          <h3 class="text-lg font-bold text-n-slate-12 mb-4">
            {{ t('CRM.SETTINGS.DEFAULT_PIPELINE_TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ t('CRM.SETTINGS.DEFAULT_PIPELINE_DESCRIPTION') }}
          </p>
        </div>

        <div
          class="p-6 bg-white dark:bg-n-slate-1 border border-n-weak rounded-2xl shadow-sm"
        >
          <h3 class="text-lg font-bold text-n-slate-12 mb-4">
            {{ t('CRM.SETTINGS.MANAGEMENT_TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ t('CRM.SETTINGS.MANAGEMENT_DESCRIPTION') }}
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
