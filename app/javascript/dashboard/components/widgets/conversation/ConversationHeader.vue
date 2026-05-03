<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import { useElementSize } from '@vueuse/core';
import BackButton from '../BackButton.vue';
import InboxName from '../InboxName.vue';
import MoreActions from './MoreActions.vue';
import Avatar from 'next/avatar/Avatar.vue';
import PipelineEntitySelector from '../../crm/PipelineEntitySelector.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import wootConstants from 'dashboard/constants/globals';
import { conversationListPageURL } from 'dashboard/helper/URLHelper';
import { snoozedReopenTime } from 'dashboard/helper/snoozeHelpers';
import { useInbox } from 'dashboard/composables/useInbox';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  chat: {
    type: Object,
    default: () => ({}),
  },
  showBackButton: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();
const store = useStore();
const route = useRoute();
const conversationHeader = ref(null);
const { width } = useElementSize(conversationHeader);
const { isAWebWidgetInbox } = useInbox();

const currentChat = computed(() => store.getters.getSelectedChat);
const accountId = computed(() => store.getters.getCurrentAccountId);

const chatMetadata = computed(() => props.chat.meta);

const backButtonUrl = computed(() => {
  const {
    params: { inbox_id: inboxId, label, teamId, id: customViewId },
    name,
  } = route;

  const conversationTypeMap = {
    conversation_through_mentions: 'mention',
    conversation_through_participating: 'participating',
    conversation_through_unattended: 'unattended',
  };
  return conversationListPageURL({
    accountId: accountId.value,
    inboxId,
    label,
    teamId,
    conversationType: conversationTypeMap[name],
    customViewId,
  });
});

const isHMACVerified = computed(() => {
  if (!isAWebWidgetInbox.value) {
    return true;
  }
  return chatMetadata.value.hmac_verified;
});

const currentContact = computed(() =>
  store.getters['contacts/getContact'](props.chat.meta.sender.id)
);

const isSnoozed = computed(
  () => currentChat.value.status === wootConstants.STATUS_TYPE.SNOOZED
);

const snoozedDisplayText = computed(() => {
  const { snoozed_until: snoozedUntil } = currentChat.value;
  if (snoozedUntil) {
    return `${t('CONVERSATION.HEADER.SNOOZED_UNTIL')} ${snoozedReopenTime(snoozedUntil)}`;
  }
  return t('CONVERSATION.HEADER.SNOOZED_UNTIL_NEXT_REPLY');
});

const inbox = computed(() => {
  const { inbox_id: inboxId } = props.chat;
  return store.getters['inboxes/getInbox'](inboxId);
});

const hasMultipleInboxes = computed(
  () => store.getters['inboxes/getInboxes'].length > 1
);

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);
</script>

<template>
  <div
    ref="conversationHeader"
    class="relative flex items-center justify-between w-full h-16 px-4 bg-white/80 dark:bg-n-slate-1/80 backdrop-blur-2xl border-b border-n-slate-3/30 dark:border-n-slate-2/20 sticky top-0 z-20 transition-all duration-300"
  >
    <div class="flex items-center gap-3 min-w-0">
      <BackButton
        v-if="showBackButton"
        :back-url="backButtonUrl"
        class="bg-white/80 dark:bg-n-slate-2/80 shadow-sm rounded-lg border border-n-slate-3 dark:border-n-slate-2/10 hover:bg-white dark:hover:bg-n-slate-2 transition-all active:scale-95 p-1"
      />
      <div class="relative shrink-0">
        <Avatar
          :name="currentContact.name"
          :src="currentContact.thumbnail"
          :size="40"
          :status="currentContact.availability_status"
          hide-offline-status
          class="!rounded-xl shadow-md border-2 border-white dark:border-n-slate-2"
        />
        <div
          v-if="currentContact.availability_status === 'online'"
          class="absolute -bottom-0.5 -right-0.5 size-3 rounded-full bg-n-teal-9 border-2 border-white dark:border-n-slate-1 shadow-sm"
        />
      </div>

      <div class="flex flex-col min-w-0">
        <div class="flex items-center gap-2">
          <h2
            class="text-base font-black tracking-tight text-n-slate-12 truncate leading-tight cursor-default"
          >
            {{ currentContact.name }}
          </h2>
          <div
            v-if="!isHMACVerified"
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            class="flex items-center justify-center text-n-amber-10"
          >
            <i class="i-lucide-shield-alert text-[10px]" />
          </div>
          <PipelineEntitySelector
            :conversation-id="chat.id"
            :pipeline-id="chat.pipeline_id"
            :stage-id="chat.pipeline_stage_id"
            class="scale-75 origin-left"
          />
        </div>

        <div
          class="flex items-center gap-2 text-[9px] font-black uppercase tracking-wider text-n-slate-10 truncate mt-0.5"
        >
          <InboxName
            v-if="hasMultipleInboxes"
            :inbox="inbox"
            class="!mx-0 bg-n-slate-2/50 dark:bg-n-slate-3/30 px-1.5 py-0.5 rounded border border-n-slate-3/20 dark:border-n-slate-2/10"
          />
          <div v-if="isSnoozed" class="flex items-center gap-1 text-n-amber-10">
            <div class="size-1 rounded-full bg-current animate-pulse" />
            <span>{{ snoozedDisplayText }}</span>
          </div>
        </div>
      </div>
    </div>

    <div class="flex items-center gap-3 shrink-0">
      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="hidden md:flex scale-75 origin-right"
      />
      <div
        class="hidden xl:block w-px h-6 bg-n-slate-3/30 dark:bg-n-slate-2/20"
      />
      <MoreActions
        :conversation-id="currentChat.id"
        class="bg-white/80 dark:bg-n-slate-2/80 shadow-sm rounded-lg border border-n-slate-3 dark:border-n-slate-2/10 hover:bg-white dark:hover:bg-n-slate-2 transition-all active:scale-95"
      />
    </div>
  </div>
</template>
