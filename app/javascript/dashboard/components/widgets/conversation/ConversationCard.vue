<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import Avatar from 'next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';
import InboxName from '../InboxName.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import UnreadBadge from 'dashboard/components-next/Conversation/ConversationCard/UnreadBadge.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import VoiceCallStatus from './VoiceCallStatus.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';

const props = defineProps({
  chat: { type: Object, required: true },
  currentContact: { type: Object, required: true },
  assignee: { type: Object, default: () => ({}) },
  inbox: { type: Object, default: () => ({}) },
  selected: { type: Boolean, default: false },
  isActiveChat: { type: Boolean, default: false },
  showAssignee: { type: Boolean, default: false },
  showInboxName: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
});

const emit = defineEmits([
  'click',
  'contextmenu',
  'selectConversation',
  'deSelectConversation',
]);
const { t } = useI18n();

const hovered = ref(false);

const unreadCount = computed(() => props.chat.unread_count);
const hasUnread = computed(() => unreadCount.value > 0);
const lastMessageInChat = computed(() => getLastMessage(props.chat));

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const activeLabels = computed(() => {
  const labels = props.chat.labels || [];
  return labels.slice(0, 2);
});

const hiddenLabelsCount = computed(() => {
  const labels = props.chat.labels || [];
  return Math.max(labels.length - activeLabels.value.length, 0);
});

const showMetaRow = computed(() => {
  return (
    activeLabels.value.length > 0 || hasSlaPolicyId.value || props.showAssignee
  );
});

const messagePreviewClass = computed(() => {
  return [
    hasUnread.value ? 'font-medium text-n-slate-12' : 'text-n-slate-11',
    'block w-full overflow-hidden text-ellipsis whitespace-nowrap',
  ];
});

const lastMessageToneClass = computed(() => {
  if (lastMessageInChat.value?.private) {
    return 'text-n-amber-11';
  }

  if (hasUnread.value || lastMessageInChat.value?.message_type === 0) {
    return 'text-n-brand-primary';
  }

  return 'text-n-slate-10';
});

const lastMessageMetaLabel = computed(() => {
  if (!lastMessageInChat.value) return '';
  if (lastMessageInChat.value.private) {
    return t('CRM.MESSAGE_SENDER.PRIVATE');
  }

  return lastMessageInChat.value.message_type === 1
    ? t('CRM.MESSAGE_SENDER.TEAM')
    : t('CRM.MESSAGE_SENDER.LEAD');
});

const onThumbnailHover = () => {
  hovered.value = !props.hideThumbnail;
};

const onThumbnailLeave = () => {
  hovered.value = false;
};

const onSelectConversation = checked => {
  if (checked) {
    emit('selectConversation', props.chat.id, props.inbox.id);
  } else {
    emit('deSelectConversation', props.chat.id, props.inbox.id);
  }
};

const selectedModel = computed({
  get: () => props.selected,
  set: value => onSelectConversation(value),
});

watch(
  () => props.chat.id,
  () => {
    hovered.value = false;
  }
);
</script>

