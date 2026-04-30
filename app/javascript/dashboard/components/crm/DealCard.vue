<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextLabel from 'dashboard/components-next/label/Label.vue';
import AddLabel from 'dashboard/components-next/label/AddLabel.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

defineEmits(['select']);

const store = useStore();
const { t } = useI18n();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee);
const labels = computed(() => props.conversation.labels || []);
const inboxId = computed(() => props.conversation.inbox_id);
const unreadCount = computed(() => props.conversation.unread_count || 0);

// Agents list for assignment
const assignableAgents = computed(() => 
  store.getters['inboxAssignableAgents/getAssignableAgents'](inboxId.value) || []
);

const agentMenuItems = computed(() => {
  const items = assignableAgents.value.map(agent => ({
    label: agent.name,
    value: agent.id,
    action: 'assign',
    thumbnail: {
      name: agent.name,
      src: agent.thumbnail,
    },
    isSelected: assignee.value?.id === agent.id,
  }));

  items.unshift({
    label: t('AGENT_MGMT.MULTI_SELECTOR.LIST.NONE'),
    value: 0,
    action: 'assign',
    icon: 'i-lucide-user-minus',
    isSelected: !assignee.value,
  });

  return items;
});

const allLabels = computed(() => store.getters['labels/getLabels']);
const labelMenuItems = computed(() => {
  return allLabels.value.map(label => ({
    id: label.id,
    label: label.title,
    thumbnail: { color: label.color },
    active: labels.value.includes(label.title),
  }));
});

const priorityBadgeClass = computed(() => {
  const priorities = {
    urgent: 'text-red-600 bg-red-50 dark:bg-red-900/20 border-red-100',
    high: 'text-orange-600 bg-orange-50 dark:bg-orange-900/20 border-orange-100',
    medium: 'text-blue-600 bg-blue-50 dark:bg-blue-900/20 border-blue-100',
    low: 'text-gray-600 bg-gray-50 dark:bg-gray-900/20 border-gray-100',
  };
  return `px-1.5 py-0.5 text-[10px] uppercase font-bold rounded border ${priorities[props.conversation.priority] || ''}`;
});

const onAssignAgent = ({ value }) => {
  const agentId = value === 0 ? null : value;
  const agent = assignableAgents.value.find(a => a.id === agentId);

  store.dispatch('assignAgent', {
    conversationId: props.conversation.id,
    agentId,
  }).then(() => {
    useAlert(t('CONVERSATION.CHANGE_AGENT'));
    store.dispatch('crmPipeline/updateConversation', {
      ...props.conversation,
      meta: {
        ...props.conversation.meta,
        assignee: agent || null,
      },
    });
  });
};

const onUpdateLabel = async label => {
  const labelTitle = label.label;
  let newLabels = [...labels.value];
  if (newLabels.includes(labelTitle)) {
    newLabels = newLabels.filter(l => l !== labelTitle);
  } else {
    newLabels.push(labelTitle);
  }

  try {
    await store.dispatch('conversationLabels/update', {
      conversationId: props.conversation.id,
      labels: newLabels,
    });
  } catch (error) {
    // Error
  }
};

const removeLabel = labelTitle => {
  const newLabels = labels.value.filter(l => l !== labelTitle);
  store.dispatch('conversationLabels/update', {
    conversationId: props.conversation.id,
    labels: newLabels,
  });
};
</script>

