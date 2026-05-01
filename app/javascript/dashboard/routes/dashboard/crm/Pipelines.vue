<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore } from 'vuex';
import { useRouter, useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import PipelineBoard from 'dashboard/components/crm/PipelineBoard.vue';
import FilterBar from 'dashboard/components/crm/FilterBar.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ViewCustomizer from 'dashboard/components/crm/ViewCustomizer.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';

const props = defineProps({
  pipelineId: {
    type: [String, Number],
    default: null,
  },
  viewId: {
    type: [String, Number],
    default: null,
  },
});

const DEFAULT_FILTERS = {
  q: '',
  assigneeId: null,
  labels: [],
  status: '',
  inboxId: null,
  teamId: null,
  priority: '',
};

const store = useStore();
const router = useRouter();
const route = useRoute();
useI18n();

const accountId = computed(
  () => store.getters.getCurrentAccountId || route.params.accountId
);
const pipelines = computed(() => store.getters['crmPipeline/getAllPipelines']);
const savedViews = computed(
  () => store.getters['customViews/getConversationCustomViews']
);
const selectedPipeline = computed(
  () => store.getters['crmPipeline/getActivePipeline'] || null
);
const currentPipelineStages = computed(
  () => store.getters['crmPipeline/getStages']
);
const activeView = computed(() =>
  savedViews.value.find(view => view.id === Number(props.viewId))
);
const uiFlags = computed(() => store.getters['crmPipeline/uiFlags']);
const isLoading = computed(
  () => uiFlags.value.isFetchingPipelines || uiFlags.value.isFetchingStages
);
const isCreatePipelineOpen = ref(false);
const createPipelineName = ref('');

const selectedPipelineId = computed({
  get: () => selectedPipeline.value?.id || '',
  set: value => {
    const nextPipelineId = Number(value);
    if (!nextPipelineId) return;

    router.push({
      name: 'crm_pipeline_details',
      params: {
        accountId: accountId.value,
        pipelineId: nextPipelineId,
      },
    });
  },
});

const selectedViewId = computed({
  get: () => activeView.value?.id || '',
  set: value => {
    if (!value) {
      router.push({
        name: selectedPipeline.value ? 'crm_pipeline_details' : 'crm_pipelines',
        params: selectedPipeline.value
          ? {
              accountId: accountId.value,
              pipelineId: selectedPipeline.value.id,
            }
          : { accountId: accountId.value },
      });
      return;
    }

    router.push({
      name: 'crm_view',
      params: {
        accountId: accountId.value,
        viewId: value,
      },
    });
  },
});

const getPipelineIdFromView = view => {
  const pipelineFilter = view?.query?.payload?.find(
    filter => filter.attribute_key === 'pipeline_id'
  );

  return Number(pipelineFilter?.values?.[0]) || null;
};

const extractFiltersFromView = view => {
  const payload = view?.query?.payload || [];

  return payload.reduce(
    (accumulator, filter) => {
      const values = Array.isArray(filter.values) ? filter.values : [];
      const firstValue = values[0];

      switch (filter.attribute_key) {
        case 'assignee_id':
          accumulator.assigneeId = Number(firstValue) || null;
          break;
        case 'labels':
          accumulator.labels = values;
          break;
        case 'status':
          accumulator.status = firstValue || '';
          break;
        case 'inbox_id':
          accumulator.inboxId = Number(firstValue) || null;
          break;
        case 'team_id':
          accumulator.teamId = Number(firstValue) || null;
          break;
        case 'priority':
          accumulator.priority = firstValue || '';
          break;
        default:
          break;
      }

      return accumulator;
    },
    { ...DEFAULT_FILTERS }
  );
};

const syncBoardContext = async () => {
  await Promise.all([
    store.dispatch('customViews/get', 'conversation'),
    store.dispatch('crmPipeline/fetchPipelines'),
  ]);

  const view = savedViews.value.find(item => item.id === Number(props.viewId));
  const filters = view ? extractFiltersFromView(view) : { ...DEFAULT_FILTERS };
  let nextPipelineId =
    Number(props.pipelineId) ||
    getPipelineIdFromView(view) ||
    store.getters['crmPipeline/getActivePipeline']?.id;

  await store.dispatch('crmPipeline/replaceFilters', filters);

  if (nextPipelineId) {
    await store.dispatch('crmPipeline/fetchStages', nextPipelineId);
  }
};

onMounted(() => {
  syncBoardContext();
  store.dispatch('crmPipeline/initializeViewPreferences');
  store.dispatch('labels/get');
  store.dispatch('agents/get');
});

watch(
  () => [props.pipelineId, props.viewId],
  () => {
    syncBoardContext();
  }
);

const onDealSelect = deal => {
  router.push({
    name: 'crm_conversation',
    params: {
      accountId: accountId.value,
      conversationId: deal.id,
    },
  });
};

const onContactSelect = deal => {
  const contactId = deal.meta?.sender?.id;
  if (!contactId) return;

  router.push({
    name: 'crm_contact',
    params: {
      accountId: accountId.value,
      contactId,
    },
  });
};

const createPipeline = async () => {
  const name = createPipelineName.value.trim();
  if (!name) return;

  try {
    const nextPipelineId = await store.dispatch(
      'crmPipeline/createPipeline',
      name
    );
    if (nextPipelineId) {
      createPipelineName.value = '';
      isCreatePipelineOpen.value = false;
      router.push({
        name: 'crm_pipeline_details',
        params: {
          accountId: accountId.value,
          pipelineId: nextPipelineId,
        },
      });
    }
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

const togglePipelineCreate = () => {
  isCreatePipelineOpen.value = !isCreatePipelineOpen.value;
  if (!isCreatePipelineOpen.value) {
    createPipelineName.value = '';
  }
};

const createStage = async () => {
  if (!selectedPipeline.value) return;

  // eslint-disable-next-line no-alert
  const name = prompt(
    store.getters['crmPipeline/getStages'].length === 0
      ? 'First stage name:'
      : 'New stage name:'
  );
  if (name) {
    try {
      await store.dispatch('crmPipeline/createStage', {
        pipelineId: selectedPipeline.value.id,
        stage: { name },
      });
    } catch (error) {
      // Error handling
    }
  }
};
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-h-0 bg-n-surface-1">
    <header
      class="flex flex-wrap items-center justify-between gap-3 p-4 border-b border-n-weak bg-n-alpha-2"
    >
      <div class="flex flex-wrap items-center gap-3">
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

        <div v-if="savedViews.length > 0" class="flex items-center gap-2">
          <select
            v-model="selectedViewId"
            class="bg-n-slate-2 border border-n-weak rounded-md px-3 py-1.5 text-sm text-n-slate-12 outline-none focus:border-n-brand-primary transition-all"
          >
            <option value="">{{ $t('CRM.ALL_VIEWS') }}</option>
            <option v-for="view in savedViews" :key="view.id" :value="view.id">
              {{ view.name }}
            </option>
          </select>
        </div>

        <span
          v-if="selectedPipeline?.is_default"
          class="rounded-full bg-n-brand-primary-alpha-1 px-2.5 py-1 text-xs font-semibold text-n-brand-primary"
        >
          {{ $t('CRM.DEFAULT_PIPELINE') }}
        </span>

        <span
          v-if="activeView"
          class="rounded-full bg-n-slate-2 px-2.5 py-1 text-xs font-semibold text-n-slate-11"
        >
          {{ $t('CRM.ACTIVE_VIEW', { name: activeView.name }) }}
        </span>

        <NextButton
          v-if="activeView"
          variant="ghost"
          color="slate"
          size="xs"
          icon="i-lucide-x"
          :label="$t('CRM.CLEAR_VIEW')"
          @click="selectedViewId = ''"
        />

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
          :icon="isCreatePipelineOpen ? 'i-lucide-x' : 'i-lucide-plus'"
          :label="
            isCreatePipelineOpen
              ? $t('DIALOG.BUTTONS.CANCEL')
              : $t('CRM.ADD_PIPELINE')
          "
          @click="togglePipelineCreate"
        />

        <div class="h-6 w-px bg-n-slate-3 mx-1" />

        <Popover align="end">
          <NextButton
            variant="ghost"
            color="slate"
            size="sm"
            icon="i-lucide-layout-template"
            label="Visualização"
          />
          <template #content>
            <ViewCustomizer />
          </template>
        </Popover>
      </div>

      <div
        v-if="isCreatePipelineOpen"
        class="flex flex-wrap items-center gap-2"
      >
        <input
          v-model="createPipelineName"
          type="text"
          :placeholder="$t('CRM.CREATE_PIPELINE_PROMPT')"
          class="w-56 rounded-md border border-n-weak bg-white px-3 py-1.5 text-sm text-n-slate-12 outline-none transition-all focus:border-n-brand-primary"
          @keydown.enter.prevent="createPipeline"
        />
        <NextButton
          color="blue"
          size="sm"
          icon="i-lucide-save"
          :label="$t('CRM.SAVE')"
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
        @select-contact="onContactSelect"
        @add-stage="createStage"
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
        <p class="text-sm text-n-slate-11 max-w-xs mb-4">
          {{ $t('CRM.NO_PIPELINES_SUBTITLE') }}
        </p>
        <NextButton
          v-if="selectedPipeline"
          variant="faded"
          color="blue"
          size="sm"
          icon="i-lucide-plus"
          label="Add first stage"
          @click="createStage"
        />
      </div>
    </main>
  </div>
</template>
