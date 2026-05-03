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
    class="flex flex-col gap-3 items-center justify-between flex-1 w-full min-w-0 xl:flex-row px-4 py-3 h-auto xl:h-16 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md border-b border-n-slate-3/30 dark:border-n-slate-2/10 sticky top-0 z-20"
  >
    <div
      class="flex items-center justify-start w-full xl:w-auto max-w-full min-w-0 xl:flex-1"
    >
      <BackButton
        v-if="showBackButton"
        :back-url="backButtonUrl"
        class="ltr:mr-3 rtl:ml-3 bg-white dark:bg-n-slate-2 shadow-sm rounded-xl border border-n-slate-3 dark:border-n-slate-2/10"
      />
      <Avatar
        :name="currentContact.name"
        :src="currentContact.thumbnail"
        :size="40"
        :status="currentContact.availability_status"
        hide-offline-status
        class="!rounded-2xl shadow-md border-2 border-white dark:border-n-slate-2/50"
      />
      <div
        class="flex flex-col items-start min-w-0 ml-3 overflow-hidden rtl:ml-0 rtl:mr-3"
      >
        <div class="flex flex-row items-center max-w-full gap-2 p-0 m-0">
          <span
            class="text-base font-black tracking-tight text-n-slate-12 truncate leading-none"
          >
            {{ currentContact.name }}
          </span>
          <PipelineEntitySelector
            :conversation-id="chat.id"
            :pipeline-id="chat.pipeline_id"
            :stage-id="chat.pipeline_stage_id"
            class="scale-90 origin-left"
          />
          <fluent-icon
            v-if="!isHMACVerified"
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            size="14"
            class="text-n-amber-10 my-0 mx-0 min-w-[14px] flex-shrink-0"
            icon="warning"
          />
        </div>

        <div
          class="flex items-center gap-2 overflow-hidden text-[11px] font-bold uppercase tracking-widest text-n-slate-11 text-ellipsis whitespace-nowrap mt-1"
        >
          <InboxName
            v-if="hasMultipleInboxes"
            :inbox="inbox"
            class="!mx-0 bg-n-slate-2 dark:bg-n-slate-3/50 px-1.5 py-0.5 rounded-md"
          />
          <span
            v-if="isSnoozed"
            class="text-n-amber-10 bg-n-amber-10/10 px-1.5 py-0.5 rounded-md"
          >
            {{ snoozedDisplayText }}
          </span>
        </div>
      </div>
    </div>
    <div
      class="flex flex-row items-center justify-start xl:justify-end flex-shrink-0 gap-3 w-full xl:w-auto header-actions-wrap"
    >
      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="hidden md:flex scale-90"
      />
      <div class="w-px h-6 bg-n-slate-3 dark:bg-n-slate-2/10 hidden xl:block" />
      <MoreActions
        :conversation-id="currentChat.id"
        class="bg-white dark:bg-n-slate-2 shadow-sm rounded-xl border border-n-slate-3 dark:border-n-slate-2/10"
      />
    </div>
  </div>
</template>
