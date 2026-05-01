<script setup>
import { computed, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import PipelineEntitySelector from 'dashboard/components/crm/PipelineEntitySelector.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const { t } = useI18n();

const conversations = useMapGetter(
  'contactConversations/getAllConversationsByContactId'
);
const pipelines = useMapGetter('crmPipeline/getAllPipelines');
const uiFlags = useMapGetter('contactConversations/getUIFlags');

const allContactConversations = computed(
  () => conversations.value(props.selectedContact.id) || []
);

const activeDeals = computed(() =>
  allContactConversations.value.filter(conv => conv.pipeline_id)
);

const otherConversations = computed(() =>
  allContactConversations.value.filter(conv => !conv.pipeline_id)
);

const isFetching = computed(() => uiFlags.value.isFetching);

onMounted(() => {
  store.dispatch('crmPipeline/fetchPipelines');
});

const getPipelineName = id => {
  const pipeline = pipelines.value.find(p => p.id === id);
  return pipeline ? pipeline.name : t('CRM.PIPELINE.UNKNOWN');
};
</script>

<template>
  <div class="flex h-full flex-col overflow-y-auto px-6 py-4">
    <!-- Active Deals Section -->
    <div class="mb-8">
      <h3
        class="mb-4 flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-n-slate-11"
      >
        <i class="i-lucide-award text-n-brand-primary" />
        {{ t('CRM.CONTACT_PANEL.ACTIVE_DEALS') }}
        <span
          v-if="activeDeals.length"
          class="rounded-md bg-n-brand-primary/10 px-1.5 py-0.5 text-[10px] text-n-brand-primary"
        >
          {{ activeDeals.length }}
        </span>
      </h3>

      <div v-if="isFetching" class="flex items-center justify-center py-10">
        <Spinner />
      </div>

      <div v-else-if="activeDeals.length > 0" class="flex flex-col gap-3">
        <div
          v-for="conversation in activeDeals"
          :key="conversation.id"
          class="group rounded-2xl border border-n-weak bg-n-alpha-black2 p-4 transition-all hover:border-n-strong"
        >
          <div class="mb-3 flex items-center justify-between">
            <div class="flex items-center gap-2">
              <div
                class="flex h-8 w-8 items-center justify-center rounded-lg border border-n-weak bg-n-alpha-1 transition-all group-hover:border-n-brand-primary/30 group-hover:bg-n-brand-primary/5"
              >
                <i
                  class="i-lucide-box text-n-slate-10 transition-colors group-hover:text-n-brand-primary"
                />
              </div>
              <div class="flex flex-col">
                <span class="text-xs font-bold text-n-slate-12">
                  {{ getPipelineName(conversation.pipeline_id) }}
                </span>
                <span class="text-[10px] text-n-slate-11">
                  {{ $t('CRM.DEAL_ID', { id: conversation.id }) }}
                </span>
              </div>
            </div>
            <woot-label
              :title="conversation.status"
              variant="smooth"
              size="small"
              class="capitalize"
            />
          </div>

          <div class="space-y-3 pl-10">
            <div class="text-sm font-medium leading-tight text-n-slate-12">
              {{
                conversation.additionalAttributes?.mail_subject ||
                t('CRM.CONTACT_PANEL.CONVERSATION_DEAL')
              }}
            </div>

            <div class="border-t border-n-weak/50 pt-2">
              <PipelineEntitySelector :conversation="conversation" />
            </div>
          </div>
        </div>
      </div>

      <div
        v-else-if="!isFetching && otherConversations.length === 0"
        class="flex flex-col items-center justify-center py-12 text-center"
      >
        <div
          class="mb-4 flex h-12 w-12 items-center justify-center rounded-full bg-n-alpha-black2"
        >
          <i class="i-lucide-layers text-xl text-n-slate-10" />
        </div>
        <p class="max-w-[200px] text-sm text-n-slate-11">
          {{ t('CRM.CONTACT_PANEL.NO_ACTIVE_DEALS') }}
        </p>
      </div>
    </div>

    <!-- Other Conversations Section -->
    <div v-if="otherConversations.length > 0">
      <h3
        class="mb-4 flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-n-slate-11"
      >
        <i class="i-lucide-message-square text-n-slate-10" />
        {{ t('CRM.CONTACT_PANEL.CONVERSATIONS_WITHOUT_PIPELINE') }}
      </h3>

      <div class="flex flex-col gap-2">
        <div
          v-for="conversation in otherConversations"
          :key="conversation.id"
          class="group flex items-center justify-between rounded-xl border border-dashed border-n-weak bg-n-alpha-1/50 p-3 transition-all hover:border-n-brand-primary/50"
        >
          <div class="flex min-w-0 flex-col">
            <span class="truncate text-xs font-medium text-n-slate-12">
              #{{ conversation.id }} -
              {{
                conversation.additionalAttributes?.mail_subject ||
                t('CRM.CONTACT_PANEL.CHAT_CONVERSATION')
              }}
            </span>
            <span class="text-[10px] text-n-slate-11">
              {{ t('CRM.CONTACT_PANEL.NOT_IN_CRM') }}
            </span>
          </div>

          <PipelineEntitySelector
            :conversation="conversation"
            class="opacity-50 transition-opacity group-hover:opacity-100"
          />
        </div>
      </div>
    </div>
  </div>
</template>
