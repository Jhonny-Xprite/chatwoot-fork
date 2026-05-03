<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import DealCard from './DealCard.vue';
import DealCardSkeleton from './DealCardSkeleton.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
});

defineEmits(['select', 'selectContact']);

const store = useStore();
const { t } = useI18n();

const conversations = computed({
  get: () =>
    store.getters['crmPipeline/getConversationsByStage'](props.stage.id),
  set: value => {
    store.commit('crmPipeline/REORDER_CONVERSATIONS', {
      stageId: props.stage.id,
      conversations: value,
    });
  },
});

const stageCount = computed(() => {
  const meta = store.getters['crmPipeline/getMetaByStage'](props.stage.id);
  return meta.total_count || conversations.value.length;
});

const isLoading = computed(() =>
  store.getters['crmPipeline/isStageLoading'](props.stage.id)
);

const dragOptions = computed(() => ({
  animation: 300,
  group: 'conversations',
  disabled: false,
  ghostClass: 'sortable-ghost',
  dragClass: 'sortable-drag',
  chosenClass: 'sortable-chosen',
  fallbackOnBody: true,
  forceFallback: true,
  invertSwap: true,
  emptyInsertThreshold: 120,
  scrollSensitivity: 100,
  scrollSpeed: 20,
  swapThreshold: 0.65,
}));

const onDragChange = event => {
  if (event.added) {
    const { element } = event.added;
    store.dispatch('crmPipeline/moveConversation', {
      conversationId: element.id,
      fromStageId: element.pipeline_stage_id,
      toStageId: props.stage.id,
    });
  }
};
</script>

<template>
  <div
    class="flex flex-col w-[320px] h-full bg-n-alpha-1 dark:bg-n-slate-1/50 rounded-2xl border border-n-slate-3 dark:border-n-slate-2 flex-shrink-0"
  >
    <!-- Column Header -->
    <div
      class="p-4 flex items-center justify-between border-b border-n-slate-3 dark:border-n-slate-2 bg-n-alpha-2 rounded-t-2xl"
    >
      <div class="flex items-center gap-2 overflow-hidden">
        <div
          class="w-2 h-6 rounded-full"
          :style="{ backgroundColor: stage.color || 'var(--n-slate-4)' }"
        />
        <h3 class="text-sm font-bold text-n-slate-12 truncate">
          {{ stage.name }}
        </h3>
        <span
          class="px-2 py-0.5 rounded-full bg-n-slate-3 text-[10px] font-bold text-n-slate-11"
        >
          {{ stageCount }}
        </span>
      </div>
      <div
        class="drag-handle flex-shrink-0 cursor-grab active:cursor-grabbing p-1 text-slate-400 hover:text-slate-600"
      >
        <i class="i-woot-drag text-lg" />
      </div>
    </div>

    <!-- Draggable Area -->
    <div class="flex-1 min-h-0 relative">
      <draggable
        v-model="conversations"
        v-bind="dragOptions"
        class="h-full overflow-y-auto overflow-x-hidden p-3 flex flex-col gap-2 custom-scrollbar"
        item-key="id"
        @change="onDragChange"
      >
        <template #item="{ element }">
          <DealCard
            :conversation="element"
            @select="$emit('select', $event)"
            @select-contact="$emit('selectContact', $event)"
          />
        </template>
      </draggable>

      <!-- Empty State -->
      <div
        v-if="!conversations.length && !isLoading"
        class="absolute inset-0 flex flex-col items-center justify-center p-6 text-center pointer-events-none opacity-40"
      >
        <div
          class="w-12 h-12 rounded-full bg-n-slate-2 dark:bg-n-slate-3 flex items-center justify-center mb-2"
        >
          <span class="i-lucide-layout-list text-xl text-n-slate-10" />
        </div>
        <p class="text-[11px] font-medium text-n-slate-10">
          {{ t('CRM.NO_LEADS_HERE') }}
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="p-3 flex flex-col gap-2">
        <DealCardSkeleton v-for="i in 3" :key="i" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-4);
  border-radius: 9999px;
}
.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-6);
}

.sortable-ghost {
  background: var(--n-alpha-1) !important;
  border: 2px dashed var(--n-brand-primary) !important;
  opacity: 0.4;
  transform: scale(0.96);
  transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1);
  box-shadow: none !important;
}

.sortable-drag {
  z-index: 9999 !important;
  transform: rotate(2deg) scale(1.04) !important;
  box-shadow:
    0 20px 25px -5px rgba(39, 129, 246, 0.2),
    0 10px 10px -5px rgba(39, 129, 246, 0.1) !important;
  cursor: grabbing !important;
  opacity: 1 !important;
  pointer-events: none;
}

.sortable-chosen {
  background: var(--n-alpha-2) !important;
  border-color: var(--n-brand-primary) !important;
}

:global(.dark) .custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
}

:global(.dark) .custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-5);
}
</style>
