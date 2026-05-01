<script setup>
import { computed, onMounted, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

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

const selectedPipelineId = ref(props.conversation.pipeline_id || '');
const selectedStageId = ref(props.conversation.pipeline_stage_id || '');

const pipelineOptions = computed(() =>
  pipelines.value.map(p => ({
    label: p.name,
    value: p.id,
  }))
);

const stageOptions = computed(() =>
  stages.value.map(s => ({
    label: s.name,
    value: s.id,
  }))
);

const isLoading = ref(false);

onMounted(async () => {
  await store.dispatch('crmPipeline/fetchPipelines');
  if (selectedPipelineId.value) {
    await store.dispatch('crmPipeline/fetchStages', selectedPipelineId.value);
  }
});

const handlePipelineChange = async (value) => {
  selectedPipelineId.value = value;
  selectedStageId.value = '';
  if (value) {
    await store.dispatch('crmPipeline/fetchStages', value);
  }
};

const handleSave = async () => {
  if (!selectedStageId.value) return;

  isLoading.ref = true;
  try {
    await store.dispatch('crmPipeline/moveConversation', {
      conversationId: props.conversation.id,
      toStageId: selectedStageId.value,
    });
  } catch (error) {
    // Handle error
  } finally {
    isLoading.ref = false;
  }
};

const hasChanges = computed(() => {
  return selectedStageId.value !== props.conversation.pipeline_stage_id;
});

</script>

<template>
  <div class="flex flex-col gap-3 p-3">
    <div class="flex flex-col gap-1.5">
      <label class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider">
        {{ t('CRM.PIPELINE') }}
      </label>
      <FilterSelect
        :model-value="selectedPipelineId"
        :options="pipelineOptions"
        variant="faded"
        class="w-full"
        @update:model-value="handlePipelineChange"
      />
    </div>

    <div v-if="selectedPipelineId" class="flex flex-col gap-1.5">
      <label class="text-xs font-semibold text-n-slate-11 uppercase tracking-wider">
        {{ t('CRM.STAGE') }}
      </label>
      <FilterSelect
        v-model="selectedStageId"
        :options="stageOptions"
        variant="faded"
        class="w-full"
      />
    </div>

    <div v-if="hasChanges" class="flex justify-end mt-1">
      <NextButton
        size="sm"
        color="blue"
        :label="t('CRM.SAVE')"
        :loading="isLoading"
        @click="handleSave"
      />
    </div>
  </div>
</template>
