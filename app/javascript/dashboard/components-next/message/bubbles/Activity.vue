<script setup>
import { computed, ref } from 'vue';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

const { content, createdAt } = useMessageContext();
const { t } = useI18n();
const isExpanded = ref(false);

const readableTime = computed(() =>
  messageTimestamp(createdAt.value, 'LLL d, h:mm a')
);

const plainTextContent = computed(() =>
  (content.value || '')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim()
);

const isCollapsible = computed(() => plainTextContent.value.length > 72);

const toggleExpanded = () => {
  if (!isCollapsible.value) {
    return;
  }

  isExpanded.value = !isExpanded.value;
};
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="!rounded-xl"
    data-bubble-name="activity"
  >
    <div
      class="flex min-w-0 items-center gap-2 rounded-xl px-2.5 py-1"
      :class="isExpanded ? 'max-w-[90vw] lg:max-w-2xl' : 'max-w-[360px]'"
    >
      <i class="i-lucide-activity h-3.5 w-3.5 flex-shrink-0 text-n-slate-9" />

      <span
        v-if="!isExpanded"
        class="min-w-0 flex-1 truncate"
        :title="plainTextContent"
      >
        {{ plainTextContent }}
      </span>

      <span
        v-else
        v-dompurify-html="content"
        class="min-w-0 flex-1 break-words normal-case tracking-normal text-n-slate-12"
        :title="plainTextContent"
      />

      <button
        v-if="isCollapsible"
        class="flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full bg-n-slate-3/70 text-n-slate-10 transition-colors hover:bg-n-slate-4 hover:text-n-slate-12"
        :title="
          isExpanded
            ? t('CONVERSATION.ACTIVITY_LOG.COLLAPSE')
            : t('CONVERSATION.ACTIVITY_LOG.EXPAND')
        "
        :aria-label="
          isExpanded
            ? t('CONVERSATION.ACTIVITY_LOG.COLLAPSE')
            : t('CONVERSATION.ACTIVITY_LOG.EXPAND')
        "
        @click.stop="toggleExpanded"
      >
        <i
          :class="
            isExpanded
              ? 'i-lucide-chevron-up h-3 w-3'
              : 'i-lucide-chevron-down h-3 w-3'
          "
        />
      </button>
    </div>
  </BaseBubble>
</template>
