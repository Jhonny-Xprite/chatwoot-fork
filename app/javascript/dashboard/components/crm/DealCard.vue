<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardPriorityIcon from 'dashboard/components-next/Conversation/ConversationCard/CardPriorityIcon.vue';
import SLACardLabel from 'dashboard/components-next/Conversation/Sla/SLACardLabel.vue';

import Button from 'dashboard/components-next/button/Button.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import SelectMenu from 'dashboard/components-next/selectmenu/SelectMenu.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
  isDragging: {
    type: Boolean,
    default: false,
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
const accountLabels = computed(() => store.getters['labels/getLabels']);
const conversationLabels = computed(() => {
  const labels = props.conversation.labels || [];
  return labels.map(label => (typeof label === 'string' ? label : label.title));
});
const activeLabels = computed(() => {
  return accountLabels.value.filter(label =>
    conversationLabels.value.includes(label.title)
  );
});
const hasSlaPolicyId = computed(() => props.conversation?.sla_policy_id);
const companyName = computed(
  () => contact.value.additional_attributes?.company_name || ''
);

const inbox = computed(
  () => store.getters['inboxes/getInbox'](props.conversation.inbox_id) || {}
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

const showReplyNeeded = computed(
  () => hasUnread.value || lastMessage.value?.message_type === 0
);

// --- Restored Interactive Functions ---

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

const onStartConversation = () => {
  emit('select', props.conversation);
};

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
      if (!value) return null;
      return { label: definition.attribute_display_name, value };
    })
    .filter(Boolean);
});
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative flex flex-col gap-3 cursor-pointer select-none rounded-2xl border border-n-slate-3 bg-white p-4 shadow-sm transition-all duration-300 hover:border-n-brand-primary/40 hover:shadow-2xl hover:shadow-n-brand-primary/10 dark:border-n-slate-2 dark:bg-n-slate-1 overflow-hidden"
    :class="[
      isHotLead
        ? 'ring-1 ring-n-brand-primary/20 bg-gradient-to-br from-white to-n-brand-primary-alpha-1/10'
        : '',
      showReplyNeeded ? 'border-n-brand-primary/30' : '',
      isDragging ? 'is-dragging' : 'hover:-translate-y-1.5',
    ]"
    @click="emit('select', conversation)"
  >
    <!-- Premium Backdrop Glow (Hover only) -->
    <div
      class="absolute inset-0 bg-gradient-to-tr from-n-brand-primary/0 via-n-brand-primary/0 to-n-brand-primary/5 opacity-0 transition-opacity group-hover:opacity-100"
    />

    <!-- Top: Priority, ID & Indicators -->
    <div class="flex items-center justify-between gap-2 relative z-10">
      <div class="flex items-center gap-2">
        <Popover v-if="viewPrefs.showPriority" @click.stop>
          <template #trigger>
            <div
              class="flex items-center justify-center rounded-full p-1 transition-colors hover:bg-n-slate-3 dark:hover:bg-n-slate-2"
              :class="
                conversation.priority ? 'bg-n-slate-2 dark:bg-n-slate-3' : ''
              "
            >
              <CardPriorityIcon :priority="conversation.priority || 'none'" />
            </div>
          </template>
          <template #content>
            <div class="p-1 min-w-[140px]">
              <div
                v-for="option in priorityOptions"
                :key="option.value"
                class="flex items-center gap-2 px-3 py-2 rounded-lg cursor-pointer hover:bg-n-slate-2 text-[12px] font-bold transition-colors"
                @click="onPriorityChange(option.value)"
              >
                <i :class="[option.icon, option.color]" />
                <span class="text-n-slate-11">{{ option.label }}</span>
              </div>
            </div>
          </template>
        </Popover>
        <span
          class="text-[10px] font-black uppercase tracking-widest text-n-slate-8"
        >
          {{ `#${conversation.id}` }}
          <template v-if="inboxName && viewPrefs.showChannel">
            <span class="mx-1.5 opacity-30">
              {{ '|' }}
            </span>
            <span class="text-n-slate-10">{{ inboxName }}</span>
          </template>
        </span>
      </div>

      <div class="flex items-center gap-1.5">
        <SLACardLabel
          v-if="hasSlaPolicyId && viewPrefs.showSla"
          :chat="conversation"
        />
        <div v-if="hasUnread" class="flex h-5 w-5 animate-bounce">
          <span
            class="inline-flex h-full w-full items-center justify-center rounded-full bg-n-brand-primary text-[10px] font-black text-white shadow-lg shadow-n-brand-primary/40"
          >
            {{ unreadCount }}
          </span>
        </div>
      </div>
    </div>

    <!-- Contact Info: Layout Liquid -->
    <div class="flex items-center gap-3.5 relative z-10">
      <div class="relative">
        <Avatar
          :src="contact.thumbnail"
          :name="contact.name || t('CRM.UNKNOWN_CONTACT')"
          :size="44"
          class="shrink-0 shadow-lg ring-2 ring-white dark:ring-n-slate-2 transition-transform group-hover:scale-105"
        />
        <div
          v-if="leadScore > 0"
          class="absolute -bottom-1 -right-1 flex h-4 w-4 items-center justify-center rounded-full bg-n-amber-9 text-[8px] font-black text-white shadow-sm ring-1 ring-white"
        >
          <i class="i-lucide-flame scale-75" />
        </div>
      </div>

      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-2">
          <h4
            class="truncate text-[15px] font-extrabold text-n-slate-12 tracking-tight group-hover:text-n-brand-primary transition-colors"
          >
            {{ contact.name || t('CRM.UNKNOWN_CONTACT') }}
          </h4>
          <button
            v-tooltip.top="t('CONVERSATION.NEW_MESSAGE')"
            class="p-1 rounded-md hover:bg-n-brand-primary/10 text-n-slate-8 hover:text-n-brand-primary transition-all active:scale-90"
            @click.stop="onStartConversation"
          >
            <i class="i-lucide-message-square size-3.5" />
          </button>
        </div>
        <div class="flex items-center gap-1.5 text-n-slate-10">
          <span class="truncate text-[11px] font-semibold opacity-80">
            {{ contact.phone_number || contact.email || t('CRM.PHONE') }}
          </span>
        </div>
      </div>
    </div>

    <!-- Company Meta -->
    <div
      v-if="companyName && viewPrefs.showCompanyName"
      class="flex flex-wrap items-center gap-3 relative z-10"
    >
      <div
        class="flex items-center gap-1.5 rounded-md bg-n-slate-2/50 px-2 py-0.5 text-[10px] font-bold text-n-slate-11"
      >
        <i class="i-lucide-building-2 opacity-70" />
        <span class="truncate max-w-[120px]">{{ companyName }}</span>
      </div>
    </div>

    <!-- Custom Attributes -->
    <div
      v-if="dynamicAttributes.length"
      class="flex flex-wrap gap-2 relative z-10"
    >
      <div
        v-for="attr in dynamicAttributes"
        :key="attr.label"
        class="flex items-center gap-1 text-[10px] font-bold"
      >
        <span class="text-n-slate-8">{{ attr.label }}:</span>
        <span class="text-n-slate-11">{{ attr.value }}</span>
      </div>
    </div>

    <!-- Tags / Labels -->
    <div v-if="activeLabels.length" class="flex flex-wrap gap-1 relative z-10">
      <div
        v-for="label in activeLabels"
        :key="label.id"
        class="flex items-center gap-1 px-1.5 py-0.5 rounded-md bg-n-alpha-1 border border-n-strong/20"
      >
        <div
          class="size-1.5 rounded-full"
          :style="{ backgroundColor: label.color }"
        />
        <span
          class="text-[10px] font-bold text-n-slate-11 uppercase tracking-tighter"
        >
          {{ label.title }}
        </span>
      </div>
    </div>

    <!-- Premium Message Preview (Glass Style) -->
    <div
      v-if="viewPrefs.showLastMessage && lastMessage"
      class="relative mt-0.5 rounded-xl border border-n-slate-2/60 bg-n-slate-2/30 p-3 text-[12px] leading-relaxed text-n-slate-11 transition-all group-hover:bg-white/80 dark:group-hover:bg-n-slate-2/80 group-hover:shadow-inner"
    >
      <div class="mb-1 flex items-center gap-2">
        <span
          class="text-[9px] font-black uppercase tracking-widest"
          :class="
            lastMessage?.message_type === 1
              ? 'text-n-slate-9'
              : 'text-n-brand-primary'
          "
        >
          {{ lastMessageSenderLabel }}
        </span>
        <div class="h-1 w-1 rounded-full bg-n-slate-4" />
      </div>
      <p class="line-clamp-2 italic opacity-90">
        {{ lastMessagePreview }}
      </p>
    </div>

    <!-- Footer: Team & Dynamic Actions -->
    <div
      class="mt-1 flex items-center justify-between border-t border-n-slate-2 pt-3.5 relative z-10"
    >
      <div class="flex items-center gap-2">
        <SelectMenu
          v-model="assignee.id"
          :options="agentOptions"
          class="shrink-0"
          @click.stop
          @update:model-value="onAssigneeChange"
        >
          <template #trigger>
            <div class="relative cursor-pointer group/avatar">
              <Avatar
                v-if="assignee.id"
                :src="assignee.thumbnail"
                :name="assignee.name"
                :size="26"
                class="ring-2 ring-white dark:ring-n-slate-1 shadow-sm transition-transform group-hover/avatar:scale-110"
              />
              <div
                v-else
                class="flex h-6.5 w-6.5 items-center justify-center rounded-full border-2 border-dashed border-n-slate-3 bg-n-slate-1/50 transition-colors group-hover:border-n-brand-primary/40"
              >
                <i class="i-lucide-user-plus text-[10px] text-n-slate-8" />
              </div>
            </div>
          </template>
        </SelectMenu>
        <span
          class="text-[11px] font-black text-n-slate-10 truncate max-w-[80px] tracking-tight"
        >
          {{ assignee.name || t('CRM.UNASSIGNED') }}
        </span>
      </div>

      <div class="flex items-center gap-1.5">
        <Button
          variant="ghost"
          color="slate"
          size="xs"
          class="!h-8 !w-8 !p-0 rounded-xl opacity-0 group-hover:opacity-100 transition-all hover:bg-n-slate-2"
          @click.stop="emit('selectContact', conversation)"
        >
          <i class="i-lucide-user text-base" />
        </Button>
        <Button
          variant="solid"
          color="brand"
          size="xs"
          class="!h-8 px-3 rounded-xl opacity-0 group-hover:opacity-100 transition-all shadow-lg shadow-n-brand-primary/20 translate-x-2 group-hover:translate-x-0"
          @click.stop="emit('select', conversation)"
        >
          <i class="i-lucide-message-square text-sm ltr:mr-1.5 rtl:ml-1.5" />
          <span class="text-[10px] font-black uppercase tracking-tighter">{{
            t('CRM.OPEN')
          }}</span>
        </Button>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Spring Animation for Premium Feel */
.group {
  transition: all 0.5s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.group:hover {
  transform: translateY(-6px) scale(1.01);
}

/* Glassmorphism for Apple Theme */
:global(.apple-theme) .group {
  background: var(--glass-bg);
  backdrop-filter: blur(12px);
  border-color: rgba(255, 255, 255, 0.1);
}

/* High-Tech Borders for Linear Theme */
:global(.linear-theme) .group {
  border-radius: 8px;
  background: #0c0c0e;
  border-color: #1d1d20;
}
</style>
