<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import draggable from 'vuedraggable';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

const store = useStore();
const { t } = useI18n();

const pipelines = computed(() => store.getters['crmPipeline/getAllPipelines']);
const currentStages = computed(() => store.getters['crmPipeline/getStages']);
const activePipeline = computed(
  () => store.getters['crmPipeline/getActivePipeline'] || null
);
const uiFlags = computed(() => store.getters['crmPipeline/uiFlags']);

const selectedPipelineId = ref(null);
const createPipelineName = ref('');
const stageDrafts = ref([]);
const deletePipelineDialogRef = ref(null);
const deleteStageDialogRef = ref(null);
const pendingDeletePipelineId = ref(null);
const pendingDeleteStageId = ref(null);
const isReordering = ref(false);

const newStage = reactive({
  name: '',
  color: '#14B8A6',
  active: true,
});
const pipelineForm = reactive({
  name: '',
  active: true,
  is_default: false,
});

const dragOptions = computed(() => ({
  animation: 200,
  group: 'stages',
  disabled: false,
  ghostClass: 'sortable-ghost',
  dragClass: 'sortable-drag',
}));

const syncPipelineForm = pipeline => {
  pipelineForm.name = pipeline?.name || '';
  pipelineForm.active = pipeline?.active ?? true;
  pipelineForm.is_default = pipeline?.is_default ?? false;
};

onMounted(async () => {
  const pipelineId = await store.dispatch('crmPipeline/fetchPipelines');
  if (pipelineId) {
    selectedPipelineId.value = pipelineId;
    await store.dispatch('crmPipeline/fetchStages', pipelineId);
  }
});

watch(activePipeline, pipeline => {
  syncPipelineForm(pipeline);
});

watch(currentStages, stages => {
  if (!isReordering.value) {
    stageDrafts.value = stages.map(stage => ({ ...stage }));
  }
});

watch(selectedPipelineId, async pipelineId => {
  if (!pipelineId) return;
  await store.dispatch('crmPipeline/fetchStages', Number(pipelineId));
});

const createPipeline = async () => {
  if (!createPipelineName.value.trim()) return;

  const pipelineId = await store.dispatch(
    'crmPipeline/createPipeline',
    createPipelineName.value.trim()
  );
  createPipelineName.value = '';

  if (pipelineId) {
    selectedPipelineId.value = pipelineId;
  }
};

const savePipeline = async () => {
  if (!activePipeline.value) return;

  await store.dispatch('crmPipeline/updatePipeline', {
    pipelineId: activePipeline.value.id,
    pipeline: { ...pipelineForm },
  });
};

const openDeletePipelineDialog = pipelineId => {
  pendingDeletePipelineId.value = pipelineId;
  deletePipelineDialogRef.value?.open();
};

const confirmDeletePipeline = async () => {
  const nextPipelineId = await store.dispatch(
    'crmPipeline/deletePipeline',
    pendingDeletePipelineId.value
  );
  selectedPipelineId.value = nextPipelineId || null;
  pendingDeletePipelineId.value = null;
  deletePipelineDialogRef.value?.close();
};

const createStage = async () => {
  if (!selectedPipelineId.value || !newStage.name.trim()) return;

  await store.dispatch('crmPipeline/createStage', {
    pipelineId: Number(selectedPipelineId.value),
    stage: { ...newStage, name: newStage.name.trim() },
  });

  newStage.name = '';
  newStage.color = '#14B8A6';
  newStage.active = true;
};

const saveStage = async stage => {
  await store.dispatch('crmPipeline/updateStage', {
    pipelineId: Number(selectedPipelineId.value),
    stageId: stage.id,
    stage: {
      name: stage.name,
      color: stage.color,
      active: stage.active,
      position: stage.position,
    },
  });
};

const onDragChange = async () => {
  isReordering.value = true;
  try {
    const updatedStages = stageDrafts.value.map((stage, index) => ({
      ...stage,
      position: index + 1,
    }));

    await store.dispatch('crmPipeline/reorderStages', {
      pipelineId: Number(selectedPipelineId.value),
      stages: updatedStages,
    });
  } finally {
    isReordering.value = false;
  }
};

const openDeleteStageDialog = stageId => {
  pendingDeleteStageId.value = stageId;
  deleteStageDialogRef.value?.open();
};

const confirmDeleteStage = async () => {
  await store.dispatch('crmPipeline/deleteStage', {
    pipelineId: Number(selectedPipelineId.value),
    stageId: pendingDeleteStageId.value,
  });
  pendingDeleteStageId.value = null;
  deleteStageDialogRef.value?.close();
};
</script>

