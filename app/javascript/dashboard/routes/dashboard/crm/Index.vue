<script setup>
import { computed, onMounted } from 'vue';
import { useCrmPipelineStore } from 'dashboard/store/crm/pipeline';
import PipelineBoard from 'dashboard/components/crm/PipelineBoard.vue';
import FilterBar from 'dashboard/components/crm/FilterBar.vue';

const store = useCrmPipelineStore();

const pipelines = computed(() => store.pipelines);
const currentPipelineStages = computed(() => store.stages);
const selectedPipelineId = computed({
  get: () => store.currentPipelineId,
  set: val => {
    store.currentPipelineId = val;
    store.fetchStages(val);
  },
});
const isLoading = computed(() => store.loading);

onMounted(async () => {
  await store.fetchPipelines();
  if (pipelines.value.length > 0 && !store.currentPipelineId) {
    selectedPipelineId.value = pipelines.value[0].id;
  }
});

const onDealSelect = () => {
  // Navigation or detail view
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-h-0 bg-n-surface-1">
    <header
      class="flex items-center justify-between p-4 border-b border-n-weak bg-white dark:bg-n-slate-1"
    >
      <div class="flex items-center gap-4">
        <h1 class="text-xl font-bold text-n-slate-12">
          {{ $t('CRM.HEADER') }}
        </h1>

        <!-- Pipeline Selector -->
        <div v-if="pipelines.length > 0" class="flex items-center gap-2">
          <select
            v-model="selectedPipelineId"
            class="bg-n-slate-2 border border-n-weak rounded-md px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand transition-all"
          >
            <option v-for="p in pipelines" :key="p.id" :value="p.id">
              {{ p.name }}
            </option>
          </select>
        </div>
      </div>

      <div class="flex items-center gap-2">
        <button
          class="px-4 py-1.5 bg-n-brand text-white rounded-lg text-sm font-semibold hover:bg-n-brand-emphasis transition-all flex items-center gap-2 shadow-sm"
        >
          <i class="i-lucide-plus w-4 h-4" />
          {{ $t('CRM.ADD_DEAL') }}
        </button>
      </div>
    </header>
    <FilterBar />

    <main class="flex-1 min-h-0 flex flex-col overflow-x-auto">
      <PipelineBoard
        v-if="currentPipelineStages.length"
        :stages="currentPipelineStages"
        @select="onDealSelect"
      />
      <div
        v-else-if="isLoading"
        class="flex-1 flex flex-col items-center justify-center space-y-4"
      >
        <div class="flex gap-4">
          <div
            v-for="i in 3"
            :key="i"
            class="w-80 h-96 bg-n-slate-2 rounded-xl animate-pulse"
          />
        </div>
        <p class="text-n-slate-11">{{ $t('CRM.LOADING') }}</p>
      </div>
      <div
        v-else
        class="flex-1 flex flex-col items-center justify-center p-8 text-center"
      >
        <div
          class="w-16 h-16 bg-n-slate-2 rounded-full flex items-center justify-center mb-4 text-n-slate-10 shadow-inner"
        >
          <i class="i-lucide-layout-kanban w-8 h-8" />
        </div>
        <h3 class="text-lg font-semibold text-n-slate-12 mb-1">
          {{ $t('CRM.NO_PIPELINES') }}
        </h3>
        <p class="text-sm text-n-slate-11 max-w-xs">
          {{ $t('CRM.NO_PIPELINES_SUBTITLE') }}
        </p>
      </div>
    </main>
  </div>
</template>
