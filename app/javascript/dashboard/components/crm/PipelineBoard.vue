<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import PipelineColumn from './PipelineColumn.vue';

const props = defineProps({
  stages: {
    type: Array,
    default: () => [],
  },
});

defineEmits(['select', 'selectContact', 'addStage']);

const store = useStore();
const isFetchingStages = computed(
  () => store.state.crmPipeline.uiFlags.isFetchingStages
);

const stagesList = computed({
  get: () => props.stages,
  set: value => {
    store.dispatch('crmPipeline/reorderStages', {
      stages: value,
    });
  },
});

const boardGridStyle = computed(() => ({
  display: 'grid',
  gridTemplateColumns: 'repeat(auto-fit, minmax(min(100%, 360px), 1fr))',
  gap: '1.5rem',
  padding: '1.5rem',
  height: '100%',
  alignItems: 'start',
}));
</script>

<template>
  <div class="relative flex flex-col flex-1 overflow-hidden bg-n-alpha-1">
    <!-- Board Body - CSS Grid Responsive -->
    <div
      class="flex-1 overflow-y-auto overflow-x-hidden scroll-smooth custom-scrollbar"
    >
      <div v-if="!isFetchingStages" :style="boardGridStyle">
        <draggable
          v-model="stagesList"
          tag="div"
          item-key="id"
          class="stage-draggable"
          handle=".column-drag-handle"
          ghost-class="opacity-50"
          :animation="200"
        >
          <template #item="{ element: stage }">
            <PipelineColumn
              :stage="stage"
              @select="$emit('select', $event)"
              @select-contact="$emit('selectContact', $event)"
            />
          </template>
        </draggable>

        <!-- Add Stage Placeholder -->
        <div
          v-if="!isFetchingStages && stages.length > 0"
          class="flex items-start"
        >
          <button
            class="group w-full flex items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-n-slate-3 py-8 text-n-slate-10 transition-all hover:border-n-brand-primary/50 hover:bg-n-brand-primary-alpha-1 hover:text-n-brand-primary dark:border-n-slate-2"
            @click="$emit('addStage')"
          >
            <span class="i-lucide-plus-circle text-lg" />
            <span class="text-sm font-semibold italic">{{
              $t('CRM.ADD_STAGE')
            }}</span>
          </button>
        </div>
      </div>

      <!-- Loading State -->
      <div v-else :style="boardGridStyle">
        <div
          v-for="i in 4"
          :key="i"
          class="h-full w-[320px] animate-pulse rounded-2xl bg-n-slate-2 dark:bg-n-slate-3"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Make draggable transparent to CSS Grid layout */
.stage-draggable {
  display: contents;
}

/* Estilização agressiva do Scrollbar Horizontal para facilitar a usabilidade */
.custom-horizontal-scrollbar {
  display: flex;
  flex-direction: column;
  overscroll-behavior-x: contain;
}

.custom-horizontal-scrollbar::-webkit-scrollbar {
  height: 12px; /* Aumentado para facilitar o clique */
}
.custom-horizontal-scrollbar::-webkit-scrollbar-track {
  background: var(--n-alpha-1);
  border-radius: 0;
}
.custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-5);
  border: 3px solid var(--n-alpha-1);
  border-radius: 9999px;
  transition: background 0.2s ease;
}
.custom-horizontal-scrollbar::-webkit-scrollbar-thumb:hover {
  background: var(--n-brand-primary);
}

:global(.dark) .custom-horizontal-scrollbar::-webkit-scrollbar-track {
  background: var(--n-slate-1);
}

:global(.dark) .custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
  border-color: var(--n-slate-1);
}

:global(.dark) .custom-horizontal-scrollbar::-webkit-scrollbar-thumb:hover {
  background: var(--n-brand-primary);
}

/* Garante que o container do board ocupe a altura total disponível */
:deep(.draggable-container) {
  height: 100%;
}
</style>
