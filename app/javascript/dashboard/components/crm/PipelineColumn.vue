<script setup>
import { computed, ref, onMounted } from 'vue';
import draggable from 'vuedraggable';
import DealCard from './DealCard.vue';
import DealCardSkeleton from './DealCardSkeleton.vue';
import { useStore } from 'vuex';

const props = defineProps({
  stage: {
    type: Object,
    required: true,
  },
});

defineEmits(['select']);

const store = useStore();
const scrollContainer = ref(null);

const conversations = computed(() =>
  store.getters['crmPipeline/getConversationsByStage'](props.stage.id)
);
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
    class="flex flex-col flex-shrink-0 w-80 bg-n-slate-2 rounded-xl p-2 max-h-full"
  >
    <div class="flex items-center justify-between px-2 py-3 mb-2">
      <div class="flex items-center gap-2">
        <h2 class="text-sm font-semibold text-n-slate-12">
          {{ stage.name }}
        </h2>
        <span
          class="px-2 py-0.5 text-[10px] bg-n-slate-3 text-n-slate-11 rounded-full font-bold"
        >
          {{ totalCount }}
        </span>
      </div>
      <button
        class="p-1 hover:bg-n-slate-4 rounded-md transition-colors text-n-slate-11"
      >
        <i class="i-lucide-more-horizontal w-4 h-4" />
      </button>
    </div>

    <div
      ref="scrollContainer"
      class="flex-1 overflow-y-auto px-1 custom-scrollbar"
      @scroll="handleScroll"
    >
      <draggable
        :list="conversations"
        group="conversations"
        item-key="id"
        class="min-h-[10px]"
        ghost-class="opacity-50"
        drag-class="rotate-3"
        @change="onDragChange"
      >
        <template #item="{ element }">
          <DealCard :conversation="element" @select="$emit('select', $event)" />
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