<template>
  <div
    class="group/card p-4 bg-white dark:bg-n-slate-1 border border-n-weak rounded-xl shadow-sm hover:shadow-md hover:border-n-brand transition-all cursor-grab active:cursor-grabbing flex flex-col gap-3 overflow-hidden"
    @click="$emit('select', conversation)"
  >
    <!-- Top Row: Avatar & Basic Info -->
    <div class="flex items-start gap-3 min-w-0">
      <div class="relative flex-shrink-0 w-12 h-12">
        <Avatar
          :src="contact.thumbnail"
          :name="contact.name"
          size="48px"
          rounded-full
          class="border-2 border-n-weak !w-12 !h-12 flex-shrink-0 object-cover"
        />
        <!-- Unread Notification Badge -->
        <div
          v-if="unreadCount > 0"
          class="absolute -top-1.5 -right-1.5 bg-red-500 text-white text-[10px] font-black h-5 min-w-[20px] px-1 rounded-full flex items-center justify-center border-2 border-white dark:border-n-slate-1 shadow-lg z-10 animate-bounce"
        >
          {{ unreadCount }}
        </div>
      </div>
      <div class="flex-1 min-w-0 py-0.5">
        <div class="flex items-center justify-between gap-2">
          <h3 class="text-sm font-bold text-n-slate-12 truncate leading-tight uppercase tracking-tight">
            {{ contact.name }}
          </h3>
          <span v-if="conversation.priority" :class="priorityBadgeClass">
            {{ conversation.priority }}
          </span>
        </div>
        <!-- Contact Subtext below name (FIXED INFO) -->
        <div class="flex flex-col gap-1 mt-2">
          <div
            v-if="contact.phone_number"
            class="flex items-center gap-1.5 text-[11px] font-bold text-n-slate-11"
          >
            <i class="i-lucide-phone w-3.5 h-3.5 flex-shrink-0 text-n-slate-8" />
            <span class="truncate">{{ contact.phone_number }}</span>
          </div>
          <div
            v-if="contact.email"
            class="flex items-center gap-1.5 text-[11px] text-n-slate-10 truncate"
          >
            <i class="i-lucide-mail w-3.5 h-3.5 flex-shrink-0 text-n-slate-7" />
            <span class="truncate">{{ contact.email }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Fixed ID / Meta -->
    <div v-if="contact.pub_id" class="flex items-center gap-2 px-2 py-1 bg-n-slate-2 rounded border border-n-weak/30">
      <span class="text-[9px] text-n-slate-9 font-mono uppercase tracking-widest">ID: {{ contact.pub_id }}</span>
    </div>

    <!-- Labels Row -->
    <div class="flex flex-wrap gap-1 items-center min-h-[24px] overflow-hidden">
      <NextLabel
        v-for="label in labels"
        :key="label"
        :label="label"
        compact
        color="slate"
        class="!py-0.5 !px-2 max-w-[120px]"
      >
        <template #action>
          <button
            class="hover:text-n-ruby-9 transition-colors ml-1"
            @click.stop="removeLabel(label)"
          >
            <i class="i-lucide-x w-2.5 h-2.5" />
          </button>
        </template>
      </NextLabel>
      <div @click.stop>
        <AddLabel
          :label-menu-items="labelMenuItems"
          class="hover:scale-110 transition-transform"
          @update-label="onUpdateLabel"
        />
      </div>
    </div>

    <!-- Divider -->
    <div class="h-px bg-n-weak w-full opacity-50" />

    <!-- Footer: Assignee & Status -->
    <div class="flex items-center justify-between mt-0.5">
      <Popover @click.stop>
        <template #trigger>
          <button
            class="flex items-center gap-2 px-1.5 py-0.5 rounded-lg hover:bg-n-slate-2 dark:hover:bg-n-alpha-2 transition-all group/assignee"
          >
            <Avatar
              v-if="assignee"
              :src="assignee.thumbnail"
              :name="assignee.name"
              size="18px"
              rounded-full
            />
            <div
              v-else
              class="w-4.5 h-4.5 rounded-full border border-dashed border-n-slate-5 flex items-center justify-center text-n-slate-7 group-hover/assignee:border-n-brand group-hover/assignee:text-n-brand transition-all"
            >
              <i class="i-lucide-user-plus w-2.5 h-2.5" />
            </div>
            <span class="text-[9px] font-bold text-n-slate-10 group-hover/assignee:text-n-brand uppercase tracking-tighter">
              {{ assignee ? assignee.name : 'SEM ATRIBUIÇÃO' }}
            </span>
          </button>
        </template>
        <template #content>
          <DropdownMenu
            :menu-items="agentMenuItems"
            class="!static shadow-2xl min-w-[180px]"
            show-search
            @action="onAssignAgent"
          />
        </template>
      </Popover>

      <div class="flex items-center gap-1.5 opacity-60">
        <div v-if="unreadCount > 0" class="w-1.5 h-1.5 rounded-full bg-red-500 animate-pulse" />
        <span class="text-[9px] text-n-slate-9 font-bold uppercase">
          {{ new Date(conversation.created_at).toLocaleDateString() }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.truncate {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

