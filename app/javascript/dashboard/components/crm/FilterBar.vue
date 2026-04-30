<script setup>
import { ref, watch, computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { debounce } from '@chatwoot/utils';

const vuexStore = useStore();

const searchQuery = ref(vuexStore.getters['crmPipeline/appliedFilters'].q);
const selectedAssigneeId = ref(vuexStore.getters['crmPipeline/appliedFilters'].assigneeId);
const selectedLabels = ref(vuexStore.getters['crmPipeline/appliedFilters'].labels.join(', '));

const agents = computed(() => vuexStore.getters['agents/getAgents']);

const updateSearch = debounce(val => {
  vuexStore.dispatch('crmPipeline/setFilter', { key: 'q', value: val });
}, 300);

watch(searchQuery, (newVal) => {
  updateSearch(newVal);
});

watch(selectedAssigneeId, (newVal) => {
  vuexStore.dispatch('crmPipeline/setFilter', { key: 'assigneeId', value: newVal });
});

onMounted(() => {
  vuexStore.dispatch('agents/get');
  vuexStore.dispatch('labels/get');
});

const onLabelChange = (e) => {
  const labelsList = e.target.value.split(',').map(l => l.trim()).filter(l => l !== '');
  vuexStore.dispatch('crmPipeline/setFilter', { key: 'labels', value: labelsList });
};

const clearFilters = () => {
  searchQuery.value = '';
  selectedAssigneeId.value = null;
  selectedLabels.value = '';
  vuexStore.dispatch('crmPipeline/clearFilters');
};
</script>

<template>
  <div class="flex items-center gap-4 py-2 px-4 bg-white dark:bg-n-slate-1 border-b border-n-weak overflow-x-auto no-scrollbar">
    <!-- Search -->
    <div class="relative min-w-[200px]">
      <i class="i-lucide-search absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-n-slate-10" />
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="$t('CRM.SEARCH_PLACEHOLDER')"
        class="w-full pl-9 pr-3 py-1.5 bg-n-slate-2 border border-n-weak rounded-lg text-sm text-n-slate-12 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/20 transition-all"
      >
    </div>

    <!-- Assignee Filter -->
    <div class="flex items-center gap-2 min-w-fit">
      <span class="text-xs font-medium text-n-slate-11 uppercase tracking-wider">{{ $t('CRM.ASSIGNEE') }}</span>
      <select
        v-model="selectedAssigneeId"
        class="bg-n-slate-2 border border-n-weak rounded-lg px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand transition-all cursor-pointer"
      >
        <option :value="null">{{ $t('CRM.ALL_ASSIGNEES') }}</option>
        <option v-for="agent in agents" :key="agent.id" :value="agent.id">
          {{ agent.name }}
        </option>
      </select>
    </div>

    <!-- Labels Filter -->
    <div class="flex items-center gap-2 min-w-fit">
      <span class="text-xs font-medium text-n-slate-11 uppercase tracking-wider">{{ $t('CRM.LABELS') }}</span>
      <input
        v-model="selectedLabels"
        type="text"
        :placeholder="$t('CRM.LABELS_PLACEHOLDER')"
        class="bg-n-slate-2 border border-n-weak rounded-lg px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand transition-all w-48"
        @change="onLabelChange"
      >
    </div>

    <!-- Clear Filters -->
    <button
      v-if="searchQuery || selectedAssigneeId"
      class="text-xs text-n-brand font-medium hover:underline flex items-center gap-1 ml-auto whitespace-nowrap"
      @click="clearFilters"
    >
      <i class="i-lucide-x w-3 h-3" />
      {{ $t('CRM.CLEAR_FILTERS') }}
    </button>
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar {
  display: none;
}
.no-scrollbar {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
