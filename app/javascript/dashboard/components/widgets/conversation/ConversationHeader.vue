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
    class="relative flex flex-col gap-3 items-center justify-between flex-1 w-full min-w-0 xl:flex-row px-6 py-4 h-auto xl:h-[72px] bg-white/70 dark:bg-n-slate-1/70 backdrop-blur-2xl border-b border-n-slate-3/40 dark:border-n-slate-2/20 sticky top-0 z-20 transition-all duration-500"
  >
    <!-- Background Gradient Accent -->
    <div
      class="absolute inset-0 bg-gradient-to-r from-n-brand-primary/5 via-transparent to-transparent pointer-events-none"
    />

    <div
      class="flex items-center justify-start w-full xl:w-auto max-w-full min-w-0 xl:flex-1 relative z-10"
    >
      <BackButton
        v-if="showBackButton"
        :back-url="backButtonUrl"
        class="ltr:mr-4 rtl:ml-4 bg-white/80 dark:bg-n-slate-2/80 shadow-sm rounded-xl border border-n-slate-3 dark:border-n-slate-2/10 hover:bg-white dark:hover:bg-n-slate-2 hover:shadow-md transition-all active:scale-95"
      />
      <div class="relative group cursor-pointer">
        <Avatar
          :name="currentContact.name"
          :src="currentContact.thumbnail"
          :size="48"
          :status="currentContact.availability_status"
          hide-offline-status
          class="!rounded-2xl shadow-xl border-2 border-white dark:border-n-slate-2 transition-transform group-hover:scale-105"
        />
        <div
          v-if="currentContact.availability_status === 'online'"
          class="absolute -bottom-1 -right-1 w-4 h-4 rounded-full bg-n-teal-9 border-2 border-white dark:border-n-slate-1 shadow-sm"
        />
      </div>

      <div
        class="flex flex-col items-start min-w-0 ml-4 overflow-hidden rtl:ml-0 rtl:mr-4"
      >
        <div class="flex flex-row items-center max-w-full gap-2.5 p-0 m-0">
          <h2
            class="text-[17px] font-black tracking-tight text-n-slate-12 truncate leading-tight hover:text-n-brand-primary transition-colors cursor-default"
          >
            {{ currentContact.name }}
          </h2>
          <div
            v-if="!isHMACVerified"
            v-tooltip="$t('CONVERSATION.UNVERIFIED_SESSION')"
            class="flex items-center justify-center p-1 rounded-md bg-n-amber-10/10 text-n-amber-10"
          >
            <i class="i-lucide-shield-alert text-xs" />
          </div>
          <PipelineEntitySelector
            :conversation-id="chat.id"
            :pipeline-id="chat.pipeline_id"
            :stage-id="chat.pipeline_stage_id"
            class="scale-90 origin-left opacity-90 hover:opacity-100 transition-opacity"
          />
        </div>

        <div
          class="flex items-center gap-2.5 overflow-hidden text-[10px] font-black uppercase tracking-[0.1em] text-n-slate-10 text-ellipsis whitespace-nowrap mt-1"
        >
          <InboxName
            v-if="hasMultipleInboxes"
            :inbox="inbox"
            class="!mx-0 bg-n-slate-2/80 dark:bg-n-slate-3/40 px-2 py-0.5 rounded-md border border-n-slate-3/30 dark:border-n-slate-2/20"
          />
          <div
            v-if="isSnoozed"
            class="flex items-center gap-1.5 text-n-amber-10"
          >
            <div class="w-1 h-1 rounded-full bg-current animate-pulse" />
            <span
              class="bg-n-amber-10/10 px-2 py-0.5 rounded-md border border-n-amber-10/20"
            >
              {{ snoozedDisplayText }}
            </span>
          </div>
          <SLACardLabel
            v-if="hasSlaPolicyId"
            :chat="chat"
            class="md:hidden scale-75 origin-left"
          />
        </div>
      </div>
    </div>

    <div
      class="flex flex-row items-center justify-start xl:justify-end flex-shrink-0 gap-4 w-full xl:w-auto header-actions-wrap relative z-10"
    >
      <SLACardLabel
        v-if="hasSlaPolicyId"
        :chat="chat"
        show-extended-info
        :parent-width="width"
        class="hidden md:flex scale-90"
      />

      <div
        class="hidden xl:block w-px h-8 bg-gradient-to-b from-transparent via-n-slate-3/50 dark:via-n-slate-2/30 to-transparent"
      />

      <div class="flex items-center gap-2">
        <MoreActions
          :conversation-id="currentChat.id"
          class="bg-white/80 dark:bg-n-slate-2/80 shadow-sm rounded-xl border border-n-slate-3 dark:border-n-slate-2/10 hover:bg-white dark:hover:bg-n-slate-2 hover:shadow-md transition-all active:scale-95"
        />
      </div>
    </div>
  </div>
</template>
