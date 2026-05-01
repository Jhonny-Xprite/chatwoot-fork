<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardLabels from 'dashboard/components-next/Conversation/ConversationCard/CardLabelsV5.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';

import { getInboxIconByType } from 'dashboard/helper/inbox';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select', 'selectContact']);

const store = useStore();
const { t } = useI18n();

const viewPrefs = computed(() => store.getters['crmPipeline/viewPreferences']);
const allAttributes = computed(() => store.getters['attributes/getAttributes']);

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee || {});
const unreadCount = computed(() => props.conversation.unread_count || 0);
const conversationLabels = computed(() => props.conversation.labels || []);
const hasSlaPolicyId = computed(() => props.conversation?.sla_policy_id);
const companyName = computed(
  () => contact.value.additional_attributes?.company_name || ''
);

const dynamicAttributes = computed(() => {
  if (!viewPrefs.value.customAttributes?.length) return [];

  const selected = viewPrefs.value.customAttributes;
  const contactAttrs = contact.value.custom_attributes || {};
  const convAttrs = props.conversation.custom_attributes || {};

  return selected
    .map(attr => {
      const definition = allAttributes.value.find(
        a => a.attribute_key === attr.key && a.attribute_model === attr.model
      );
      if (!definition) return null;

      const value =
        attr.model === 'contact_attribute'
          ? contactAttrs[attr.key]
          : convAttrs[attr.key];

      if (value === undefined || value === null || value === '') return null;

      return {
        label: definition.attribute_display_name,
        value,
        key: attr.key,
      };
    })
    .filter(Boolean);
});

const inbox = computed(
  () => store.getters['inboxes/getInbox'](props.conversation.inbox_id) || {}
);
const inboxIcon = computed(() =>
  getInboxIconByType(inbox.value.channel_type, inbox.value.medium, 'line')
);
const inboxName = computed(() => inbox.value.name || '');

const hasUnread = computed(() => unreadCount.value > 0);
const lastMessage = computed(() => {
  return (
    props.conversation.last_non_activity_message ||
    props.conversation.messages?.[0] ||
    null
  );
});
const showReplyNeeded = computed(
  () => hasUnread.value || lastMessage.value?.message_type === 0
);

const lastMessageTime = computed(() => {
  const time =
    props.conversation.last_non_activity_message?.created_at ||
    props.conversation.updated_at;
  if (!time) return '';

  return shortTimestamp(dynamicTime(time));
});

const lastMessagePreview = computed(() => {
  if (lastMessage.value?.content) {
    return lastMessage.value.content;
  }

  return t('CRM.NO_MESSAGES_YET');
});

