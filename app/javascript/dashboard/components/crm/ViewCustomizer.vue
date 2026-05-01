<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';

const store = useStore();
const { t } = useI18n();

const viewPrefs = computed(() => store.getters['crmPipeline/viewPreferences']);

const updatePref = (key, value) => {
  store.commit('crmPipeline/UPDATE_VIEW_PREFERENCES', { [key]: value });
};

const togglePref = key => {
  updatePref(key, !viewPrefs.value[key]);
};

const densityOptions = [
  {
    label: t('CRM.SETTINGS.DENSITY_COMPACT'),
    value: 'compact',
    icon: 'i-lucide-layout-list',
  },
  {
    label: t('CRM.SETTINGS.DENSITY_COMFORTABLE'),
    value: 'comfortable',
    icon: 'i-lucide-layout-grid',
  },
];
</script>

<template>
  <div
    class="w-64 p-2 bg-white dark:bg-n-slate-1 border border-n-weak rounded-xl shadow-xl"
  >
    <div class="px-3 py-2 border-b border-n-slate-2 mb-2">
      <h3 class="text-xs font-bold text-n-slate-11 uppercase tracking-wider">
        {{ t('CRM.SETTINGS.VIEW_OPTIONS') }}
      </h3>
    </div>

    <!-- Density Toggle -->
    <div class="px-2 mb-4">
      <div class="text-[10px] font-bold text-n-slate-10 mb-2 px-1 uppercase">
        {{ t('CRM.SETTINGS.DENSITY') }}
      </div>
      <div class="flex p-1 bg-n-alpha-1 rounded-lg gap-1">
        <button
          v-for="option in densityOptions"
          :key="option.value"
          class="flex-1 flex items-center justify-center gap-1.5 py-1.5 rounded-md text-xs font-medium transition-all"
          :class="
            viewPrefs.density === option.value
              ? 'bg-white dark:bg-n-slate-2 text-n-brand-primary shadow-sm'
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
          @click="updatePref('density', option.value)"
        >
          <span :class="option.icon" class="text-sm" />
          {{ option.label }}
        </button>
      </div>
    </div>

    <!-- Field Toggles -->
    <div class="space-y-1">
      <div class="text-[10px] font-bold text-n-slate-10 mb-2 px-3 uppercase">
        {{ t('CRM.SETTINGS.VISIBLE_FIELDS') }}
      </div>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showLabels')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-tag text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_LABELS') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="viewPrefs.showLabels ? 'bg-n-brand-primary' : 'bg-n-slate-3'"
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showLabels }"
          />
        </div>
      </button>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showSla')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-clock text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_SLA') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="viewPrefs.showSla ? 'bg-n-brand-primary' : 'bg-n-slate-3'"
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showSla }"
          />
        </div>
      </button>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showPriority')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-alert-circle text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_PRIORITY') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="
            viewPrefs.showPriority ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showPriority }"
          />
        </div>
      </button>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showLastMessage')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-message-square text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_LAST_MESSAGE') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="
            viewPrefs.showLastMessage ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showLastMessage }"
          />
        </div>
      </button>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showAssignee')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-user text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_ASSIGNEE') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="
            viewPrefs.showAssignee ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showAssignee }"
          />
        </div>
      </button>

      <button
        class="w-full flex items-center justify-between px-3 py-2 rounded-lg hover:bg-n-alpha-1 transition-colors group"
        @click="togglePref('showCompanyName')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-building text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_COMPANY') }}
          </span>
        </div>
        <div
          class="w-8 h-4 rounded-full relative transition-colors"
          :class="
            viewPrefs.showCompanyName ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute top-0.5 left-0.5 w-3 h-3 bg-white rounded-full transition-transform shadow-sm"
            :class="{ 'translate-x-4': viewPrefs.showCompanyName }"
          />
        </div>
      </button>
    </div>
  </div>
</template>
