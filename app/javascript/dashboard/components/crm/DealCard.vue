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
import Popover from 'dashboard/components-next/popover/Popover.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

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

      const options = (definition.attribute_values || []).map(opt => ({
        label: opt,
        value: opt,
      }));

      return {
        label: definition.attribute_display_name,
        value,
        key: attr.key,
        type: definition.attribute_type,
        options,
        model: attr.model,
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

const lastMessageSenderLabel = computed(() => {
  if (!lastMessage.value) return '';
  const isAgent = lastMessage.value.message_type === 1;
  return isAgent ? t('CRM.MESSAGE_SENDER.TEAM') : t('CRM.MESSAGE_SENDER.LEAD');
});

const leadScore = computed(() => contact.value.lead_score || 0);
const isHotLead = computed(() => leadScore.value >= 70);

const agents = computed(() => store.getters['agents/getAgents']);
const agentOptions = computed(() =>
  agents.value.map(agent => ({
    label: agent.name,
    value: agent.id,
    thumbnail: agent.thumbnail,
  }))
);

const priorityOptions = [
  {
    label: t('CONVERSATION.PRIORITY.OPTIONS.NONE'),
    value: null,
    icon: 'i-lucide-minus',
  },
  {
    label: t('CONVERSATION.PRIORITY.OPTIONS.URGENT'),
    value: 'urgent',
    icon: 'i-lucide-alert-circle',
    color: 'text-n-ruby-9',
  },
  {
    label: t('CONVERSATION.PRIORITY.OPTIONS.HIGH'),
    value: 'high',
    icon: 'i-lucide-chevron-up',
    color: 'text-n-amber-9',
  },
  {
    label: t('CONVERSATION.PRIORITY.OPTIONS.MEDIUM'),
    value: 'medium',
    icon: 'i-lucide-minus',
    color: 'text-n-teal-9',
  },
  {
    label: t('CONVERSATION.PRIORITY.OPTIONS.LOW'),
    value: 'low',
    icon: 'i-lucide-chevron-down',
    color: 'text-n-slate-9',
  },
];

const onPriorityChange = async priority => {
  try {
    await store.dispatch('assignPriority', {
      conversationId: props.conversation.id,
      priority,
    });
  } catch (error) {
    // Error handled by store
  }
};

const onAssigneeChange = async agentId => {
  try {
    await store.dispatch('assignAgent', {
      conversationId: props.conversation.id,
      agentId,
    });
  } catch (error) {
    // Error handled by store
  }
};

const allLabels = computed(() => store.getters['labels/getLabels']);
const labelOptions = computed(() =>
  allLabels.value.map(l => ({ label: l.title, value: l.title }))
);

const onLabelsChange = async labels => {
  try {
    await store.dispatch('conversationLabels/updateConversationLabels', {
      conversationId: props.conversation.id,
      labels,
    });
  } catch (error) {
    // Error
  }
};

const onAttributeUpdate = async (attr, newValue) => {
  try {
    const updatedAttrs = { [attr.key]: newValue };
    if (attr.model === 'contact_attribute') {
      await store.dispatch('contacts/updateCustomAttributes', {
        contactId: contact.value.id,
        customAttributes: updatedAttrs,
      });
    } else {
      await store.dispatch('updateCustomAttributes', {
        conversationId: props.conversation.id,
        customAttributes: updatedAttrs,
      });
    }
  } catch (error) {
    // Error
  }
};
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative cursor-pointer select-none rounded-2xl border border-n-slate-3 bg-white p-4 shadow-sm transition-[border-color,box-shadow,transform] duration-200 hover:-translate-y-1 hover:border-n-brand-primary/40 hover:shadow-xl hover:shadow-n-brand-primary/5 dark:border-n-slate-2 dark:bg-n-slate-1"
    :class="[
      viewPrefs.density === 'compact' ? 'p-3 gap-3' : 'p-4 gap-4',
      isHotLead ? 'ring-1 ring-n-brand-primary/20' : '',
      showReplyNeeded
        ? 'bg-n-brand-primary-alpha-1/10 border-n-brand-primary-alpha-2'
        : '',
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
        <div class="relative">
          <Avatar
            :src="contact.thumbnail"
            :name="contact.name || t('CRM.UNKNOWN_CONTACT')"
            :size="viewPrefs.density === 'compact' ? 32 : 40"
            class="shadow-sm transition-transform group-hover:scale-105"
          />
          <div
            v-if="showReplyNeeded"
            class="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-white bg-n-brand-primary dark:border-n-slate-1 animate-pulse shadow-sm"
          />
        </div>
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
            <Popover align="end">
              <template #trigger>
                <div
                  class="cursor-pointer hover:scale-110 transition-transform"
                  @click.stop
                >
                  <CardPriorityIcon
                    v-if="viewPrefs.showPriority"
                    :priority="conversation.priority || 'none'"
                  />
                  <div
                    v-else-if="!conversation.priority"
                    class="i-lucide-flag text-n-slate-4 w-3 h-3"
                  />
                </div>
              </template>
              <template #content>
                <div @click.stop>
                  <SelectMenu
                    :options="priorityOptions"
                    :value="conversation.priority"
                    @select="onPriorityChange"
                  />
                </div>
              </template>
            </Popover>
          </div>
        </div>
      </div>

      <div
        v-if="
          (conversationLabels.length && viewPrefs.showLabels) ||
          (hasSlaPolicyId && viewPrefs.showSla)
        "
        class="mt-1 flex items-center gap-1.5"
      >
        <CardLabels :labels="conversationLabels" class="flex-1">
          <template v-if="hasSlaPolicyId && viewPrefs.showSla" #before>
            <SLACardLabel :chat="conversation" class="ltr:mr-1 rtl:ml-1" />
          </template>
        </CardLabels>
        <Popover align="end">
          <template #trigger>
            <Button
              variant="ghost"
              color="slate"
              size="xs"
              icon="i-lucide-plus"
              class="!p-1 h-5 w-5 rounded-md opacity-0 group-hover:opacity-100 transition-opacity"
              @click.stop
            />
          </template>
          <template #content>
            <div class="p-2 w-64" @click.stop>
              <TagMultiSelectComboBox
                :options="labelOptions"
                :model-value="conversationLabels"
                @update:model-value="onLabelsChange"
              />
            </div>
          </template>
        </Popover>
      </div>

      <div
        v-if="viewPrefs.showLastMessage"
        class="rounded-xl border border-n-brand-primary-alpha-1 bg-n-brand-primary-alpha-1/5 px-2.5 py-2 text-[11px] leading-snug group-hover:bg-white dark:group-hover:bg-n-slate-2 transition-colors"
      >
        <div class="flex items-center gap-1.5 line-clamp-1">
          <span
            class="font-black tracking-tighter uppercase whitespace-nowrap"
            :class="
              lastMessage?.message_type === 1
                ? 'text-n-slate-10'
                : 'text-n-brand-primary'
            "
          >
            {{ lastMessageSenderLabel }}:
          </span>
          <p class="truncate italic text-n-slate-11">
            {{ lastMessagePreview }}
          </p>
        </div>
      </div>

      <div
        v-if="dynamicAttributes.length"
        class="overflow-x-auto scroll-smooth"
      >
        <div class="flex gap-1.5 min-w-min">
          <div
            v-for="attr in dynamicAttributes"
            :key="attr.key"
            class="flex items-center gap-1.5 rounded-md border border-n-slate-3 bg-n-slate-1 px-2 py-0.5 shadow-sm hover:border-n-brand-primary/40 transition-colors flex-shrink-0"
            @click.stop
          >
            <span
              class="text-[9px] font-black uppercase text-n-slate-9 tracking-tighter"
            >
              {{ attr.label }}
            </span>
            <Popover v-if="attr.type === 'list'" align="start">
              <template #trigger>
                <div
                  class="cursor-pointer text-[10px] font-bold text-n-slate-12 hover:text-n-brand-primary"
                >
                  {{ attr.value }}
                </div>
              </template>
              <template #content>
                <div @click.stop>
                  <SelectMenu
                    :options="attr.options"
                    :value="attr.value"
                    @select="val => onAttributeUpdate(attr, val)"
                  />
                </div>
              </template>
            </Popover>
            <InlineInput
              v-else
              :value="attr.value"
              size="xs"
              class="!text-[10px] !font-bold !p-0 !min-h-0 !border-none !bg-transparent"
              @save="val => onAttributeUpdate(attr, val)"
            />
          </div>
        </div>
      </div>

      <div
        class="mt-1 flex items-center justify-between border-t border-n-slate-2 pt-2 dark:border-n-slate-2"
      >
        <div v-if="viewPrefs.showAssignee" class="flex-1">
          <Popover align="start">
            <template #trigger>
              <div
                class="flex items-center gap-1.5 cursor-pointer hover:bg-n-slate-2 p-1 rounded-lg transition-colors"
                @click.stop
              >
                <Avatar
                  v-if="assignee.id"
                  :src="assignee.thumbnail"
                  :name="assignee.name"
                  :size="18"
                  rounded-full
                />
                <div
                  v-else
                  class="w-[18px] h-[18px] rounded-full border border-dashed border-n-slate-4 flex items-center justify-center"
                >
                  <i class="i-lucide-user text-[10px] text-n-slate-10" />
                </div>
                <span class="truncate text-[10px] font-bold text-n-slate-11">
                  {{ assignee.name || t('CRM.UNASSIGNED') }}
                </span>
              </div>
            </template>
            <template #content>
              <div @click.stop>
                <SelectMenu
                  :options="agentOptions"
                  :value="assignee.id"
                  @select="onAssigneeChange"
                />
              </div>
            </template>
          </Popover>
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
