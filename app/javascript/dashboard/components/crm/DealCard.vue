<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['select', 'selectContact']);

const { t } = useI18n();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee || {});
const unreadCount = computed(() => props.conversation.unread_count || 0);
const labels = computed(() => props.conversation.labels || []);
const companyName = computed(
  () => contact.value.additional_attributes?.company_name || ''
);
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

  return new Date(time * 1000).toLocaleTimeString([], {
    hour: '2-digit',
    minute: '2-digit',
  });
});

const lastMessagePreview = computed(() => {
  if (lastMessage.value?.content) {
    return lastMessage.value.content;
  }

  return t('CRM.NO_MESSAGES_YET');
});
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative bg-n-alpha-3 dark:bg-n-slate-1 rounded-xl p-3 border border-n-slate-3 dark:border-n-slate-2 hover:border-n-brand-primary/50 dark:hover:border-n-brand-primary/50 hover:shadow-lg hover:shadow-n-brand-primary/10 hover:-translate-y-0.5 transition-all duration-300 spring-motion cursor-grab active:cursor-grabbing select-none"
    @click="emit('select', conversation)"
    @keydown.enter.prevent="emit('select', conversation)"
    @keydown.space.prevent="emit('select', conversation)"
  >
    <div
      v-if="hasUnread"
      class="absolute -top-1 -right-1 flex h-4 w-4 spring-pop"
    >
      <span
        class="animate-ping-subtle absolute inline-flex h-full w-full rounded-full bg-n-brand-primary/30 opacity-75"
      />
      <span
        class="relative inline-flex rounded-full h-4 w-4 bg-n-brand-primary text-[9px] font-bold text-n-white items-center justify-center shadow-sm"
      >
        {{ unreadCount }}
      </span>
    </div>

    <div class="flex flex-col gap-3">
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
              class="text-[13px] font-bold text-n-slate-12 truncate group-hover:text-n-brand-primary transition-colors"
            >
              {{ contact.name || t('CRM.UNKNOWN_CONTACT') }}
            </h4>
            <span
              class="text-[10px] font-medium text-n-slate-10 whitespace-nowrap"
            >
              {{ lastMessageTime }}
            </span>
          </div>
          <p class="text-[11px] text-n-slate-11 truncate mt-0.5 font-medium">
            {{ contact.email || contact.phone_number || t('CRM.PHONE') }}
          </p>
          <p
            v-if="companyName"
            class="text-[10px] font-semibold text-n-slate-10 truncate mt-1"
          >
            {{ companyName }}
          </p>
        </div>
      </div>

      <div v-if="labels.length" class="flex flex-wrap gap-1 mt-1">
        <span
          v-for="label in labels"
          :key="label"
          class="inline-flex max-w-full truncate rounded-full bg-n-slate-2 px-2 py-0.5 text-[10px] font-semibold text-n-slate-11"
        >
          {{ label }}
        </span>
      </div>

      <div
        class="rounded-xl border px-2.5 py-2 text-[11px] leading-4"
        :class="
          showReplyNeeded
            ? 'border-n-brand-primary/30 bg-n-brand-primary-alpha-1 text-n-slate-12'
            : 'border-n-slate-2 bg-n-alpha-2 text-n-slate-11'
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
        class="flex items-center justify-between pt-2 mt-1 border-t border-n-slate-2 dark:border-n-slate-2"
      >
        <div class="flex items-center gap-1.5 overflow-hidden">
          <Avatar
            v-if="assignee.id"
            :src="assignee.thumbnail"
            :name="assignee.name"
            :size="18"
            rounded-full
          />
          <span class="text-[10px] font-bold text-n-slate-11 truncate">
            {{ assignee.name || t('CRM.UNASSIGNED') }}
          </span>
        </div>

        <div class="flex items-center gap-1">
          <button
            v-if="contact.id"
            type="button"
            class="rounded-md px-2 py-1 text-[10px] font-semibold text-n-slate-11 hover:bg-n-slate-2"
            @click.stop="emit('selectContact', conversation)"
          >
            {{ t('CRM.OPEN_CONTACT') }}
          </button>
          <button
            type="button"
            class="rounded-md px-2 py-1 text-[10px] font-semibold text-n-brand-primary hover:bg-n-brand-primary-alpha-1"
            @click.stop="emit('select', conversation)"
          >
            {{ t('CRM.OPEN_CONVERSATION') }}
          </button>
        </div>
      </div>

      <div class="flex items-center justify-between">
        <span
          class="text-[10px] font-black text-n-slate-8 dark:text-n-slate-9 uppercase tracking-tight"
        >
          {{ t('CRM.DEAL_ID', { id: conversation.id }) }}
        </span>
        <span
          class="i-lucide-grip-vertical text-n-slate-8 dark:text-n-slate-9 opacity-0 group-hover:opacity-100 transition-opacity"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.spring-motion {
  transition-timing-function: cubic-bezier(0.34, 1.56, 0.64, 1);
}

.spring-pop {
  animation: spring-pop 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275) both;
}

@keyframes spring-pop {
  0% {
    transform: scale(0.5);
    opacity: 0;
  }
  100% {
    transform: scale(1);
    opacity: 1;
  }
}

@keyframes ping-subtle {
  75%,
  100% {
    transform: scale(1.4);
    opacity: 0;
  }
}

.animate-ping-subtle {
  animation: ping-subtle 2s cubic-bezier(0, 0, 0.2, 1) infinite;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

div {
  animation: fadeIn 0.4s cubic-bezier(0.34, 1.56, 0.64, 1) both;
}
</style>
