<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DealCard from './DealCard.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
});

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
  animation: 200,
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
    class="flex flex-col w-[320px] h-full bg-slate-50/50 dark:bg-slate-900/30 rounded-2xl border border-slate-200/60 dark:border-slate-800/60 flex-shrink-0"
  >
    <!-- Column Header -->
    <div
      class="p-4 flex items-center justify-between border-b border-slate-200/60 dark:border-slate-800/60 bg-white/50 dark:bg-slate-800/50 rounded-t-2xl"
    >
      <div class="flex items-center gap-2 overflow-hidden">
        <div
          class="w-2 h-6 rounded-full"
          :style="{ backgroundColor: stage.color || '#cbd5e1' }"
        />
        <h3
          class="text-sm font-bold text-slate-800 dark:text-slate-200 truncate"
        >
          {{ stage.name }}
        </h3>
        <span
          class="px-2 py-0.5 rounded-full bg-slate-200/50 dark:bg-slate-700/50 text-[10px] font-bold text-slate-500 dark:text-slate-400"
        >
          {{ stageCount }}
        </span>
      </div>
      <NextButton ghost xs slate icon="i-lucide-grip-vertical" disabled />
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
          <DealCard :conversation="element" />
        </template>
      </draggable>

      <!-- Empty State -->
      <div
        v-if="!conversations.length && !isLoading"
        class="absolute inset-0 flex flex-col items-center justify-center p-6 text-center pointer-events-none opacity-40"
      >
        <div
          class="w-12 h-12 rounded-full bg-slate-100 dark:bg-slate-800 flex items-center justify-center mb-2"
        >
          <span class="i-lucide-layout-list text-xl text-slate-400" />
        </div>
        <p class="text-[11px] font-medium text-slate-400">
          {{ t('CRM.NO_LEADS_HERE') }}
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="p-4 flex flex-col gap-3">
        <div
          v-for="i in 3"
          :key="i"
          class="h-24 bg-white/50 dark:bg-slate-800/50 rounded-xl animate-pulse border border-slate-100 dark:border-slate-700"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 4px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: #cbd5e1;
  border-radius: 9999px;
}
.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: #94a3b8;
}

.sortable-ghost {
  background: rgba(59, 130, 246, 0.12);
  border-color: rgba(59, 130, 246, 0.3);
  opacity: 0.5;
}

.sortable-drag {
  z-index: 1000;
  transform: rotate(2deg) scale(1.05);
  box-shadow:
    0 25px 50px -12px rgba(15, 23, 42, 0.35),
    0 10px 20px -10px rgba(15, 23, 42, 0.25);
}

:global(.dark) .custom-scrollbar::-webkit-scrollbar-thumb {
  background: #475569;
}

:global(.dark) .custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: #64748b;
}
</style>
