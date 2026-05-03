<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { dynamicTime, shortTimestamp } from 'shared/helpers/timeHelper';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['selectContact']);

const { t } = useI18n();

const leadScore = computed(
  () => props.contact.leadScore ?? props.contact.lead_score ?? 0
);
const hasConversationStarted = computed(() =>
  Boolean(props.contact.lastActivityAt)
);
const companyName = computed(
  () => props.contact.additionalAttributes?.companyName || ''
);
const lastActivityLabel = computed(() => {
  if (!hasConversationStarted.value) {
    return t('CRM.CONTACTS_COLUMN.NOT_STARTED');
  }

  return shortTimestamp(dynamicTime(props.contact.lastActivityAt), true);
});

const scoreClasses = computed(() => {
  if (leadScore.value >= 70) {
    return 'bg-n-ruby-9/10 text-n-ruby-11 border-n-ruby-9/20';
  }

  if (leadScore.value >= 40) {
    return 'bg-n-amber-9/10 text-n-amber-11 border-n-amber-9/20';
  }

  return 'bg-n-teal-9/10 text-n-teal-11 border-n-teal-9/20';
});

const openContact = () => {
  emit('selectContact', props.contact);
};
</script>

<template>
  <div
    role="button"
    tabindex="0"
    class="group relative flex-shrink-0 overflow-hidden rounded-2xl border border-n-slate-3 bg-white p-4 shadow-sm transition-all duration-200 hover:border-n-brand-primary/30 hover:shadow-lg hover:shadow-n-brand-primary/5 dark:border-n-slate-2 dark:bg-n-slate-1"
    @click="openContact"
  >
    <div
      class="absolute inset-0 bg-gradient-to-tr from-n-brand-primary/0 via-n-brand-primary/0 to-n-brand-primary/5 opacity-0 transition-opacity group-hover:opacity-100"
    />

    <div class="relative z-10 flex items-start gap-3.5">
      <Avatar
        :src="contact.thumbnail"
        :name="contact.name || t('CRM.UNKNOWN_CONTACT')"
        :size="42"
        class="shrink-0 ring-2 ring-white shadow-sm dark:ring-n-slate-2"
      />

      <div class="min-w-0 flex-1">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <h4
              class="truncate text-sm font-extrabold tracking-tight text-n-slate-12 transition-colors group-hover:text-n-brand-primary"
            >
              {{ contact.name || t('CRM.UNKNOWN_CONTACT') }}
            </h4>
            <p class="mt-0.5 truncate text-[11px] font-medium text-n-slate-10">
              {{ contact.phoneNumber || contact.email || t('CRM.PHONE') }}
            </p>
          </div>

          <div
            class="inline-flex items-center rounded-full border px-2 py-1 text-[10px] font-black"
            :class="scoreClasses"
          >
            {{ `#${leadScore}` }}
          </div>
        </div>

        <div
          v-if="companyName"
          class="mt-2 inline-flex max-w-full items-center gap-1.5 rounded-md bg-n-slate-2/60 px-2 py-1 text-[10px] font-bold text-n-slate-11"
        >
          <i class="i-lucide-building-2 opacity-70" />
          <span class="truncate">{{ companyName }}</span>
        </div>

        <div class="mt-3 flex items-center gap-2">
          <span
            class="inline-flex items-center rounded-full px-2 py-1 text-[10px] font-black uppercase tracking-wider"
            :class="
              hasConversationStarted
                ? 'bg-n-brand-primary/10 text-n-brand-primary'
                : 'bg-n-slate-2 text-n-slate-10'
            "
          >
            {{
              hasConversationStarted
                ? t('CRM.CONTACTS_COLUMN.STARTED')
                : t('CRM.CONTACTS_COLUMN.NOT_STARTED')
            }}
          </span>
          <span
            v-if="hasConversationStarted"
            class="text-[10px] font-bold uppercase tracking-wide text-n-slate-9"
          >
            {{ lastActivityLabel }}
          </span>
        </div>
      </div>
    </div>

    <div class="relative z-10 mt-4 flex items-center justify-between gap-2">
      <span
        class="text-[10px] font-bold uppercase tracking-wider text-n-slate-9"
      >
        {{ t('CRM.CONTACTS_COLUMN.LAST_ACTIVITY') }}
      </span>

      <div class="flex items-center gap-2">
        <Button
          variant="ghost"
          color="slate"
          size="xs"
          class="!h-8 !w-8 !p-0 rounded-xl opacity-0 transition-all group-hover:opacity-100"
          @click.stop="openContact"
        >
          <i class="i-lucide-user text-base" />
        </Button>
        <Button
          variant="solid"
          color="blue"
          size="xs"
          class="!h-8 px-3 rounded-xl opacity-0 transition-all group-hover:opacity-100"
          @click.stop="openContact"
        >
          <i class="i-lucide-message-square text-sm ltr:mr-1.5 rtl:ml-1.5" />
          <span class="text-[10px] font-black uppercase tracking-wider">
            {{ t('CRM.OPEN_CONTACT') }}
          </span>
        </Button>
      </div>
    </div>
  </div>
</template>
