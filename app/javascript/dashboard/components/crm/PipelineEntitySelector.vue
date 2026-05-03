<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  pipelineId: {
    type: Number,
    default: null,
  },
  stageId: {
    type: Number,
    default: null,
  },
});

const { t } = useI18n();
const store = useStore();

const pipelines = computed(() => store.getters['crmPipeline/getAllPipelines']);
const stages = computed(() => store.getters['crmPipeline/getStages']);

const currentPipeline = computed(() =>
  pipelines.value.find(p => p.id === props.pipelineId)
);

const currentStage = computed(() =>
  stages.value.find(s => s.id === props.stageId)
);

onMounted(async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  if (props.pipelineId) {
    store.dispatch('crmPipeline/fetchStages', props.pipelineId);
  }
});

watch(
  () => props.pipelineId,
  newId => {
    if (newId) {
      store.dispatch('crmPipeline/fetchStages', newId);
    }
  }
);

const pipelineMenuItems = computed(() => {
  return pipelines.value.map(p => ({
    label: p.name,
    value: p.id,
    action: 'select-pipeline',
    isSelected: p.id === props.pipelineId,
  }));
});

const stageMenuItems = computed(() => {
  return stages.value.map(s => ({
    label: s.name,
    value: s.id,
    action: 'select-stage',
    isSelected: s.id === props.stageId,
    thumbnail: { name: s.name, color: s.color },
  }));
});

const handlePipelineAction = async ({ value }, hide) => {
  await store.dispatch('crmPipeline/fetchStages', value);
  hide();
};

const handleStageAction = async ({ value }, hide) => {
  await store.dispatch('crmPipeline/moveConversation', {
    conversationId: props.conversationId,
    toStageId: value,
  });
  hide();
};

const badgeStyle = computed(() => {
  if (currentStage.value) {
    return {
      backgroundColor: `${currentStage.value.color}20`,
      color: currentStage.value.color,
      borderColor: `${currentStage.value.color}40`,
    };
  }
  return {};
});
</script>

<template>
  <div class="flex items-center gap-1">
    <!-- Pipeline Selector (Icon only) -->
    <Popover align="start">
      <ButtonV4
        v-tooltip="
          currentPipeline
            ? `${t('CRM.PIPELINE')}: ${currentPipeline.name}`
            : t('CRM.SELECT_PIPELINE')
        "
        size="xs"
        variant="ghost"
        color="slate"
        icon="i-lucide-box"
        :class="{ 'text-n-brand-primary': pipelineId }"
      />
      <template #content="{ hide }">
        <DropdownMenu
          :menu-items="pipelineMenuItems"
          show-search
          class="w-48 mt-2"
          @action="handlePipelineAction($event, hide)"
        />
      </template>
    </Popover>

    <!-- Stage Selector (Badge) -->
    <Popover v-if="pipelineId" align="start">
      <button
        v-if="stageId && currentStage"
        class="flex items-center gap-1.5 px-2 py-0.5 rounded-full border text-[10px] font-bold transition-all hover:brightness-95 active:scale-95 whitespace-nowrap"
        :style="badgeStyle"
      >
        <span class="w-1.5 h-1.5 rounded-full" : />
        {{ currentStage.name }}
        <i class="i-lucide-chevron-down size-3 opacity-70" />
      </button>

      <button
        v-else
        class="text-[10px] font-medium text-n-slate-11 hover:text-n-brand-primary transition-colors px-1 h-6 flex items-center"
      >
        {{ t('CRM.SELECT_STAGE') }}
        <i class="i-lucide-chevron-down size-3 ml-1 opacity-50" />
      </button>

      <template #content="{ hide }">
        <DropdownMenu
          :menu-items="stageMenuItems"
          class="w-48 mt-2"
          @action="handleStageAction($event, hide)"
        >
          <template #thumbnail="{ item }">
            <div class="size-2 rounded-full" : />
          </template>
        </DropdownMenu>
      </template>
    </Popover>
  </div>
</template>
