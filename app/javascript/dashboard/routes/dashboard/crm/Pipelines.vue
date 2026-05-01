<script setup>
import { computed, onMounted } from 'vue';
import { useStore } from 'vuex';
import { useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';
import PipelineBoard from 'dashboard/components/crm/PipelineBoard.vue';
import FilterBar from 'dashboard/components/crm/FilterBar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const store = useStore();
const router = useRouter();
const { t } = useI18n();

const pipelines = computed(() => store.getters['crmPipeline/getAllPipelines']);
const selectedPipeline = computed(
  () => store.getters['crmPipeline/getActivePipeline'] || null
);
const currentPipelineStages = computed(
  () => store.getters['crmPipeline/getStages']
);
const selectedPipelineId = computed({
  get: () => store.getters['crmPipeline/getActivePipeline']?.id || null,
  set: value => {
    if (!value) return;

    store.dispatch('crmPipeline/fetchStages', Number(value));
  },
});
const uiFlags = computed(() => store.getters['crmPipeline/uiFlags']);
const isLoading = computed(
  () => uiFlags.value.isFetchingPipelines || uiFlags.value.isFetchingStages
);

onMounted(async () => {
  const initialPipelineId = await store.dispatch('crmPipeline/fetchPipelines');

  if (initialPipelineId) {
    await store.dispatch('crmPipeline/fetchStages', initialPipelineId);
  }
});

const onDealSelect = deal => {
  const { id } = deal;
  const accountId = store.getters.getCurrentAccountId;

  router.push({
    name: 'inbox_conversation',
    params: { accountId, conversation_id: id },
  });
};

const createPipeline = async () => {
  // eslint-disable-next-line no-alert
  const name = prompt(t('CRM.CREATE_PIPELINE_PROMPT'));
  if (!name) return;

  try {
    await store.dispatch('crmPipeline/createPipeline', name);
  } catch (error) {
    // Ignore creation errors for now
  }
};

const setDefaultPipeline = async () => {
  if (!selectedPipeline.value || selectedPipeline.value.is_default) {
    return;
  }

  try {
    await store.dispatch(
      'crmPipeline/setDefaultPipeline',
      selectedPipeline.value.id
    );
  } catch (error) {
    // Ignore update errors for now
  }
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-h-0 bg-n-surface-1">
    <header
      class="flex items-center justify-between p-4 border-b border-n-weak bg-n-alpha-2"
    >
      <div class="flex items-center gap-4">
        <h1 class="text-xl font-bold text-n-slate-12">
          {{ $t('CRM.HEADER') }}
        </h1>

        <div v-if="pipelines.length > 0" class="flex items-center gap-2">
          <select
            v-model="selectedPipelineId"
            class="bg-n-slate-2 border border-n-weak rounded-md px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary transition-all"
          >
            <option
              v-for="pipeline in pipelines"
              :key="pipeline.id"
              :value="pipeline.id"
            >
              {{ pipeline.name
              }}{{ pipeline.is_default ? ` - ${$t('CRM.DEFAULT_BADGE')}` : '' }}
            </option>
          </select>
        </div>

        <span
          v-if="selectedPipeline?.is_default"
          class="rounded-full bg-n-brand-primary-alpha-1 px-2.5 py-1 text-xs font-semibold text-n-brand-primary"
        >
          {{ $t('CRM.DEFAULT_PIPELINE') }}
        </span>

        <NextButton
          v-else-if="selectedPipeline"
          variant="faded"
          color="teal"
          size="sm"
          icon="i-lucide-star"
          :label="$t('CRM.SET_AS_DEFAULT')"
          @click="setDefaultPipeline"
        />

        <NextButton
          variant="faded"
          color="slate"
          size="sm"
          icon="i-lucide-plus"
          :label="$t('CRM.ADD_PIPELINE')"
          @click="createPipeline"
        />
      </div>
    </header>

    <FilterBar />

    <main class="flex-1 min-h-0 flex flex-col overflow-x-auto">
      <PipelineBoard
        v-if="currentPipelineStages.length"
        :stages="currentPipelineStages"
        @select="onDealSelect"
      />
      <div
        v-else-if="isLoading"
        class="flex-1 flex flex-col items-center justify-center space-y-4"
      >
        <div class="flex gap-4">
          <div
            v-for="index in 3"
            :key="index"
            class="w-80 h-96 bg-n-slate-2 rounded-xl animate-pulse"
          />
        </div>
        <p class="text-n-slate-11">{{ $t('CRM.LOADING') }}</p>
      </div>
      <div
        v-else
        class="flex-1 flex flex-col items-center justify-center p-8 text-center"
      >
        <div
          class="w-16 h-16 bg-n-slate-2 rounded-full flex items-center justify-center mb-4 text-n-slate-10 shadow-inner"
        >
          <i class="i-lucide-layout-kanban w-8 h-8" />
        </div>
        <h3 class="text-lg font-semibold text-n-slate-12 mb-1">
          {{ $t('CRM.NO_PIPELINES') }}
        </h3>
        <p class="text-sm text-n-slate-11 max-w-xs">
          {{ $t('CRM.NO_PIPELINES_SUBTITLE') }}
        </p>
      </div>
    </main>
  </div>
</template>

<style scoped>
:deep(.draggable-container) {
  height: 100%;
}
</style>