const leadScore = computed(() => contact.value.lead_score || 0);
const isHotLead = computed(() => leadScore.value >= 70);
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative cursor-pointer select-none rounded-2xl border border-n-slate-3 bg-white p-4 shadow-sm transition-all duration-300 hover:-translate-y-1 hover:border-n-brand-primary/40 hover:shadow-xl hover:shadow-n-brand-primary/5 dark:border-n-slate-2 dark:bg-n-slate-1"
    :class="[
      viewPrefs.density === 'compact' ? 'p-3 gap-3' : 'p-4 gap-4',
      isHotLead ? 'ring-1 ring-n-brand-primary/20' : '',
    ]"
    @click="emit('select', conversation)"
    @keydown.enter.prevent="emit('select', conversation)"
    @keydown.space.prevent="emit('select', conversation)"
  >
    <div v-if="hasUnread" class="absolute -right-1 -top-1 flex h-4 w-4">
      <span
        class="relative inline-flex h-4 w-4 items-center justify-center rounded-full bg-n-brand-primary text-[9px] font-bold text-n-white shadow-sm"
      >
        {{ unreadCount }}
      </span>
    </div>

    <div
      class="flex flex-col"
      :class="viewPrefs.density === 'compact' ? 'gap-2' : 'gap-3'"
    >
      <div
        class="flex items-start"
        :class="viewPrefs.density === 'compact' ? 'gap-2' : 'gap-3'"
      >
        <Avatar
          :src="contact.thumbnail"
          :name="contact.name || t('CRM.UNKNOWN_CONTACT')"
          :size="viewPrefs.density === 'compact' ? 32 : 40"
          class="shadow-sm"
        />
        <div class="min-w-0 flex-1">
          <div class="flex items-center justify-between gap-1">
            <h4
              class="truncate font-bold text-n-slate-12 transition-colors group-hover:text-n-brand-primary"
              :class="viewPrefs.density === 'compact' ? 'text-xs' : 'text-sm'"
            >
              {{ contact.name || t('CRM.UNKNOWN_CONTACT') }}
            </h4>
            <div class="flex items-center gap-1.5 shrink-0">
              <div
                v-if="leadScore > 0"
                class="flex items-center gap-0.5 rounded-md px-1.5 py-0.5 text-[10px] font-black"
                :class="
                  isHotLead
                    ? 'bg-n-brand-primary-alpha-1 text-n-brand-primary'
                    : 'bg-n-slate-2 text-n-slate-11'
                "
              >
                <i v-if="isHotLead" class="i-lucide-flame text-[10px]" />
                {{ leadScore }}
              </div>
              <span
                class="whitespace-nowrap text-[10px] font-medium text-n-slate-10"
              >
                {{ lastMessageTime }}
              </span>
            </div>
          </div>
          <p
            class="truncate font-medium text-n-slate-11"
            :class="
              viewPrefs.density === 'compact'
                ? 'text-[10px]'
                : 'text-[11px] mt-0.5'
            "
          >
            {{ contact.email || contact.phone_number || t('CRM.PHONE') }}
          </p>
          <div
            v-if="
              viewPrefs.showCompanyName ||
              viewPrefs.showPriority ||
              viewPrefs.showChannel
            "
            class="mt-1 flex items-center gap-2"
          >
            <p
              v-if="companyName && viewPrefs.showCompanyName"
              class="truncate text-[10px] font-semibold text-n-slate-10"
            >
              {{ companyName }}
            </p>
            <div
              v-if="inboxName && viewPrefs.showChannel"
              class="flex items-center gap-1 text-[10px] font-semibold text-n-slate-10"
            >
              <span :class="inboxIcon" class="text-xs" />
              <span class="max-w-[80px] truncate">{{ inboxName }}</span>
            </div>
            <CardPriorityIcon
              v-if="conversation.priority && viewPrefs.showPriority"
              :priority="conversation.priority"
            />
          </div>
        </div>
      </div>

      <div
        v-if="
          (conversationLabels.length && viewPrefs.showLabels) ||
          (hasSlaPolicyId && viewPrefs.showSla)
        "
        class="mt-1"
      >
        <CardLabels :labels="conversationLabels">
          <template v-if="hasSlaPolicyId && viewPrefs.showSla" #before>
            <SLACardLabel :chat="conversation" class="ltr:mr-1 rtl:ml-1" />
          </template>
        </CardLabels>
      </div>

      <div
        v-if="viewPrefs.showLastMessage"
        class="rounded-2xl border border-n-slate-2 bg-n-alpha-1 px-3 py-2.5 text-[11px] leading-relaxed text-n-slate-11 transition-colors"
        :class="
          showReplyNeeded
            ? 'border-n-brand-primary/20 bg-n-brand-primary-alpha-1/40 text-n-slate-12 shadow-sm'
            : ''
        "
      >
        <p
          v-if="showReplyNeeded"
          class="mb-1 text-[10px] font-bold uppercase tracking-wide text-n-brand-primary"
        >
          {{ t('CRM.REPLY_NEEDED') }}
        </p>
        <p class="line-clamp-2 break-words">
          {{ lastMessagePreview }}
        </p>
      </div>

      <div
        v-if="dynamicAttributes.length"
        class="flex flex-col gap-2 rounded-2xl border border-n-slate-2 bg-n-alpha-1/20 p-3"
      >
        <div
          v-for="attr in dynamicAttributes"
          :key="attr.key"
          class="flex items-start justify-between gap-2 overflow-hidden"
        >
          <span
            class="shrink-0 text-[10px] font-bold uppercase tracking-tight text-n-slate-10"
          >
            {{ attr.label }}
          </span>
          <span class="truncate text-[10px] font-medium text-n-slate-12">
            {{ attr.value }}
          </span>
        </div>
      </div>

      <div
        class="mt-1 flex items-center justify-between border-t border-n-slate-2 pt-2 dark:border-n-slate-2"
      >
        <div
          v-if="viewPrefs.showAssignee"
          class="flex items-center gap-1.5 overflow-hidden"
        >
          <Avatar
            v-if="assignee.id"
            :src="assignee.thumbnail"
            :name="assignee.name"
            :size="18"
            rounded-full
          />
          <span class="truncate text-[10px] font-bold text-n-slate-11">
            {{ assignee.name || t('CRM.UNASSIGNED') }}
          </span>
        </div>

        <div
          class="flex items-center gap-1.5"
          :class="{ 'ml-auto': !viewPrefs.showAssignee }"
        >
          <button
            v-if="contact.id"
            type="button"
            class="rounded-lg px-2.5 py-1.5 text-[10px] font-bold text-n-slate-11 transition-colors hover:bg-n-slate-2 dark:hover:bg-n-slate-2"
            @click.stop="emit('selectContact', conversation)"
          >
            {{ t('CRM.OPEN_CONTACT') }}
          </button>
          <button
            type="button"
            class="rounded-lg bg-n-brand-primary-alpha-1 px-2.5 py-1.5 text-[10px] font-black text-n-brand-primary transition-all hover:bg-n-brand-primary-alpha-2"
            @click.stop="emit('select', conversation)"
          >
            {{ t('CRM.OPEN_CONVERSATION') }}
          </button>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <span
          class="text-[10px] font-black uppercase tracking-tight text-n-slate-8 dark:text-n-slate-9"
        >
          {{ t('CRM.DEAL_ID', { id: conversation.id }) }}
        </span>
        <span
          class="i-lucide-grip-vertical text-n-slate-8 opacity-0 transition-opacity group-hover:opacity-100 dark:text-n-slate-9"
        />
      </div>
    </div>
  </div>
</template>
