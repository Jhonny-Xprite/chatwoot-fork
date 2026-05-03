<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const store = useStore();
const { t } = useI18n();

const viewPrefs = computed(() => store.getters['crmPipeline/viewPreferences']);
const allAttributes = computed(() => store.getters['attributes/getAttributes']);

const selectedAttributes = computed({
  get: () => {
    return (viewPrefs.value.customAttributes || []).map(attr => {
      const found = allAttributes.value.find(
        a => a.attribute_key === attr.key && a.attribute_model === attr.model
      );
      return found ? found.attribute_display_name : attr.key;
    });
  },
  set: () => {},
});

const availableAttributeMenuItems = computed(() => {
  return allAttributes.value
    .filter(
      attr =>
        !viewPrefs.value.customAttributes.some(
          a => a.key === attr.attribute_key && a.model === attr.attribute_model
        )
    )
    .map(attr => ({
      label: attr.attribute_display_name,
      value: `${attr.attribute_model}:${attr.attribute_key}`,
      action: 'add',
    }));
});

onMounted(() => {
  store.dispatch('attributes/get');
});

const updatePref = (key, value) => {
  store.commit('crmPipeline/UPDATE_VIEW_PREFERENCES', { [key]: value });
};

const togglePref = key => {
  updatePref(key, !viewPrefs.value[key]);
};

const addAttribute = ({ value }) => {
  const [model, key] = value.split(':');
  const current = [...(viewPrefs.value.customAttributes || [])];
  if (!current.some(a => a.key === key && a.model === model)) {
    current.push({ key, model });
    updatePref('customAttributes', current);
  }
};

const removeAttribute = index => {
  const current = [...(viewPrefs.value.customAttributes || [])];
  current.splice(index, 1);
  updatePref('customAttributes', current);
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
    class="custom-scrollbar max-h-[80vh] w-80 overflow-y-auto rounded-xl border border-n-weak bg-white p-2 shadow-xl dark:bg-n-slate-1"
  >
    <div class="mb-2 border-b border-n-slate-2 px-3 py-2">
      <h3 class="text-xs font-bold uppercase tracking-wider text-n-slate-11">
        {{ t('CRM.SETTINGS.VIEW_OPTIONS') }}
      </h3>
    </div>

    <!-- Density Toggle -->
    <div class="px-2 mb-4">
      <div class="mb-2 px-1 text-[10px] font-bold uppercase text-n-slate-10">
        {{ t('CRM.SETTINGS.DENSITY') }}
      </div>
      <div class="flex gap-1 rounded-lg bg-n-alpha-1 p-1">
        <button
          v-for="option in densityOptions"
          :key="option.value"
          class="flex flex-1 items-center justify-center gap-1.5 rounded-md py-1.5 text-xs font-medium transition-all"
          :class="
            viewPrefs.density === option.value
              ? 'bg-n-white text-n-brand-primary shadow-sm dark:bg-n-slate-2'
              : 'text-n-slate-11 hover:bg-n-alpha-1 hover:text-n-slate-12'
          "
          @click="updatePref('density', option.value)"
        >
          <span :class="option.icon" class="text-sm" />
          {{ option.label }}
        </button>
      </div>
    </div>

    <!-- Field Toggles -->
    <div class="mb-4 space-y-1">
      <div class="mb-2 px-3 text-[10px] font-bold uppercase text-n-slate-10">
        {{ t('CRM.SETTINGS.VISIBLE_FIELDS') }}
      </div>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
        @click="togglePref('showContactsColumn')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-users text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_CONTACTS_COLUMN') }}
          </span>
        </div>
        <div
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="
            viewPrefs.showContactsColumn ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showContactsColumn }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="viewPrefs.showLabels ? 'bg-n-brand-primary' : 'bg-n-slate-3'"
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showLabels }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="viewPrefs.showSla ? 'bg-n-brand-primary' : 'bg-n-slate-3'"
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showSla }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="
            viewPrefs.showPriority ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showPriority }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="
            viewPrefs.showLastMessage ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showLastMessage }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="
            viewPrefs.showAssignee ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showAssignee }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
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
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="
            viewPrefs.showCompanyName ? 'bg-n-brand-primary' : 'bg-n-slate-3'
          "
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showCompanyName }"
          />
        </div>
      </button>

      <button
        class="group flex w-full items-center justify-between rounded-lg px-3 py-2 transition-colors hover:bg-n-alpha-1"
        @click="togglePref('showChannel')"
      >
        <div class="flex items-center gap-2">
          <span
            class="i-lucide-hash text-n-slate-10 group-hover:text-n-brand-primary"
          />
          <span class="text-xs font-medium text-n-slate-12">
            {{ t('CRM.SETTINGS.FIELD_CHANNEL') }}
          </span>
        </div>
        <div
          class="relative h-4 w-8 rounded-full transition-colors"
          :class="viewPrefs.showChannel ? 'bg-n-brand-primary' : 'bg-n-slate-3'"
        >
          <div
            class="absolute left-0.5 top-0.5 h-3 w-3 rounded-full bg-n-white shadow-sm transition-transform"
            :class="{ 'translate-x-4': viewPrefs.showChannel }"
          />
        </div>
      </button>
    </div>

    <!-- Dynamic Attributes -->
    <div class="px-2">
      <div class="mb-2 px-1 text-[10px] font-bold uppercase text-n-slate-10">
        {{ t('CRM.SETTINGS.CUSTOM_ATTRIBUTES') }}
      </div>
      <div class="rounded-xl border border-n-weak/50 bg-n-alpha-1 p-2">
        <TagInput
          v-model="selectedAttributes"
          :menu-items="availableAttributeMenuItems"
          placeholder="Adicionar campo..."
          show-dropdown
          auto-open-dropdown
          @add="addAttribute"
          @remove="removeAttribute"
        />
        <p class="mt-2 px-1 text-[10px] italic text-n-slate-11">
          {{ t('CRM.SETTINGS.CUSTOM_ATTRIBUTES_HELP') }}
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
  border-radius: 4px;
}
</style>
