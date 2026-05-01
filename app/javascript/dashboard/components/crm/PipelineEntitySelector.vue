<script setup>
import { computed, onMounted, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const pipelines = computed(() => store.getters['crmPipeline/getAllPipelines']);
const stages = computed(() => store.getters['crmPipeline/getStages']);

const currentPipelineId = computed(() => props.conversation.pipeline_id);
const currentStageId = computed(() => props.conversation.pipeline_stage_id);

const currentPipeline = computed(() =>
  pipelines.value.find(p => p.id === currentPipelineId.value)
);

const currentStage = computed(() => {
  return stages.value.find(s => s.id === currentStageId.value);
});

onMounted(async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  if (currentPipelineId.value) {
    store.dispatch('crmPipeline/fetchStages', currentPipelineId.value);
  }
});

watch(currentPipelineId, newId => {
  if (newId) {
    store.dispatch('crmPipeline/fetchStages', newId);
  }
});

const pipelineMenuItems = computed(() => {
  return pipelines.value.map(p => ({
    label: p.name,
    value: p.id,
    action: 'select-pipeline',
    isSelected: p.id === currentPipelineId.value,
  }));
});

const stageMenuItems = computed(() => {
  return stages.value.map(s => ({
    label: s.name,
    value: s.id,
    action: 'select-stage',
    isSelected: s.id === currentStageId.value,
    color: s.color,
  }));
});

const handlePipelineAction = async ({ value }, hide) => {
  await store.dispatch('crmPipeline/fetchStages', value);
  hide();
};

const handleStageAction = async ({ value }, hide) => {
  await store.dispatch('crmPipeline/moveConversation', {
    conversationId: props.conversation.id,
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
  <div class="flex items-center gap-1 ml-2 mr-1">
    <div class="relative flex items-center">
      <!-- Pipeline Dropdown -->
      <Popover align="start">
        <ButtonV4
          v-tooltip="
            currentPipeline
              ? `${t('CRM.PIPELINE')}: ${currentPipeline.name}`
              : t('CRM.ADD_TO_PIPELINE')
          "
          size="xs"
          variant="ghost"
          color="slate"
          icon="i-lucide-box"
          :class="{ 'text-n-brand-primary': currentPipelineId }"
        />
        <template #content="{ hide }">
          <DropdownMenu
            :menu-items="pipelineMenuItems"
            @action="handlePipelineAction($event, hide)"
          />
        </template>
      </Popover>

      <!-- Stage Badge/Dropdown -->
      <Popover v-if="currentPipelineId" align="start">
        <button
          v-if="currentStageId && currentStage"
          class="flex items-center gap-1.5 px-2 py-0.5 rounded-full border text-[10px] font-bold transition-all hover:brightness-95 active:scale-95 whitespace-nowrap"
          :style="badgeStyle"
        >
          <span
            class="w-1.5 h-1.5 rounded-full"
            :style="{ backgroundColor: currentStage.color }"
          />
          {{ currentStage.name }}
          <i class="i-lucide-chevron-down size-3 opacity-70" />
        </button>

        <button
          v-else
          class="text-[10px] font-medium text-n-slate-11 hover:text-n-brand-primary transition-colors px-1"
        >
          {{ t('CRM.SELECT_STAGE') }}
        </button>

        <template #content="{ hide }">
          <DropdownMenu
            :menu-items="stageMenuItems"
            @action="handleStageAction($event, hide)"
          />
        </template>
      </Popover>
    </div>
  </div>
</template>
