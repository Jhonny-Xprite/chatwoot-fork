<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { debounce } from '@chatwoot/utils';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const vuexStore = useStore();

const searchQuery = ref(vuexStore.getters['crmPipeline/appliedFilters'].q);
const selectedAssigneeId = ref(
  vuexStore.getters['crmPipeline/appliedFilters'].assigneeId || ''
);
const selectedLabels = ref([
  ...vuexStore.getters['crmPipeline/appliedFilters'].labels,
]);

const agents = computed(() => vuexStore.getters['agents/getAgents']);
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
    class="flex items-center gap-4 py-2 px-4 bg-white dark:bg-n-slate-1 border-b border-n-weak"
  >
    <!-- Search -->
    <div class="relative min-w-[200px]">
      <i
        class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-n-slate-10"
      />
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="$t('CRM.SEARCH_PLACEHOLDER')"
        class="w-full pl-9 pr-3 py-1.5 bg-n-slate-2 border border-n-weak rounded-lg text-sm text-n-slate-12 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/20 transition-all"
      />
    </div>

    <!-- Assignee Filter -->
    <div class="flex items-center gap-2 min-w-fit">
      <span
        class="text-xs font-medium text-n-slate-11 uppercase tracking-wider"
      >
        {{ $t('CRM.ASSIGNEE') }}
      </span>
      <select
        v-model="selectedAssigneeId"
        class="bg-n-slate-2 border border-n-weak rounded-lg px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand transition-all cursor-pointer"
      >
        <option value="">{{ $t('CRM.ALL_ASSIGNEES') }}</option>
        <option v-for="agent in agents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
    </div>

    <!-- Labels Filter -->
    <div class="flex items-center gap-2 min-w-fit">
      <span
        class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider"
      >
        {{ $t('CRM.LABELS') }}
      </span>
      <TagInput
        v-model="selectedLabels"
        :menu-items="labelMenuItems"
        :placeholder="$t('CRM.LABELS_PLACEHOLDER')"
        show-dropdown
        class="w-64 rounded-lg border border-n-weak bg-n-slate-2 px-3 py-1.5 focus-within:border-n-brand focus-within:ring-1 focus-within:ring-n-brand/20 transition-all shadow-sm"
      />
    </div>

    <!-- Clear Filters -->
    <button
      v-if="searchQuery || selectedAssigneeId || selectedLabels.length"
      class="text-xs text-n-brand font-medium hover:underline flex items-center gap-1 ml-auto whitespace-nowrap"
      @click="clearFilters"
    >
      <i class="i-lucide-x w-3 h-3" />
      {{ $t('CRM.CLEAR_FILTERS') }}
    </button>
  </div>
</template>
