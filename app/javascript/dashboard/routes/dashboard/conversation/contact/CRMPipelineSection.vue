<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

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

const currentStage = computed(() =>
  stages.value.find(s => s.id === currentStageId.value)
);

const isLoading = ref(false);

onMounted(async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  if (currentPipelineId.value) {
    await store.dispatch('crmPipeline/fetchStages', currentPipelineId.value);
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
    thumbnail: { name: s.name, color: s.color },
  }));
});

const handlePipelineAction = async ({ value }, hide) => {
  await store.dispatch('crmPipeline/fetchStages', value);
  hide();
};

const handleStageAction = async ({ value }, hide) => {
  isLoading.value = true;
  try {
    await store.dispatch('crmPipeline/moveConversation', {
      conversationId: props.conversation.id,
      toStageId: value,
    });
  } finally {
    isLoading.value = false;
    hide();
  }
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
  <div
    class="flex flex-col gap-4 p-4 bg-n-alpha-black2 rounded-xl border border-n-weak m-2"
  >
    <!-- Pipeline Selection -->
    <div class="flex flex-col gap-2">
      <div class="flex items-center justify-between">
        <span
          class="text-[10px] font-bold text-n-slate-11 uppercase tracking-widest flex items-center gap-1.5"
        >
          <i class="i-lucide-box size-3" />
          {{ t('CRM.PIPELINE') }}
        </span>
      </div>

      <Popover align="start" class="w-full">
        <button
          class="flex items-center justify-between w-full px-3 py-2 text-sm font-medium transition-all border rounded-xl bg-n-background hover:bg-n-alpha-1 border-n-weak hover:border-n-strong group"
        >
          <span
            class="truncate"
            :class="currentPipeline ? 'text-n-slate-12' : 'text-n-slate-11'"
          >
            {{
              currentPipeline ? currentPipeline.name : t('CRM.SELECT_PIPELINE')
            }}
          </span>
          <i
            class="i-lucide-chevron-down size-4 text-n-slate-10 group-hover:text-n-slate-12 transition-colors"
          />
        </button>
        <template #content="{ hide }">
          <DropdownMenu
            :menu-items="pipelineMenuItems"
            show-search
            class="w-56 mt-2"
            @action="handlePipelineAction($event, hide)"
          />
        </template>
      </Popover>
    </div>

    <!-- Stage Selection -->
    <div v-if="currentPipelineId" class="flex flex-col gap-2">
      <div class="flex items-center justify-between">
        <span
          class="text-[10px] font-bold text-n-slate-11 uppercase tracking-widest flex items-center gap-1.5"
        >
          <i class="i-lucide-layers size-3" />
          {{ t('CRM.STAGE') }}
        </span>
        <Spinner v-if="isLoading" :size="12" />
      </div>

      <Popover align="start" class="w-full">
        <button
          v-if="currentStage"
          class="flex items-center justify-between w-full px-3 py-2 text-sm font-bold transition-all border rounded-xl group"
          :style="badgeStyle"
        >
          <div class="flex items-center gap-2 truncate">
            <span
              class="w-2 h-2 rounded-full"
              :style="{ backgroundColor: currentStage.color }"
            />
            <span class="truncate">{{ currentStage.name }}</span>
          </div>
          <i
            class="i-lucide-chevron-down size-4 opacity-70 group-hover:opacity-100 transition-opacity"
          />
        </button>

        <button
          v-else
          class="flex items-center justify-between w-full px-3 py-2 text-sm font-medium transition-all border rounded-xl bg-n-background hover:bg-n-alpha-1 border-n-weak hover:border-n-strong text-n-slate-11 group"
        >
          {{ t('CRM.SELECT_STAGE') }}
          <i
            class="i-lucide-chevron-down size-4 text-n-slate-10 group-hover:text-n-slate-12 transition-colors"
          />
        </button>

        <template #content="{ hide }">
          <DropdownMenu
            :menu-items="stageMenuItems"
            class="w-56 mt-2"
            @action="handleStageAction($event, hide)"
          >
            <template #thumbnail="{ item }">
              <div
                class="size-2 rounded-full"
                :style="{ backgroundColor: item.thumbnail.color }"
              />
            </template>
          </DropdownMenu>
        </template>
      </Popover>
    </div>

    <div
      v-if="!currentPipelineId"
      class="py-2 px-3 bg-n-blue-7/10 rounded-lg border border-n-blue-7/20"
    >
      <p class="text-[11px] text-n-blue-11 leading-relaxed">
        {{ t('CRM.SIDEBAR_HINT') }}
      </p>
    </div>
  </div>
</template>
