<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import CardLabels from 'dashboard/components/widgets/conversation/conversationCardComponents/CardLabels.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee || {});
const unreadCount = computed(() => props.conversation.unread_count || 0);

const hasUnread = computed(() => unreadCount.value > 0);

const lastMessageTime = computed(() => {
  const time =
    props.conversation.last_non_activity_message?.created_at ||
    props.conversation.updated_at;
  if (!time) return '';
  return new Date(time * 1000).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });
});

const labels = computed(() => props.conversation.labels || []);
</script>

<template>
  <div
    class="group relative bg-white dark:bg-slate-800 rounded-xl p-3 border border-slate-200/60 dark:border-slate-700/60 hover:border-blue-400/50 dark:hover:border-blue-500/50 hover:shadow-lg hover:shadow-blue-500/5 transition-all cursor-grab active:cursor-grabbing select-none"
  >
    <!-- Unread Pulse Badge -->
    <div v-if="hasUnread" class="absolute -top-1 -right-1 flex h-4 w-4">
      <span
        class="animate-ping absolute inline-flex h-full w-full rounded-full bg-blue-400 opacity-75"
      />
      <span
        class="relative inline-flex rounded-full h-4 w-4 bg-blue-500 text-[9px] font-bold text-white items-center justify-center"
      >
        {{ unreadCount }}
      </span>
    </div>

    <div class="flex flex-col gap-3">
      <!-- Header: Avatar + Main Info -->
      <div class="flex items-start gap-3">
        <Avatar
          :src="contact.thumbnail"
          :name="contact.name || t('CRM.UNKNOWN_CONTACT')"
          :size="40"
          class="shadow-sm"
        />
        <div class="flex-1 min-w-0">
          <div class="flex items-center justify-between gap-1">
            <h4
              class="text-[13px] font-bold text-slate-800 dark:text-slate-100 truncate group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors"
            >
              {{ contact.name || t('CRM.UNKNOWN_CONTACT') }}
            </h4>
            <span
              class="text-[10px] font-medium text-slate-400 whitespace-nowrap"
            >
              {{ lastMessageTime }}
            </span>
          </div>
          <p
            class="text-[11px] text-slate-500 dark:text-slate-400 truncate mt-0.5 font-medium"
          >
            {{ contact.email || contact.phone_number || t('CRM.PHONE') }}
          </p>
        </div>
      </div>

      <!-- Mid: Labels -->
      <div v-if="labels.length" class="flex flex-wrap gap-1 mt-1">
        <CardLabels :conversation-labels="labels" />
      </div>

      <!-- Footer: Meta Info -->
      <div
        class="flex items-center justify-between pt-2 mt-1 border-t border-slate-100/50 dark:border-slate-700/50"
      >
        <div class="flex items-center gap-1.5 overflow-hidden">
          <Avatar
            v-if="assignee.id"
            :src="assignee.thumbnail"
            :name="assignee.name"
            :size="18"
            rounded-full
          />
          <span
            class="text-[10px] font-bold text-slate-500 dark:text-slate-400 truncate"
          >
            {{ assignee.name || t('CRM.UNASSIGNED') }}
          </span>
        </div>

        <div class="flex items-center gap-1">
          <span
            class="text-[10px] font-black text-slate-300 dark:text-slate-600 uppercase tracking-tight"
          >
            {{ t('CRM.DEAL_ID', { id: conversation.id }) }}
          </span>
          <span
            class="i-lucide-grip-vertical text-slate-300 dark:text-slate-600 opacity-0 group-hover:opacity-100 transition-opacity"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Smooth entrance for the card */
@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(5px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

div {
  animation: fadeIn 0.2s ease-out;
}
</style>
