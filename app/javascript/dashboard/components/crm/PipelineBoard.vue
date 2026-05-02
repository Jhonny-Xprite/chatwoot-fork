<script setup>
import { computed, ref } from 'vue';
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
const scrollContainer = ref(null);
const isFetchingStages = computed(
  () => store.state.crmPipeline.uiFlags.isFetchingStages
);

const stagesList = computed({
  get: () => props.stages,
  set: value => {
    // ATENÇÃO: MANTER COMO 'stages'. NÃO MUDAR PARA 'positions'.
    store.dispatch('crmPipeline/reorderStages', {
      stages: value,
    });
  },
});

const handleKeyboard = event => {
  if (!scrollContainer.value) return;

  const scrollStep = 320;

  if (event.key === 'ArrowRight') {
    event.preventDefault();
    scrollContainer.value.scrollLeft += scrollStep;
  } else if (event.key === 'ArrowLeft') {
    event.preventDefault();
    scrollContainer.value.scrollLeft -= scrollStep;
  }
};
</script>

<template>
  <div
    class="relative flex flex-col flex-1 overflow-hidden bg-n-alpha-1"
    @keydown="handleKeyboard"
  >
    <!-- Board Body - Onde o scroll horizontal real acontece -->
    <div
      ref="scrollContainer"
      class="custom-horizontal-scrollbar flex-1 overflow-y-hidden overflow-x-auto scroll-smooth"
      tabindex="0"
    >
      <div
        v-if="!isFetchingStages"
        class="flex h-full min-w-max items-start gap-6 p-6"
      >
        <draggable
          v-model="stagesList"
          item-key="id"
          class="flex h-full items-start gap-6"
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
          class="w-[320px] flex-shrink-0 flex items-start pr-6 pt-6"
        >
          <button
            class="group flex w-full items-center justify-center gap-2 rounded-2xl border-2 border-dashed border-n-slate-3 py-4 text-n-slate-10 transition-all hover:border-n-brand-primary/50 hover:bg-n-brand-primary-alpha-1 hover:text-n-brand-primary dark:border-n-slate-2"
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
      <div v-else class="flex h-full gap-6 p-6">
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
