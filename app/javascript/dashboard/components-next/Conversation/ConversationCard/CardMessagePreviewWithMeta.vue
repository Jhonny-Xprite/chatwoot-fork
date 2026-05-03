<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabels.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/ConversationCard/SLACardLabel.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  accountLabels: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();

const slaCardLabelRef = ref(null);

const { getPlainText } = useMessageFormatter();

const lastNonActivityMessageContent = computed(() => {
  const { lastNonActivityMessage = {}, customAttributes = {} } =
    props.conversation;
  const { email: { subject } = {} } = customAttributes;
  return getPlainText(
    subject || lastNonActivityMessage?.content || t('CHAT_LIST.NO_CONTENT')
  );
});

const assignee = computed(() => {
  const { meta: { assignee: agent = {} } = {} } = props.conversation;
  return {
    name: agent.name ?? agent.availableName,
    thumbnail: agent.thumbnail,
    status: agent.availabilityStatus,
  };
});

const unreadMessagesCount = computed(() => {
  const { unreadCount } = props.conversation;
  return unreadCount;
});

const hasSlaThreshold = computed(() => {
  return (
    slaCardLabelRef.value?.hasSlaThreshold && props.conversation?.slaPolicyId
  );
});

defineExpose({
  hasSlaThreshold,
});
</script>

<template>
  <div class="flex flex-col w-full gap-1">
    <div class="flex items-center justify-between w-full gap-2 py-1 h-7">
      <p class="mb-0 text-sm leading-7 text-n-slate-12 line-clamp-1">
        {{ lastNonActivityMessageContent }}
      </p>

      <div
        v-if="unreadMessagesCount > 0"
        class="inline-flex items-center justify-center flex-shrink-0 rounded-full size-5 bg-n-brand"
      >
        <span class="text-xs font-semibold text-white">
          {{ unreadMessagesCount }}
        </span>
      </div>
    </div>

    <div class="flex items-center gap-2.5 h-7">
      <SLACardLabel
        v-show="hasSlaThreshold"
        ref="slaCardLabelRef"
        :conversation="conversation"
      />
      <div v-if="hasSlaThreshold" class="w-px h-3 bg-n-slate-4" />

      <div
        v-if="conversation.pipeline_stage"
        class="flex items-center gap-1.5 px-1.5 py-0.5 rounded-md bg-n-alpha-1 border border-n-strong flex-shrink-0"
      >
        <div
          class="size-1.5 rounded-full"
          :style="{
            backgroundColor:
              conversation.pipeline_stage.color || 'var(--n-slate-4)',
          }"
        />
        <span
          class="text-[10px] font-bold text-n-slate-11 uppercase tracking-tight truncate max-w-[100px]"
          :title="`${conversation.pipeline_name} › ${conversation.pipeline_stage.name}`"
        >
          {{ conversation.pipeline_stage.name }}
        </span>
      </div>

      <div
        v-if="conversation.pipeline_stage"
        class="w-px h-3 bg-n-slate-4 flex-shrink-0"
      />

      <div class="overflow-hidden flex-1">
        <CardLabels
          :conversation-labels="conversation.labels"
          :account-labels="accountLabels"
        />
      </div>
      <Avatar
        v-if="assignee.name"
        :name="assignee.name"
        :src="assignee.thumbnail"
        :size="20"
        :status="assignee.status"
        rounded-full
        class="flex-shrink-0"
      />
    </div>
  </div>
</template>
