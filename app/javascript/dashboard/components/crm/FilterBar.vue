<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { debounce } from '@chatwoot/utils';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

const vuexStore = useStore();
const { t } = useI18n();

const searchQuery = ref(vuexStore.getters['crmPipeline/appliedFilters'].q);
const selectedAssigneeId = ref(
  vuexStore.getters['crmPipeline/appliedFilters'].assigneeId || ''
);
const selectedLabels = ref([
  ...vuexStore.getters['crmPipeline/appliedFilters'].labels,
]);

const agents = computed(() => vuexStore.getters['agents/getAgents']);
const assigneeOptions = computed(() => [
  { label: t('CRM.ALL_ASSIGNEES'), value: '' },
  ...agents.value.map(agent => ({
    label: agent.name,
    value: agent.id,
  })),
]);

const labels = computed(() => vuexStore.getters['labels/getLabels']);
const labelMenuItems = computed(() =>
  labels.value.map(label => ({
    action: 'select',
    label: label.title,
    value: label.title,
  }))
);

const updateSearch = debounce(val => {
  vuexStore.dispatch('crmPipeline/setFilter', { key: 'q', value: val });
}, 300);

watch(searchQuery, newVal => {
  updateSearch(newVal);
});

watch(selectedAssigneeId, newVal => {
  vuexStore.dispatch('crmPipeline/setFilter', {
    key: 'assigneeId',
    value: newVal ? Number(newVal) : null,
  });
});

onMounted(() => {
  vuexStore.dispatch('agents/get');
  vuexStore.dispatch('labels/get');
});

watch(
  selectedLabels,
  newVal => {
    vuexStore.dispatch('crmPipeline/setFilter', {
      key: 'labels',
      value: newVal,
    });
  },
  { deep: true }
);

const clearFilters = () => {
  searchQuery.value = '';
  selectedAssigneeId.value = '';
  selectedLabels.value = [];
  vuexStore.dispatch('crmPipeline/clearFilters');
};
</script>

<template>
  <div
    class="flex items-center gap-5 py-3 px-6 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md border-b border-n-slate-3/30 dark:border-n-slate-2/10 shadow-sm"
  >
    <!-- Search -->
    <div class="relative min-w-[240px] group">
      <i
        class="i-lucide-search absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-n-slate-9 group-focus-within:text-n-brand-primary transition-colors"
      />
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="$t('CRM.SEARCH_PLACEHOLDER')"
        class="w-full pl-10 pr-4 py-2 bg-n-slate-2/50 dark:bg-n-slate-2/20 border border-n-slate-3/50 dark:border-n-slate-2/20 rounded-xl text-sm text-n-slate-12 outline-none focus:border-n-brand-primary focus:ring-4 focus:ring-n-brand-primary/10 transition-all placeholder:text-n-slate-9"
      />
    </div>

    <div class="h-6 w-px bg-n-slate-3/30 dark:bg-n-slate-2/20 mx-1" />

    <!-- Assignee Filter -->
    <div class="flex items-center gap-3 min-w-fit">
      <span
        class="text-[10px] font-black text-n-slate-10 uppercase tracking-widest"
      >
        {{ $t('CRM.ASSIGNEE') }}
      </span>
      <FilterSelect
        v-model="selectedAssigneeId"
        :options="assigneeOptions"
        variant="faded"
        class="min-w-[160px] !rounded-xl !bg-n-slate-2/50 !border-n-slate-3/50"
      />
    </div>

    <!-- Labels Filter -->
    <div class="flex items-center gap-3 min-w-fit">
      <span
        class="text-[10px] font-black text-n-slate-10 uppercase tracking-widest"
      >
        {{ $t('CRM.LABELS') }}
      </span>
      <TagInput
        v-model="selectedLabels"
        :menu-items="labelMenuItems"
        :placeholder="$t('CRM.LABELS_PLACEHOLDER')"
        show-dropdown
        class="w-72 rounded-xl border border-n-slate-3/50 dark:border-n-slate-2/20 bg-n-slate-2/50 dark:bg-n-slate-2/20 px-3 py-1.5 focus-within:border-n-brand-primary focus-within:ring-4 focus-within:ring-n-brand-primary/10 transition-all shadow-sm"
      />
    </div>

    <!-- Clear Filters -->
    <button
      v-if="searchQuery || selectedAssigneeId || selectedLabels.length"
      v-tooltip.top="$t('CRM.CLEAR_FILTERS')"
      class="p-2 rounded-xl text-n-ruby-9 hover:bg-n-ruby-9/10 transition-all ml-auto flex items-center justify-center group"
      @click="clearFilters"
    >
      <i
        class="i-lucide-rotate-ccw w-4 h-4 group-active:rotate-180 transition-transform duration-500"
      />
    </button>
  </div>
</template>
