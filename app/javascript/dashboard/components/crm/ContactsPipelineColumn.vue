<script setup>
import { useI18n } from 'vue-i18n';
import ContactPipelineCard from './ContactPipelineCard.vue';
import DealCardSkeleton from './DealCardSkeleton.vue';

defineProps({
  contacts: {
    type: Array,
    default: () => [],
  },
  totalCount: {
    type: Number,
    default: 0,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

defineEmits(['selectContact']);

const { t } = useI18n();
</script>

<template>
  <div
    class="flex h-full w-[340px] flex-shrink-0 flex-col overflow-hidden rounded-3xl border border-n-slate-3 bg-n-slate-2/40 transition-all duration-300 hover:border-n-brand-primary/20 hover:shadow-lg hover:shadow-n-brand-primary/5 dark:border-n-slate-2/50 dark:bg-n-slate-2/10"
  >
    <div class="h-1.5 w-full shrink-0 bg-n-brand-primary opacity-80" />

    <div
      class="flex shrink-0 items-center justify-between border-b border-n-slate-3/50 bg-white/40 px-5 py-4 backdrop-blur-md dark:border-n-slate-2/30 dark:bg-n-slate-1/40"
    >
      <div class="flex min-w-0 items-center gap-3">
        <h3
          class="truncate text-sm font-black uppercase tracking-tight text-n-slate-12"
        >
          {{ t('CRM.CONTACTS_COLUMN.TITLE') }}
        </h3>
        <span
          class="flex h-5 items-center justify-center rounded-full bg-n-slate-2 px-1.5 text-[10px] font-black text-n-slate-11 ring-1 ring-n-slate-3 dark:bg-n-slate-3 dark:ring-n-slate-2"
        >
          {{ totalCount || contacts.length }}
        </span>
      </div>

      <div
        class="flex h-8 w-8 items-center justify-center rounded-xl bg-n-brand-primary/10 text-n-brand-primary"
      >
        <i class="i-lucide-users text-base" />
      </div>
    </div>

    <div class="relative flex min-h-0 flex-1 flex-col">
      <div
        v-if="isLoading"
        class="flex flex-1 flex-col gap-3 overflow-y-auto p-4 custom-scrollbar"
      >
        <DealCardSkeleton v-for="i in 3" :key="i" />
      </div>

      <div
        v-else-if="contacts.length"
        class="flex flex-1 flex-col gap-4 overflow-y-auto p-4 custom-scrollbar"
      >
        <ContactPipelineCard
          v-for="contact in contacts"
          :key="contact.id"
          :contact="contact"
          @select-contact="$emit('selectContact', $event)"
        />
      </div>

      <div
        v-else
        class="absolute inset-0 flex flex-col items-center justify-center p-8 opacity-50"
      >
        <div class="mb-4 rounded-full bg-n-slate-2 p-5 dark:bg-n-slate-3">
          <i class="i-lucide-user-round-search text-3xl text-n-slate-8" />
        </div>
        <p
          class="text-center text-[11px] font-black uppercase tracking-widest text-n-slate-9"
        >
          {{ t('CRM.CONTACTS_COLUMN.EMPTY') }}
        </p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}

.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-4);
  border-radius: 9999px;
}

.custom-scrollbar:hover::-webkit-scrollbar-thumb {
  background: var(--n-slate-6);
}
</style>