<template>
  <div
    class="relative flex min-h-[92px] w-full flex-col px-4 py-3 cursor-pointer conversation border-b border-n-slate-3/20 dark:border-n-slate-2/10 transition-colors duration-200 group"
    :class="{
      'active-premium bg-white/70 dark:bg-n-slate-1/70 shadow-sm ring-1 ring-inset ring-n-brand-primary/20 z-10':
        isActiveChat,
      'selected bg-n-brand-primary/5': selected,
      '!px-2 !py-2': compact,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <!-- Background Blur Effect for Active Chat -->
    <div
      v-if="isActiveChat"
      class="absolute inset-0 bg-white/30 dark:bg-n-slate-1/30 backdrop-blur-md -z-10"
    />

    <div class="flex items-start gap-3">
      <!-- Avatar Section -->
      <div
        class="relative flex-shrink-0 mt-1"
        @mouseenter="onThumbnailHover"
        @mouseleave="onThumbnailLeave"
      >
        <Avatar
          v-if="!hideThumbnail"
          :name="currentContact.name"
          :src="currentContact.thumbnail"
          :size="compact ? 32 : 44"
          :status="currentContact.availability_status"
          class="!rounded-2xl shadow-sm border border-white dark:border-n-slate-2/50"
          hide-offline-status
        >
          <template #overlay="{ size }">
            <label
              v-if="hovered || selected"
              class="flex items-center justify-center rounded-2xl cursor-pointer absolute inset-0 z-10 backdrop-blur-md bg-white/40 dark:bg-black/40 border border-white/20"
              :style="{ width: `${size}px`, height: `${size}px` }"
              @click.stop
            >
              <Checkbox v-model="selectedModel" class="scale-110" />
            </label>
          </template>
        </Avatar>
      </div>

      <!-- Main Content -->
      <div class="flex-1 min-w-0 flex flex-col gap-1">
        <!-- Top Metadata Row -->
        <div class="flex items-center justify-between gap-2 h-5">
          <div class="flex items-center gap-2 overflow-hidden">
            <div
              v-if="chat.pipeline_stage"
              class="flex items-center gap-1.5 bg-n-brand-primary/10 dark:bg-n-brand-primary/20 px-2 py-0.5 rounded-full border border-n-brand-primary/20"
            >
              <div
                class="size-1.5 rounded-full animate-pulse"
                :style="{
                  backgroundColor:
                    chat.pipeline_stage.color || 'var(--color-n-brand-primary)',
                }"
              />
              <span
                class="text-[9px] font-black text-n-brand-primary uppercase tracking-widest truncate max-w-[100px]"
                :title="`${chat.pipeline_name} › ${chat.pipeline_stage.name}`"
              >
                {{ chat.pipeline_stage.name }}
              </span>
            </div>
            <InboxName
              v-if="showInboxName"
              :inbox="inbox"
              class="scale-90 origin-left"
            />
          </div>
          <div class="flex items-center gap-1.5">
            <CardPriorityIcon
              v-if="chat.priority"
              :priority="chat.priority"
              class="!size-3.5 opacity-80"
            />
            <span
              class="text-[10px] font-bold text-n-slate-10 tracking-tight uppercase group-hover:text-n-slate-12 transition-colors"
            >
              <TimeAgo
                :last-activity-timestamp="chat.timestamp"
                :created-at-timestamp="chat.created_at"
                :conversation-id="chat.id"
              />
            </span>
          </div>
        </div>

        <!-- Name/Title Row -->
        <div class="flex items-center justify-between gap-2 mt-0.5">
          <h4
            class="text-[15px] font-black tracking-tight text-n-slate-12 truncate flex-1 leading-none group-hover:text-n-brand-primary transition-colors"
          >
            {{ currentContact.name }}
          </h4>
          <UnreadBadge
            v-if="hasUnread"
            :count="unreadCount"
            class="shadow-sm shadow-n-brand-primary/10 scale-90"
          />
        </div>

        <!-- Message Preview Row -->
        <div
          class="mt-1 rounded-xl border border-n-slate-3/20 bg-n-slate-2/40 px-2.5 py-2 transition-colors group-hover:bg-white/60 dark:border-n-slate-2/20 dark:bg-n-slate-2/20 dark:group-hover:bg-n-slate-2/40"
        >
          <VoiceCallStatus
            v-if="voiceCallData.status"
            key="voice-status-row"
            :status="voiceCallData.status"
            :direction="voiceCallData.direction"
            :message-preview-class="messagePreviewClass"
            class="min-w-0 flex-1"
          />
          <template v-else-if="lastMessageInChat">
            <div class="mb-1 flex items-center gap-1.5">
              <span
                class="text-[9px] font-black uppercase tracking-widest"
                :class="lastMessageToneClass"
              >
                {{ lastMessageMetaLabel }}
              </span>
              <div class="h-1 w-1 rounded-full bg-n-slate-4" />
            </div>
            <MessagePreview
              key="message-preview"
              :message="lastMessageInChat"
              class="min-w-0 flex-1 text-[12px] leading-tight"
              :class="messagePreviewClass"
            />
          </template>
        </div>

        <!-- Bottom Row: Tags/SLA -->
        <div
          v-if="showMetaRow"
          class="mt-1 flex items-center justify-between gap-2"
        >
          <div class="flex min-w-0 flex-wrap items-center gap-1.5">
            <SLACardLabel v-if="hasSlaPolicyId" :chat="chat" />
            <span
              v-for="label in activeLabels"
              :key="label"
              class="inline-flex max-w-[88px] items-center rounded-full bg-n-slate-2/70 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-n-slate-11"
              :title="label"
            >
              <span class="truncate">{{ label }}</span>
            </span>
            <span
              v-if="hiddenLabelsCount > 0"
              class="inline-flex items-center rounded-full bg-n-brand-primary/10 px-2 py-0.5 text-[9px] font-black uppercase tracking-wider text-n-brand-primary"
            >
              {{ `+${hiddenLabelsCount}` }}
            </span>
          </div>
          <div
            v-if="showAssignee && assignee.name"
            class="flex items-center gap-1 bg-n-slate-3/50 dark:bg-n-slate-2/30 px-1.5 py-0.5 rounded-lg border border-n-slate-3/20"
          >
            <span
              class="text-[9px] font-bold text-n-slate-11 uppercase tracking-wider"
            >
              {{ assignee.name }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.conversation {
  transition:
    background-color 0.2s ease,
    box-shadow 0.2s ease,
    border-color 0.2s ease;
}

.conversation:hover:not(.active-premium) {
  @apply bg-white/20 dark:bg-n-slate-3/10;
}

.active-premium {
  @apply border-n-brand-primary/20;
}

.active-premium::before {
  content: '';
  position: absolute;
  left: 0;
  top: 14px;
  bottom: 14px;
  width: 3px;
  background: var(--color-n-brand-primary);
  border-radius: 99px;
}

.selected {
  @apply ring-2 ring-n-brand-primary/30 ring-inset;
}
</style>
