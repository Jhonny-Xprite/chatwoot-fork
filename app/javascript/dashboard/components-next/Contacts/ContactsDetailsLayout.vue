<script setup>
import { computed, useSlots, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { vOnClickOutside } from '@vueuse/components';

import Button from 'dashboard/components-next/button/Button.vue';
import Breadcrumb from 'dashboard/components-next/breadcrumb/Breadcrumb.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';

const props = defineProps({
  selectedContact: {
    type: Object,
    default: () => ({}),
  },
  isUpdating: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['goToContactsList', 'toggleBlock']);

const { t } = useI18n();
const slots = useSlots();
const route = useRoute();

const isContactSidebarOpen = ref(false);

const contactId = computed(() => route.params.contactId);

const selectedContactName = computed(() => {
  return props.selectedContact?.name;
});

const breadcrumbItems = computed(() => {
  const items = [
    {
      label: t('CONTACTS_LAYOUT.HEADER.BREADCRUMB.CONTACTS'),
      link: '#',
    },
  ];
  if (props.selectedContact) {
    items.push({
      label: selectedContactName.value,
    });
  }
  return items;
});

const isContactBlocked = computed(() => {
  return props.selectedContact?.blocked;
});

const handleBreadcrumbClick = () => {
  emit('goToContactsList');
};

const toggleBlock = () => {
  emit('toggleBlock', isContactBlocked.value);
};

const handleConversationSidebarToggle = () => {
  isContactSidebarOpen.value = !isContactSidebarOpen.value;
};

const closeMobileSidebar = () => {
  if (!isContactSidebarOpen.value) return;
  isContactSidebarOpen.value = false;
};
</script>

<template>
  <section
    class="flex w-full h-full overflow-hidden justify-evenly bg-immersive"
  >
    <div
      class="flex flex-col w-full h-full transition-all duration-300 ltr:2xl:ml-56 rtl:2xl:mr-56"
    >
      <header
        class="sticky top-0 z-10 px-6 3xl:px-0 bg-white/60 dark:bg-n-slate-1/60 backdrop-blur-xl border-b border-n-slate-3/30 dark:border-n-slate-2/10"
      >
        <div class="w-full mx-auto max-w-[50rem]">
          <div
            class="flex flex-col xs:flex-row items-start xs:items-center justify-between w-full py-5 gap-4"
          >
            <Breadcrumb
              :items="breadcrumbItems"
              class="!text-n-slate-12 font-medium"
              @click="handleBreadcrumbClick"
            />
            <div class="flex items-center gap-3">
              <Button
                :label="
                  !isContactBlocked
                    ? $t('CONTACTS_LAYOUT.HEADER.BLOCK_CONTACT')
                    : $t('CONTACTS_LAYOUT.HEADER.UNBLOCK_CONTACT')
                "
                size="sm"
                variant="ghost"
                color="slate"
                class="!rounded-xl hover:!bg-red-500/10 hover:!text-red-500 transition-all"
                :is-loading="isUpdating"
                :disabled="isUpdating"
                @click="toggleBlock"
              />
              <VoiceCallButton
                :phone="selectedContact?.phoneNumber"
                :contact-id="contactId"
                :label="$t('CONTACT_PANEL.CALL')"
                size="sm"
                class="!rounded-xl"
              />
              <ComposeConversation :contact-id="contactId">
                <template #trigger>
                  <Button
                    :label="$t('CONTACTS_LAYOUT.HEADER.SEND_MESSAGE')"
                    size="sm"
                    variant="solid"
                    color="brand"
                    class="!rounded-xl shadow-lg shadow-n-brand-primary/20"
                  />
                </template>
              </ComposeConversation>
            </div>
          </div>
        </div>
      </header>
      <main class="flex-1 px-6 overflow-y-auto 3xl:px-px custom-scrollbar">
        <div class="w-full py-8 mx-auto max-w-[50rem]">
          <slot name="default" />
        </div>
      </main>
    </div>

    <!-- Desktop sidebar -->
    <div
      v-if="slots.sidebar"
      class="hidden lg:block overflow-y-auto justify-end min-w-52 w-full py-8 max-w-md border-l border-n-slate-3/30 dark:border-n-slate-2/10 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md"
    >
      <slot name="sidebar" />
    </div>

    <!-- Mobile sidebar container -->
    <div
      v-if="slots.sidebar"
      class="lg:hidden fixed top-0 ltr:right-0 rtl:left-0 h-full z-50 flex justify-end transition-all duration-200 ease-in-out"
      :class="isContactSidebarOpen ? 'w-full' : 'w-16'"
    >
      <!-- Toggle button -->
      <div
        v-on-click-outside="[
          closeMobileSidebar,
          { ignore: ['#contact-sidebar-content'] },
        ]"
        class="flex items-start p-2 w-fit h-fit relative order-1 xs:top-24 top-28 transition-all bg-white/80 dark:bg-n-slate-1/80 border border-n-slate-3/30 dark:border-n-slate-2/10 backdrop-blur-xl shadow-2xl duration-500 ease-in-out"
        :class="[
          isContactSidebarOpen
            ? 'justify-end ltr:rounded-l-2xl rtl:rounded-r-2xl ltr:rounded-r-none rtl:rounded-l-none'
            : 'justify-center rounded-2xl ltr:mr-6 rtl:ml-6',
        ]"
      >
        <Button
          variant="ghost"
          color="slate"
          size="sm"
          class="!rounded-full rtl:rotate-180"
          :class="{ 'bg-n-alpha-2': isContactSidebarOpen }"
          :icon="
            isContactSidebarOpen
              ? 'i-lucide-panel-right-close'
              : 'i-lucide-panel-right-open'
          "
          data-contact-sidebar-toggle
          @click="handleConversationSidebarToggle"
        />
      </div>

      <Transition
        enter-active-class="transition-transform duration-300 ease-out"
        leave-active-class="transition-transform duration-200 ease-in"
        enter-from-class="ltr:translate-x-full rtl:-translate-x-full"
        enter-to-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-from-class="ltr:translate-x-0 rtl:-translate-x-0"
        leave-to-class="ltr:translate-x-full rtl:-translate-x-full"
      >
        <div
          v-if="isContactSidebarOpen"
          id="contact-sidebar-content"
          class="order-2 w-[85%] sm:w-[50%] bg-white/95 dark:bg-n-slate-1/95 ltr:border-l rtl:border-r border-n-slate-3/30 dark:border-n-slate-2/10 backdrop-blur-2xl overflow-y-auto py-8 shadow-2xl"
        >
          <slot name="sidebar" />
        </div>
      </Transition>
    </div>
  </section>
</template>

<style scoped>
.bg-immersive {
  background: radial-gradient(
      circle at top left,
      rgba(var(--color-n-brand-primary-rgb), 0.03),
      transparent 40%
    ),
    radial-gradient(
      circle at bottom right,
      rgba(var(--color-n-brand-primary-rgb), 0.02),
      transparent 40%
    ),
    var(--color-n-surface-1);
}

.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--color-n-slate-11-rgb), 0.1);
  border-radius: 10px;
}
.custom-scrollbar::-webkit-scrollbar-thumb:hover {
  background: rgba(var(--color-n-slate-11-rgb), 0.2);
}
</style>
