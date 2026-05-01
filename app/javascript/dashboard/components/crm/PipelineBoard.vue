<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import PipelineColumn from './PipelineColumn.vue';

const store = useStore();
const { t } = useI18n();

const stages = computed(() => store.getters['crmPipeline/getStages']);
const activePipelineId = computed(
  () => store.state.crmPipeline.activePipelineId
);
const isFetchingStages = computed(
  () => store.state.crmPipeline.uiFlags.isFetchingStages
);

onMounted(() => {
  if (activePipelineId.value) {
    store.dispatch('crmPipeline/fetchStages', activePipelineId.value);
  }
});
</script>

<template>
  <div
    class="flex-1 overflow-hidden flex flex-col bg-slate-50 dark:bg-slate-950"
  >
    <!-- Board Body -->
    <div
      class="flex-1 overflow-x-auto overflow-y-hidden custom-horizontal-scrollbar"
    >
      <div v-if="!isFetchingStages" class="flex h-full p-6 gap-6 min-w-max">
        <PipelineColumn
          v-for="stage in stages"
          :key="stage.id"
          :stage="stage"
        />

        <!-- Add Stage Placeholder -->
        <div class="w-[320px] flex-shrink-0 flex items-start pt-4">
          <button
            class="w-full py-4 border-2 border-dashed border-slate-200 dark:border-slate-800 rounded-2xl flex items-center justify-center gap-2 text-slate-400 hover:text-blue-500 hover:border-blue-500/50 hover:bg-blue-50/50 dark:hover:bg-blue-900/10 transition-all group"
          >
            <span class="i-lucide-plus-circle text-lg" />
            <span class="text-sm font-semibold italic">{{
              t('CRM.ADD_STAGE')
            }}</span>
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-else class="flex h-full p-6 gap-6">
        <div
          v-for="i in 4"
          :key="i"
          class="w-[320px] h-full bg-slate-100/50 dark:bg-slate-900/50 rounded-2xl animate-pulse"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-horizontal-scrollbar::-webkit-scrollbar {
  height: 8px;
}
.custom-horizontal-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: #e2e8f0;
  border: 4px solid #f8fafc;
  border-radius: 9999px;
}
.custom-horizontal-scrollbar:hover::-webkit-scrollbar-thumb {
  background: #cbd5e1;
}

:global(.dark) .custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: #1e293b;
  border-color: #0f172a;
}

:global(.dark) .custom-horizontal-scrollbar:hover::-webkit-scrollbar-thumb {
  background: #334155;
}

/* Ensure the board fills the screen correctly without double scrollbars */
:deep(.draggable-container) {
  height: 100%;
}
</style>
