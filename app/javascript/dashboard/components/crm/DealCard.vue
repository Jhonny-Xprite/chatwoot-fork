<script setup>
import { computed } from 'vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

defineEmits(['select']);

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee);
const labels = computed(() => props.conversation.labels || []);

const lastMessageContent = computed(() => {
  const lastMessage = props.conversation.last_non_activity_message;
  return lastMessage?.content || '';
});

const priorityBadgeClass = computed(() => {
  const priorities = {
    urgent: 'text-red-500 bg-red-50 dark:bg-red-900/20',
    high: 'text-orange-500 bg-orange-50 dark:bg-orange-900/20',
    medium: 'text-blue-500 bg-blue-50 dark:bg-blue-900/20',
    low: 'text-gray-500 bg-gray-50 dark:bg-gray-900/20',
  };
  return `px-1.5 py-0.5 text-[9px] uppercase font-bold rounded ${priorities[props.conversation.priority] || ''}`;
});
</script>

<template>
  <div
    class="p-3 mb-3 bg-white border rounded-lg shadow-sm border-n-weak hover:border-n-brand dark:bg-n-slate-1 transition-colors cursor-grab active:cursor-grabbing"
    @click="$emit('select', conversation)"
  >
    <div class="flex items-center gap-2 mb-2">
      <Avatar :src="contact.thumbnail" :name="contact.name" size="24px" />
      <h3 class="text-sm font-medium text-n-slate-12 truncate flex-1">
        {{ contact.name }}
      </h3>
      <span v-if="conversation.priority" :class="priorityBadgeClass">
        {{ conversation.priority }}
      </span>
    </div>

    <p
      v-if="lastMessageContent"
      class="text-xs text-n-slate-11 mb-3 line-clamp-2"
    >
      {{ lastMessageContent }}
    </p>

    <div v-if="labels.length" class="flex flex-wrap gap-1 mb-3">
      <span
        v-for="label in labels"
        :key="label"
        class="px-2 py-0.5 text-[10px] rounded-full border border-n-weak text-n-slate-11"
      >
        {{ label }}
      </span>
    </div>

    <div class="flex items-center justify-between">
      <span class="text-[10px] text-n-slate-10 uppercase font-medium">
        {{ $t('CRM.DEAL_ID', { id: conversation.id }) }}
      </span>
      <Avatar
        v-if="assignee"
        :src="assignee.thumbnail"
        :name="assignee.name"
        size="20px"
        :title="assignee.name"
      />
    </div>
  </div>
</template>
