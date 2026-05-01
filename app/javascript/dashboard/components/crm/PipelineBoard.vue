<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import PipelineColumn from './PipelineColumn.vue';

defineProps({
  stages: {
    type: Array,
    default: () => [],
  },
});

defineEmits(['select', 'selectContact']);

const store = useStore();
const isFetchingStages = computed(
  () => store.state.crmPipeline.uiFlags.isFetchingStages
);
</script>

<template>
  <div class="flex-1 overflow-hidden flex flex-col bg-n-alpha-1">
    <!-- Board Body -->
    <div
      class="flex-1 overflow-x-auto overflow-y-hidden custom-horizontal-scrollbar"
    >
      <div v-if="!isFetchingStages" class="flex h-full p-6 gap-6 min-w-max">
        <PipelineColumn
          v-for="stage in stages"
          :key="stage.id"
          :stage="stage"
          @select="$emit('select', $event)"
          @select-contact="$emit('selectContact', $event)"
        />
      </div>

      <!-- Loading State -->
      <div v-else class="flex h-full p-6 gap-6">
        <div
          v-for="i in 4"
          :key="i"
          class="w-[320px] h-full bg-n-slate-2 dark:bg-n-slate-3 rounded-2xl animate-pulse"
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
  background: var(--n-slate-3);
  border: 4px solid var(--n-alpha-1);
  border-radius: 9999px;
}
.custom-horizontal-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-4);
}

:global(.dark) .custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-2);
  border-color: var(--n-slate-1);
}

:global(.dark) .custom-horizontal-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
}

/* Ensure the board fills the screen correctly without double scrollbars */
:deep(.draggable-container) {
  height: 100%;
}
</style>
