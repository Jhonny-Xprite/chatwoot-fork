<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import NextLabel from 'dashboard/components-next/label/Label.vue';
import AddLabel from 'dashboard/components-next/label/AddLabel.vue';
import Popover from 'dashboard/components-next/popover/Popover.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { useAlert } from 'dashboard/composables';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select']);

const store = useStore();
const { t } = useI18n();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee);
const labels = computed(() => props.conversation.labels || []);
const inboxId = computed(() => props.conversation.inbox_id);

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

  // Add "None" option
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

const lastMessageContent = computed(() => {
  const lastMessage = props.conversation.last_non_activity_message;
  return lastMessage?.content || '';
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
    // Update local state for immediate feedback
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
    class="group/card p-4 bg-white dark:bg-n-slate-1 border border-n-weak rounded-xl shadow-sm hover:shadow-md hover:border-n-brand transition-all cursor-grab active:cursor-grabbing flex flex-col gap-3"
    @click="$emit('select', conversation)"
  >
    <!-- Top Row: Avatar & Basic Info -->
    <div class="flex items-start gap-3">
      <Avatar
        :src="contact.thumbnail"
        :name="contact.name"
        size="40px"
        rounded-full
        class="flex-shrink-0"
      />
      <div class="flex-1 min-w-0">
        <div class="flex items-center justify-between gap-2">
          <h3 class="text-sm font-semibold text-n-slate-12 truncate">
            {{ contact.name }}
          </h3>
          <span v-if="conversation.priority" :class="priorityBadgeClass">
            {{ conversation.priority }}
          </span>
        </div>
        <!-- Contact Subtext below name -->
        <div class="flex flex-col gap-0.5 mt-1">
          <div
            v-if="contact.email"
            class="flex items-center gap-1.5 text-[11px] text-n-slate-11 truncate"
          >
            <i class="i-lucide-mail w-3 h-3 flex-shrink-0" />
            <span class="truncate">{{ contact.email }}</span>
          </div>
          <div
            v-if="contact.phone_number"
            class="flex items-center gap-1.5 text-[11px] text-n-slate-11"
          >
            <i class="i-lucide-phone w-3 h-3 flex-shrink-0" />
            <span>{{ contact.phone_number }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Message Snippet -->
    <p
      v-if="lastMessageContent"
      class="text-xs text-n-slate-11 line-clamp-2 italic opacity-80"
    >
      "{{ lastMessageContent }}"
    </p>

    <!-- Labels Row -->
    <div class="flex flex-wrap gap-1 items-center min-h-[24px]">
      <NextLabel
        v-for="label in labels"
        :key="label"
        :label="label"
        compact
        color="slate"
        class="!py-0.5 !px-2"
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
    <div class="h-px bg-n-weak w-full" />

    <!-- Footer: Assignee & Date -->
    <div class="flex items-center justify-between mt-1">
      <Popover @click.stop>
        <template #trigger>
          <button
            class="flex items-center gap-2 px-2 py-1 rounded-lg hover:bg-n-slate-2 dark:hover:bg-n-alpha-2 transition-all group/assignee"
          >
            <Avatar
              v-if="assignee"
              :src="assignee.thumbnail"
              :name="assignee.name"
              size="20px"
              rounded-full
            />
            <div
              v-else
              class="w-5 h-5 rounded-full border border-dashed border-n-slate-6 flex items-center justify-center text-n-slate-8 group-hover/assignee:border-n-brand group-hover/assignee:text-n-brand transition-all"
            >
              <i class="i-lucide-user-plus w-3 h-3" />
            </div>
            <span class="text-[10px] font-medium text-n-slate-11 group-hover/assignee:text-n-slate-12">
              {{ assignee ? assignee.name : t('CONVERSATION_SIDEBAR.SELF_ASSIGN') }}
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

      <span class="text-[10px] text-n-slate-9 font-medium">
        {{ new Date(conversation.created_at).toLocaleDateString() }}
      </span>
    </div>
  </div>
</template>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
