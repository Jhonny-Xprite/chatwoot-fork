<script setup>
import { computed, ref } from 'vue';
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

defineEmits(['select', 'selectContact', 'addDeal']);

const store = useStore();
const { t } = useI18n();

const isDragging = ref(false);

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
  animation: 250,
  group: 'conversations',
  disabled: false,
  ghostClass: 'sortable-ghost',
  dragClass: 'sortable-drag',
  chosenClass: 'sortable-chosen',
  fallbackOnBody: true,
  forceFallback: true,
  emptyInsertThreshold: 100,
  scrollSensitivity: 80,
  scrollSpeed: 15,
  swapThreshold: 0.5,
  preventOnFilter: false,
  delayOnTouchOnly: true,
  delay: 0,
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
    class="flex flex-col h-full bg-n-slate-2/40 dark:bg-n-slate-2/10 rounded-3xl border border-n-slate-3 dark:border-n-slate-2/50 min-w-0 w-[340px] flex-shrink-0 overflow-hidden transition-all duration-300 hover:shadow-xl hover:shadow-n-brand-primary/5 hover:border-n-brand-primary/20"
    :class="{ 'ring-2 ring-n-brand-primary/20 shadow-2xl': isDragging }"
  >
    <!-- Stage Color Banner -->
    <div
      class="h-1.5 w-full shrink-0 opacity-80"
      :style="{ backgroundColor: stage.color || 'var(--n-slate-4)' }"
    />

    <!-- Column Header: Floating Glass Style -->
    <div
      class="flex items-center justify-between px-5 py-4 shrink-0 border-b border-n-slate-3/50 dark:border-n-slate-2/30 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md"
    >
      <div class="flex items-center gap-3 min-w-0">
        <h3
          class="text-sm font-black text-n-slate-12 truncate tracking-tight uppercase"
        >
          {{ stage.name }}
        </h3>
        <span
          class="flex h-5 items-center justify-center rounded-full bg-n-slate-2 dark:bg-n-slate-3 px-1.5 text-[10px] font-black text-n-slate-11 ring-1 ring-n-slate-3 dark:ring-n-slate-2"
        >
          {{ stageCount }}
        </span>
      </div>
      <div
        class="column-drag-handle flex-shrink-0 cursor-grab active:cursor-grabbing p-1.5 rounded-lg text-n-slate-8 hover:text-n-brand-primary hover:bg-n-slate-2 dark:hover:bg-n-slate-2/50 transition-all"
      >
        <i class="i-woot-drag text-lg" />
      </div>
    </div>

    <!-- Draggable Area -->
    <div class="flex-1 min-h-0 relative flex flex-col">
      <draggable
        v-model="conversations"
        v-bind="dragOptions"
        class="flex-1 overflow-y-auto p-4 flex flex-col gap-4 custom-scrollbar scroll-smooth"
        :class="{ 'dragging-active': isDragging }"
        item-key="id"
        tag="div"
        @start="isDragging = true"
        @end="isDragging = false"
        @change="onDragChange"
      >
        <template #item="{ element: conversation }">
          <DealCard
            :conversation="conversation"
            :is-dragging="isDragging"
            @select="$emit('select', $event)"
            @select-contact="$emit('selectContact', $event)"
          />
        </template>
      </draggable>

      <!-- Empty State -->
      <div
        v-if="!conversations.length && !isLoading"
        class="absolute inset-0 flex flex-col items-center justify-center p-8 opacity-40 grayscale pointer-events-none"
      >
        <div class="mb-4 rounded-full bg-n-slate-2 p-5 dark:bg-n-slate-3">
          <i class="i-lucide-box text-3xl text-n-slate-8" />
        </div>
        <p
          class="text-center text-[11px] font-black uppercase tracking-widest text-n-slate-9"
        >
          {{ t('CRM.NO_DEALS') }}
        </p>
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="p-3 flex flex-col gap-2">
        <DealCardSkeleton v-for="i in 3" :key="i" />
      </div>
    </div>

    <!-- Column Footer: Quick Add -->
    <div class="p-3 border-t border-n-slate-3/30 dark:border-n-slate-2/20">
      <button
        class="group flex w-full items-center justify-center gap-2 rounded-xl py-2.5 text-[10px] font-black uppercase tracking-widest text-n-slate-9 transition-all hover:bg-n-brand-primary hover:text-white hover:shadow-lg hover:shadow-n-brand-primary/20"
        @click="$emit('addDeal', stage.id)"
      >
        <i
          class="i-lucide-plus text-sm transition-transform group-hover:rotate-90"
        />
        <span>{{ t('CRM.ADD_DEAL') }}</span>
      </button>
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
  box-shadow: var(--shadow-floating) !important;
  cursor: grabbing !important;
  opacity: 1 !important;
  /* CRITICAL: Disable all transitions while dragging to prevent lag */
  transition: none !important;
}

.sortable-chosen {
  background: var(--n-alpha-2) !important;
  border-color: var(--n-brand-primary) !important;
  /* CRITICAL: Ensure the chosen element itself doesn't animate its move during drag */
  transition: none !important;
}

.flip-list-move {
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.no-move {
  transition: transform 0s;
}

:global(.dark) .custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
}

:global(.dark) .custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-5);
}
</style>