<template>
  <div class="flex-1 p-6 bg-n-surface-1 overflow-auto">
    <div class="max-w-6xl mx-auto space-y-6">
      <div>
        <h2 class="text-2xl font-bold text-n-slate-12">
          {{ t('CRM.SETTINGS.TITLE') }}
        </h2>
        <p class="text-n-slate-11">
          {{ t('CRM.SETTINGS.SUBTITLE') }}
        </p>
      </div>

      <section
        class="p-6 bg-n-alpha-3 dark:bg-n-slate-1 border border-n-slate-3 rounded-2xl shadow-sm space-y-4"
      >
        <div class="flex items-center justify-between gap-4">
          <div>
            <h3 class="text-lg font-bold text-n-slate-12">
              {{ t('CRM.SETTINGS.PIPELINES_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ t('CRM.SETTINGS.PIPELINES_DESCRIPTION') }}
            </p>
          </div>
        </div>

        <div class="flex gap-3">
          <input
            v-model="createPipelineName"
            type="text"
            :placeholder="t('CRM.SETTINGS.NEW_PIPELINE_PLACEHOLDER')"
            class="flex-1 rounded-lg border border-n-slate-3 bg-n-slate-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary"
          />
          <NextButton
            color="blue"
            size="sm"
            icon="i-lucide-plus"
            :label="t('CRM.SETTINGS.CREATE_PIPELINE')"
            @click="createPipeline"
          />
        </div>

        <div
          v-if="pipelines.length"
          class="grid gap-4 lg:grid-cols-[280px_1fr]"
        >
          <div class="space-y-2">
            <button
              v-for="pipeline in pipelines"
              :key="pipeline.id"
              type="button"
              class="w-full rounded-xl border px-4 py-3 text-left transition-all"
              :class="
                selectedPipelineId === pipeline.id
                  ? 'border-n-brand-primary bg-n-brand-primary-alpha-1'
                  : 'border-n-slate-3 bg-n-alpha-2 hover:border-n-brand-primary/40'
              "
              @click="selectedPipelineId = pipeline.id"
            >
              <div class="flex items-center justify-between gap-3">
                <div>
                  <p class="font-semibold text-n-slate-12">
                    {{ pipeline.name }}
                  </p>
                  <p class="text-xs text-n-slate-11">
                    {{
                      pipeline.is_default
                        ? t('CRM.DEFAULT_PIPELINE')
                        : t('CRM.SETTINGS.SECONDARY_PIPELINE')
                    }}
                  </p>
                </div>
                <span
                  class="h-2.5 w-2.5 rounded-full"
                  :class="pipeline.active ? 'bg-n-teal-9' : 'bg-n-slate-6'"
                />
              </div>
            </button>
          </div>

          <div
            v-if="activePipeline"
            class="rounded-2xl border border-n-slate-3 bg-n-alpha-2 p-5 space-y-5"
          >
            <div class="grid gap-4 md:grid-cols-2">
              <label class="space-y-2">
                <span
                  class="text-xs font-semibold uppercase tracking-wide text-n-slate-11"
                >
                  {{ t('CRM.SETTINGS.PIPELINE_NAME') }}
                </span>
                <input
                  v-model="pipelineForm.name"
                  type="text"
                  class="w-full rounded-lg border border-n-slate-3 bg-n-alpha-3 px-3 py-2 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary"
                />
              </label>
              <div class="flex flex-col justify-end gap-2">
                <label class="flex items-center gap-2 text-sm text-n-slate-12">
                  <input v-model="pipelineForm.active" type="checkbox" />
                  {{ t('CRM.SETTINGS.PIPELINE_ACTIVE') }}
                </label>
                <label class="flex items-center gap-2 text-sm text-n-slate-12">
                  <input v-model="pipelineForm.is_default" type="checkbox" />
                  {{ t('CRM.SETTINGS.PIPELINE_DEFAULT') }}
                </label>
              </div>
            </div>

            <div class="flex gap-3">
              <NextButton
                color="blue"
                size="sm"
                icon="i-lucide-save"
                :label="t('CRM.SAVE')"
                @click="savePipeline"
              />
              <NextButton
                variant="outline"
                color="ruby"
                size="sm"
                icon="i-lucide-trash-2"
                :label="t('CRM.SETTINGS.DELETE_PIPELINE')"
                @click="openDeletePipelineDialog(activePipeline.id)"
              />
            </div>

            <div class="space-y-4">
              <div>
                <h4 class="text-base font-bold text-n-slate-12">
                  {{ t('CRM.SETTINGS.STAGES_TITLE') }}
                </h4>
                <p class="text-sm text-n-slate-11">
                  {{ t('CRM.SETTINGS.STAGES_DESCRIPTION') }}
                </p>
              </div>

              <div class="grid gap-3 md:grid-cols-[1.3fr_120px_100px_160px]">
                <input
                  v-model="newStage.name"
                  type="text"
                  :placeholder="t('CRM.SETTINGS.NEW_STAGE_PLACEHOLDER')"
                  class="rounded-lg border border-n-slate-3 bg-n-alpha-3 px-3 py-2 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary"
                />
                <input
                  v-model="newStage.color"
                  type="color"
                  class="h-10 w-full rounded-lg border border-n-slate-3 bg-n-alpha-3 px-2"
                />
                <label
                  class="flex items-center gap-2 rounded-lg border border-n-slate-3 bg-n-alpha-3 px-3 py-2 text-sm text-n-slate-12"
                >
                  <input v-model="newStage.active" type="checkbox" />
                  {{ t('CRM.SETTINGS.ACTIVE') }}
                </label>
                <NextButton
                  color="blue"
                  size="sm"
                  icon="i-lucide-plus"
                  :label="t('CRM.SETTINGS.CREATE_STAGE')"
                  @click="createStage"
                />
              </div>

              <draggable
                v-if="stageDrafts.length"
                v-model="stageDrafts"
                v-bind="dragOptions"
                class="space-y-3"
                item-key="id"
                handle=".drag-handle"
                @change="onDragChange"
              >
                <template #item="{ element: stage }">
                  <div
                    class="grid gap-3 rounded-xl border border-n-slate-3 bg-n-alpha-3 p-4 md:grid-cols-[24px_1.3fr_120px_100px_1fr]"
                  >
                    <div
                      class="drag-handle flex cursor-grab items-center justify-center text-n-slate-8 active:cursor-grabbing hover:text-n-slate-11"
                    >
                      <i class="i-lucide-grip-vertical" />
                    </div>
                    <input
                      v-model="stage.name"
                      type="text"
                      class="rounded-lg border border-n-slate-3 bg-n-slate-1 px-3 py-2 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary"
                    />
                    <input
                      v-model="stage.color"
                      type="color"
                      class="h-10 w-full rounded-lg border border-n-slate-3 bg-n-alpha-3 px-2"
                    />
                    <label
                      class="flex items-center gap-2 rounded-lg border border-n-slate-3 bg-n-slate-1 px-3 py-2 text-sm text-n-slate-12"
                    >
                      <input v-model="stage.active" type="checkbox" />
                      {{ t('CRM.SETTINGS.ACTIVE') }}
                    </label>
                    <div class="flex gap-2">
                      <NextButton
                        color="blue"
                        size="sm"
                        icon="i-lucide-save"
                        :label="t('CRM.SAVE')"
                        @click="saveStage(stage)"
                      />
                      <NextButton
                        variant="outline"
                        color="ruby"
                        size="sm"
                        icon="i-lucide-trash-2"
                        :label="t('CRM.SETTINGS.DELETE_STAGE')"
                        @click="openDeleteStageDialog(stage.id)"
                      />
                    </div>
                  </div>
                </template>
              </draggable>
            </div>
          </div>
        </div>
      </section>

      <div
        v-if="uiFlags.isFetchingPipelines || uiFlags.isFetchingStages"
        class="text-sm text-n-slate-11"
      >
        {{ t('CRM.LOADING') }}
      </div>
    </div>

    <Dialog
      ref="deletePipelineDialogRef"
      type="alert"
      :title="t('CRM.SETTINGS.DELETE_PIPELINE')"
      :description="t('CRM.SETTINGS.DELETE_PIPELINE_CONFIRM')"
      :confirm-button-label="t('CRM.SETTINGS.DELETE_PIPELINE')"
      @confirm="confirmDeletePipeline"
    />

    <Dialog
      ref="deleteStageDialogRef"
      type="alert"
      :title="t('CRM.SETTINGS.DELETE_STAGE')"
      :description="t('CRM.SETTINGS.DELETE_STAGE_CONFIRM')"
      :confirm-button-label="t('CRM.SETTINGS.DELETE_STAGE')"
      @confirm="confirmDeleteStage"
    />
  </div>
</template>

<style scoped>
.sortable-ghost {
  opacity: 0.4;
  background: var(--n-brand-primary-alpha-1) !important;
  border: 2px dashed var(--n-brand-primary) !important;
}

.sortable-drag {
  cursor: grabbing;
  box-shadow: var(--shadow-n-brand-primary-lg);
  transform: scale(1.02);
  z-index: 100;
}
</style>
