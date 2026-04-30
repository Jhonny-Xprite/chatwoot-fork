/* eslint-disable no-alert */
<script setup>
import { computed, ref, onMounted } from 'vue';
import draggable from 'vuedraggable';
import DealCard from './DealCard.vue';
import DealCardSkeleton from './DealCardSkeleton.vue';
import { useStore } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
});

defineEmits(['select']);

const store = useStore();
const scrollContainer = ref(null);

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
const isLoading = computed(() =>
  store.getters['crmPipeline/isStageLoading'](props.stage.id)
);
const totalCount = computed(
  () =>
    store.getters['crmPipeline/getMetaByStage'](props.stage.id)?.total_count ??
    props.stage.conversations_count ??
    0
);

const onDragChange = evt => {
  if (evt.added) {
    const { element } = evt.added;
    store.dispatch('crmPipeline/moveConversation', {
      conversationId: element.id,
      fromStageId: element.pipeline_stage_id,
      toStageId: props.stage.id,
    });
  }
};

const handleScroll = e => {
  const { scrollTop, scrollHeight, clientHeight } = e.target;
  if (scrollHeight - scrollTop <= clientHeight + 100) {
    const meta = store.getters['crmPipeline/getMetaByStage'](props.stage.id);
    if (meta && meta.current_page < meta.total_pages) {
      store.dispatch('crmPipeline/fetchConversations', {
        stageId: props.stage.id,
        page: meta.current_page + 1,
      });
    }
  }
};

const renameStage = () => {
  const name = window.prompt('Novo nome da etapa:', props.stage.name);
  if (name && name !== props.stage.name) {
    store.dispatch('crmPipeline/updateStage', {
      stageId: props.stage.id,
      name,
    });
  }
};

const deleteStage = () => {
  if (window.confirm('Tem certeza que deseja excluir esta etapa?')) {
    store.dispatch('crmPipeline/deleteStage', props.stage.id);
  }
};

onMounted(() => {
  if (conversations.value.length === 0) {
    store.dispatch('crmPipeline/fetchConversations', {
      stageId: props.stage.id,
      page: 1,
    });
  }
});
</script>

<template>
  <div
    class="flex flex-col flex-shrink-0 w-80 bg-n-slate-2 rounded-xl p-2 max-h-full transition-all group/column"
  >
    <div class="flex items-center justify-between px-3 py-4 mb-1">
      <div class="flex items-center gap-2.5 min-w-0">
        <h2
          class="text-sm font-bold text-n-slate-12 truncate uppercase tracking-tight"
        >
          {{ stage.name }}
        </h2>
        <div
          class="px-2 py-0.5 text-[10px] bg-n-alpha-2 text-n-slate-11 rounded-md font-bold border border-n-weak"
        >
          {{ totalCount }}
        </div>
      </div>
      
      <Popover @click.stop>
        <template #trigger>
          <button class="p-1 hover:bg-n-alpha-1 rounded-lg transition-colors text-n-slate-10 hover:text-n-slate-12">
            <i class="i-lucide-more-horizontal w-4 h-4" />
          </button>
        </template>
        <template #content>
          <div class="bg-n-solid-1 border border-n-weak rounded-xl shadow-2xl p-1 min-w-[140px] z-50">
            <button 
              class="w-full flex items-center gap-2 px-3 py-2 text-xs font-medium text-n-slate-12 hover:bg-n-alpha-1 rounded-lg transition-colors"
              @click="renameStage"
            >
              <i class="i-lucide-pencil w-3.5 h-3.5" />
              Renomear Etapa
            </button>
            <div class="h-px bg-n-weak my-1" />
            <button 
              class="w-full flex items-center gap-2 px-3 py-2 text-xs font-medium text-n-ruby-9 hover:bg-n-ruby-9/10 rounded-lg transition-colors"
              @click="deleteStage"
            >
              <i class="i-lucide-trash-2 w-3.5 h-3.5" />
              Excluir Etapa
            </button>
          </div>
        </template>
      </Popover>
    </div>

    <div
      ref="scrollContainer"
      class="flex-1 overflow-y-auto px-1 custom-scrollbar"
      @scroll="handleScroll"
    >
      <draggable
        v-model="conversations"
        group="conversations"
        item-key="id"
        class="min-h-[150px] pb-20"
        ghost-class="opacity-40"
        drag-class="rotate-[2deg] scale-105 shadow-xl !z-[9999]"
        :animation="200"
        :delay="0"
        :disabled="false"
        :force-fallback="true"
        :fallback-on-body="true"
        @change="onDragChange"
      >
        <template #item="{ element }">
          <div class="mb-3 last:mb-0">
            <DealCard
              :conversation="element"
              @select="$emit('select', $event)"
            />
          </div>
        </template>
      </draggable>

      <div v-if="isLoading" class="space-y-3">
        <DealCardSkeleton v-for="i in 3" :key="i" />
      </div>
      <div
        v-else-if="!conversations.length"
        class="flex items-center justify-center px-4 py-10 text-center text-sm text-n-slate-10"
      >
        {{ $t('CRM.EMPTY_STAGE') }}
      </div>
    </div>
  </div>
</template>

<style scoped>
.list-complete-enter-active,
.list-complete-leave-active {
  transition: all 0.3s ease;
}

.list-complete-enter-from,
.list-complete-leave-to {
  opacity: 0;
  transform: translateY(10px);
}

.sortable-ghost {
  @apply bg-n-slate-3 border-dashed border-2 border-n-slate-4 shadow-none opacity-40 rounded-xl;
}

.sortable-drag {
  @apply shadow-2xl scale-[1.02] rotate-1 !z-[9999] cursor-grabbing !pointer-events-none;
}
</style>
