<script setup>
import { computed } from 'vue';

import MessageMeta from '../MessageMeta.vue';

import { emitter } from 'shared/helpers/mitt';
import { useMessageContext } from '../provider.js';
import { useI18n } from 'vue-i18n';

import MessageFormatter from 'shared/helpers/MessageFormatter.js';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { MESSAGE_VARIANTS, ORIENTATION } from '../constants';

const props = defineProps({
  hideMeta: { type: Boolean, default: false },
});

const { variant, orientation, inReplyTo, shouldGroupWithNext } =
  useMessageContext();
const { t } = useI18n();

const variantBaseMap = {
  [MESSAGE_VARIANTS.AGENT]:
    'bg-gradient-to-br from-n-brand-primary to-n-brand-primary-alt text-white shadow-lg shadow-n-brand-primary/10',
  [MESSAGE_VARIANTS.PRIVATE]:
    'bg-n-solid-amber/10 dark:bg-n-solid-amber/20 border border-n-solid-amber/30 text-n-amber-12 [&_.prosemirror-mention-node]:font-semibold backdrop-blur-sm',
  [MESSAGE_VARIANTS.USER]:
    'bg-white/70 dark:bg-n-slate-3/40 backdrop-blur-md border border-white/20 dark:border-n-slate-2/10 text-n-slate-12 shadow-sm',
  [MESSAGE_VARIANTS.ACTIVITY]:
    'bg-n-slate-2/35 dark:bg-n-slate-1/35 text-n-slate-10 text-[10px] font-medium tracking-wide border border-n-slate-3/30 dark:border-n-slate-2/20',
  [MESSAGE_VARIANTS.BOT]:
    'bg-gradient-to-br from-n-solid-iris to-n-solid-iris-alt text-white shadow-lg shadow-n-solid-iris/10',
  [MESSAGE_VARIANTS.TEMPLATE]:
    'bg-gradient-to-br from-n-solid-iris to-n-solid-iris-alt text-white shadow-lg shadow-n-solid-iris/10',
  [MESSAGE_VARIANTS.ERROR]: 'bg-n-ruby-4 text-n-ruby-12 border border-n-ruby-5',
  [MESSAGE_VARIANTS.EMAIL]:
    'w-full bg-white/50 dark:bg-n-slate-1/50 backdrop-blur-md border border-n-slate-3/30 dark:border-n-slate-2/10',
  [MESSAGE_VARIANTS.UNSUPPORTED]:
    'bg-n-solid-amber/10 border border-dashed border-n-amber-5 text-n-amber-11 backdrop-blur-sm',
};

const orientationMap = {
  [ORIENTATION.LEFT]:
    'left-bubble rounded-2xl ltr:rounded-bl-md rtl:rounded-br-md',
  [ORIENTATION.RIGHT]:
    'right-bubble rounded-2xl ltr:rounded-br-md rtl:rounded-bl-md',
  [ORIENTATION.CENTER]: 'rounded-xl',
};

const flexOrientationClass = computed(() => {
  const map = {
    [ORIENTATION.LEFT]: 'justify-start',
    [ORIENTATION.RIGHT]: 'justify-end',
    [ORIENTATION.CENTER]: 'justify-center',
  };

  return map[orientation.value];
});

const messageClass = computed(() => {
  const classToApply = [variantBaseMap[variant.value]];

  if (variant.value !== MESSAGE_VARIANTS.ACTIVITY) {
    classToApply.push(orientationMap[orientation.value]);
  } else {
    classToApply.push('rounded-xl mx-auto my-2');
  }

  return classToApply;
});

const scrollToMessage = () => {
  emitter.emit(BUS_EVENTS.SCROLL_TO_MESSAGE, {
    messageId: inReplyTo.value.id,
  });
};

const shouldShowMeta = computed(
  () =>
    !props.hideMeta &&
    !shouldGroupWithNext.value &&
    variant.value !== MESSAGE_VARIANTS.ACTIVITY
);

const translateAttachmentPreview = fileType => {
  switch (fileType) {
    case 'image':
      return t('CHAT_LIST.ATTACHMENTS.image.CONTENT');
    case 'audio':
      return t('CHAT_LIST.ATTACHMENTS.audio.CONTENT');
    case 'video':
      return t('CHAT_LIST.ATTACHMENTS.video.CONTENT');
    case 'file':
      return t('CHAT_LIST.ATTACHMENTS.file.CONTENT');
    case 'fallback':
      return t('CHAT_LIST.ATTACHMENTS.fallback.CONTENT');
    case 'location':
      return t('CHAT_LIST.ATTACHMENTS.location.CONTENT');
    case 'share':
      return t('CHAT_LIST.ATTACHMENTS.share.CONTENT');
    case 'story_mention':
      return t('CHAT_LIST.ATTACHMENTS.story_mention.CONTENT');
    case 'contact':
      return t('CHAT_LIST.ATTACHMENTS.contact.CONTENT');
    case 'ig_reel':
      return t('CHAT_LIST.ATTACHMENTS.ig_reel.CONTENT');
    default:
      return t('CHAT_LIST.NO_CONTENT');
  }
};

const replyToPreview = computed(() => {
  if (!inReplyTo) return '';

  const { content, attachments } = inReplyTo.value;

  if (content) return new MessageFormatter(content).formattedMessage;
  if (attachments?.length) {
    const firstAttachment = attachments[0];
    const fileType = firstAttachment.fileType ?? firstAttachment.file_type;

    return translateAttachmentPreview(fileType);
  }

  return t('CONVERSATION.REPLY_MESSAGE_NOT_FOUND');
});
</script>

<template>
  <div
    class="text-sm transition-all duration-300"
    :class="[
      messageClass,
      {
        'max-w-[85%] lg:max-w-lg': variant !== MESSAGE_VARIANTS.EMAIL,
        'mb-1': shouldGroupWithNext,
        'mb-4': !shouldGroupWithNext,
      },
    ]"
  >
    <div
      v-if="inReplyTo"
      class="p-2.5 mx-1 mt-1 mb-2 rounded-xl cursor-pointer bg-black/5 dark:bg-white/5 border-l-2 border-n-brand-primary"
      @click="scrollToMessage"
    >
      <div
        v-dompurify-html="replyToPreview"
        class="prose prose-bubble line-clamp-2 text-xs opacity-70"
      />
    </div>
    <div class="px-4 py-3">
      <slot />
    </div>
    <MessageMeta
      v-if="shouldShowMeta"
      :class="[
        flexOrientationClass,
        variant === MESSAGE_VARIANTS.EMAIL ? 'px-4 pb-4' : 'px-4 pb-2',
        variant === MESSAGE_VARIANTS.PRIVATE
          ? 'text-n-amber-12/60'
          : variant === MESSAGE_VARIANTS.AGENT ||
              variant === MESSAGE_VARIANTS.BOT ||
              variant === MESSAGE_VARIANTS.TEMPLATE
            ? 'text-white/70'
            : 'text-n-slate-11',
      ]"
      class="-mt-1"
    />
  </div>
</template>

<style scoped>
.left-bubble {
  border-bottom-left-radius: 4px !important;
}
.right-bubble {
  border-bottom-right-radius: 4px !important;
}
</style>
