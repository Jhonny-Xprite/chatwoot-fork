<script setup>
import { computed, useTemplateRef } from 'vue';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import CardAvatar from './CardAvatar.vue';
import CardContent from './CardContent.vue';
import CardLabels from './CardLabelsV5.vue';
import CardPriorityIcon from './CardPriorityIcon.vue';
import InboxName from 'dashboard/components-next/Conversation/InboxName.vue';
import Avatar from 'next/avatar/Avatar.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';
import CardStatusIcon from './CardStatusIcon.vue';
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
  isInboxView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'selectConversation',
  'deSelectConversation',
  'click',
  'contextmenu',
]);

const lastMessageInChat = computed(() => getLastMessage(props.chat));
const showLabelsSection = computed(() => props.chat.labels?.length > 0);

const voiceCallData = computed(() => ({
  status: props.chat.additional_attributes?.call_status,
  direction: props.chat.additional_attributes?.call_direction,
}));

const unreadCount = computed(() => props.chat.unread_count);

const slaCardLabel = useTemplateRef('slaCardLabel');

const hasSlaPolicyId = computed(
  () => props.chat?.sla_policy_id || slaCardLabel.value?.hasSlaThreshold
);

const selectedModel = computed({
  get: () => props.selected,
  set: value => {
    if (value) {
      emit('selectConversation', value);
    } else {
      emit('deSelectConversation', value);
    }
  },
});
</script>

<template>
  <div
    class="conversation relative cursor-pointer group grid gap-4 items-center px-4 h-14 border-b border-n-slate-3/30 dark:border-n-slate-2/10 hover:bg-white/40 dark:hover:bg-n-slate-3/10 transition-all duration-200"
    :class="{
      'active-premium bg-white dark:bg-n-slate-1 shadow-xl shadow-n-brand-primary/5 z-10':
        isActiveChat,
      'selected bg-n-brand-primary/5': selected,
      'grid-cols-[minmax(0,2fr)_minmax(0,1fr)]': showLabelsSection,
      'grid-cols-[minmax(0,2fr)_max-content]': !showLabelsSection,
    }"
    @click="$emit('click', $event)"
    @contextmenu="$emit('contextmenu', $event)"
  >
    <!-- LEFT SECTION -->
    <div class="flex items-center gap-3 min-w-0 flex-1">
      <div class="flex items-center justify-center flex-shrink-0" @click.stop>
        <Checkbox v-model="selectedModel" class="scale-110" />
      </div>

      <div class="w-px h-4 bg-n-slate-3 dark:bg-n-slate-3/30 flex-shrink-0" />

      <div class="w-5 flex items-center justify-center flex-shrink-0">
        <CardPriorityIcon
          :priority="chat.priority"
          show-empty
          class="!size-4"
        />
      </div>

      <div class="w-5 flex items-center justify-center flex-shrink-0">
        <Avatar
          v-if="showAssignee && assignee.name"
          v-tooltip.top="{
            content: assignee.name,
            delay: { show: 500, hide: 0 },
          }"
          :name="assignee.name"
          :src="assignee.thumbnail"
          :size="18"
          :status="assignee.availability_status"
          hide-offline-status
          class="!rounded-lg"
        />
        <span v-else class="i-lucide-user-plus text-n-slate-7 size-4" />
      </div>

      <div class="w-5 flex items-center justify-center flex-shrink-0">
        <CardStatusIcon :status="chat.status" show-empty class="!size-4" />
      </div>

      <div class="w-px h-4 bg-n-slate-3 dark:bg-n-slate-3/30 flex-shrink-0" />

      <div v-if="!isInboxView && showInboxName" class="w-24 flex-shrink-0">
        <InboxName
          v-if="showInboxName"
          :inbox="inbox"
          class="min-w-0 scale-90 origin-left"
        />
      </div>

      <div
        v-if="!isInboxView && showInboxName"
        class="w-px h-4 bg-n-slate-3 dark:bg-n-slate-3/30 flex-shrink-0"
      />

      <div
        v-tooltip.top="{
          content: chat.id,
          delay: { show: 500, hide: 0 },
        }"
        class="flex items-center gap-1.5 max-w-24 w-full min-w-0 flex-shrink-0"
      >
        <span
          class="text-[10px] font-black text-n-slate-10 tracking-widest bg-n-slate-2 dark:bg-n-slate-3/30 px-1.5 py-0.5 rounded-md"
        >
          #{{ chat.id }}
        </span>
      </div>

      <CardAvatar
        :contact="currentContact"
        :selected="false"
        :enable-selection="false"
        :hide-thumbnail="false"
        class="!size-8 !rounded-xl shadow-sm"
      />

      <h4
        class="text-sm font-black tracking-tight text-n-slate-12 truncate w-40 flex-shrink-0"
      >
        {{ currentContact.name }}
      </h4>

      <CardContent
        :last-message="lastMessageInChat"
        :voice-call-status="voiceCallData.status"
        :voice-call-direction="voiceCallData.direction"
        :unread-count="unreadCount"
        :show-expanded-preview="false"
        class="flex-1 text-xs"
      />
    </div>

    <!-- RIGHT SECTION -->
    <div class="flex items-center justify-end gap-3 flex-shrink-0">
      <div v-if="showLabelsSection" class="min-w-0 w-full flex justify-end">
        <CardLabels
          :labels="chat.labels"
          disable-toggle
          class="my-0 scale-90 origin-right"
        />
      </div>

      <div v-if="hasSlaPolicyId" class="flex-shrink-0 scale-90">
        <SLACardLabel ref="slaCardLabel" :chat="chat" />
      </div>

      <div class="flex-shrink-0 w-20 text-end">
        <TimeAgo
          :conversation-id="chat.id"
          :last-activity-timestamp="chat.timestamp"
          :created-at-timestamp="chat.created_at"
          class="font-black text-[10px] text-n-slate-11 uppercase tracking-tighter"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.active-premium {
  position: relative;
}

.active-premium::before {
  content: '';
  position: absolute;
  left: 0;
  top: 15%;
  bottom: 15%;
  width: 3px;
  background: var(--color-n-brand-primary);
  border-radius: 0 4px 4px 0;
  box-shadow: 0 0 10px var(--color-n-brand-primary);
}

.conversation {
  transition:
    transform 0.2s cubic-bezier(0.16, 1, 0.3, 1),
    background-color 0.2s ease;
}

.conversation:hover:not(.active-premium) {
  transform: translateX(2px);
}
</style>
