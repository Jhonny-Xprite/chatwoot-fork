<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';

import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import LabelActions from 'dashboard/components/widgets/conversation/conversationBulkActions/LabelActions.vue';
import Policy from 'dashboard/components/policy.vue';

const props = defineProps({
  visibleContactIds: {
    type: Array,
    default: () => [],
  },
  selectedContactIds: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'clearSelection',
  'assignLabels',
  'toggleAll',
  'deleteSelected',
]);

const { t } = useI18n();

const selectedCount = computed(() => props.selectedContactIds.length);
const totalVisibleContacts = computed(() => props.visibleContactIds.length);
const showLabelSelector = ref(false);

const selectAllLabel = computed(() => {
  if (!totalVisibleContacts.value) {
    return '';
  }

  return t('CONTACTS_BULK_ACTIONS.SELECT_ALL', {
    count: totalVisibleContacts.value,
  });
});

const selectedCountLabel = computed(() =>
  t('CONTACTS_BULK_ACTIONS.SELECTED_COUNT', {
    count: selectedCount.value,
  })
);

const allItems = computed(() =>
  props.visibleContactIds.map(id => ({
    id,
  }))
);

const selectionModel = computed({
  get: () => new Set(props.selectedContactIds),
  set: newSet => {
    if (!props.visibleContactIds.length) {
      emit('toggleAll', false);
      return;
    }

    const shouldSelectAll = props.visibleContactIds.every(id => newSet.has(id));
    emit('toggleAll', shouldSelectAll);
  },
});

const emitClearSelection = () => {
  showLabelSelector.value = false;
  emit('clearSelection');
};

const toggleLabelSelector = () => {
  if (!selectedCount.value || props.isLoading) return;
  showLabelSelector.value = !showLabelSelector.value;
};

const closeLabelSelector = () => {
  showLabelSelector.value = false;
};

const handleAssignLabels = labels => {
  emit('assignLabels', labels);
  closeLabelSelector();
};
</script>

<template>
  <div
    class="sticky top-4 z-40 mx-auto w-full max-w-2xl px-4 pointer-events-none"
  >
    <div class="pointer-events-auto">
      <BulkSelectBar
        v-model="selectionModel"
        :all-items="allItems"
        :select-all-label="selectAllLabel"
        :selected-count-label="selectedCountLabel"
        class="premium-bulk-bar py-3 px-5 justify-between rounded-2xl border border-n-brand-primary/20 bg-white/60 dark:bg-n-slate-1/60 backdrop-blur-xl shadow-2xl shadow-n-brand-primary/10"
      >
        <template #secondary-actions>
          <Button
            variant="ghost"
            color="slate"
            size="sm"
            :label="t('CONTACTS_BULK_ACTIONS.CLEAR_SELECTION')"
            class="!px-3 !rounded-xl hover:!bg-n-slate-2 dark:hover:!bg-n-slate-2/50"
            @click="emitClearSelection"
          />
        </template>
        <template #actions>
          <div class="flex items-center gap-3 ml-auto">
            <div
              v-on-click-outside="closeLabelSelector"
              class="relative flex items-center"
            >
              <Button
                variant="faded"
                color="brand"
                size="sm"
                icon="i-lucide-tags"
                :label="t('CONTACTS_BULK_ACTIONS.ASSIGN_LABELS')"
                :disabled="!selectedCount || isLoading"
                :is-loading="isLoading"
                class="!rounded-xl transition-all shadow-sm"
                @click="toggleLabelSelector"
              />
              <transition
                enter-active-class="transition ease-out duration-200"
                enter-from-class="transform opacity-0 -translate-y-2"
                enter-to-class="transform opacity-100 translate-y-0"
                leave-active-class="transition ease-in duration-150"
                leave-from-class="transform opacity-100 translate-y-0"
                leave-to-class="transform opacity-0 -translate-y-2"
              >
                <LabelActions
                  v-if="showLabelSelector"
                  class="premium-label-actions !absolute top-full mt-2 ltr:right-0 rtl:left-0 z-50 rounded-2xl shadow-2xl"
                  @assign="handleAssignLabels"
                />
              </transition>
            </div>
            <Policy :permissions="['administrator']">
              <Button
                v-tooltip.bottom="t('CONTACTS_BULK_ACTIONS.DELETE_CONTACTS')"
                variant="faded"
                color="ruby"
                size="sm"
                icon="i-lucide-trash"
                :disabled="!selectedCount || isLoading"
                :is-loading="isLoading"
                class="!rounded-xl !px-3 shadow-sm hover:!bg-red-500 hover:!text-white transition-all"
                @click="emit('deleteSelected')"
              />
            </Policy>
          </div>
        </template>
      </BulkSelectBar>
    </div>
  </div>
</template>

<style scoped>
.premium-bulk-bar {
  animation: slide-up 0.4s cubic-bezier(0.16, 1, 0.3, 1);
}

@keyframes slide-up {
  from {
    opacity: 0;
    transform: translateY(20px) scale(0.95);
  }
  to {
    opacity: 1;
    transform: translateY(0) scale(1);
  }
}

.premium-label-actions :deep(.label-dropdown) {
  @apply !rounded-2xl !border-n-slate-3/50 !bg-white/90 dark:!bg-n-slate-1/90 !backdrop-blur-xl !shadow-2xl;
}
</style>
