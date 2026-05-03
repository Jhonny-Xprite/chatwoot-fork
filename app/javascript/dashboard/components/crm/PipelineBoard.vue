<script setup>
import { computed } from 'vue';
import { useStore } from 'vuex';
import draggable from 'vuedraggable';
import PipelineColumn from './PipelineColumn.vue';
import ContactsPipelineColumn from './ContactsPipelineColumn.vue';

const props = defineProps({
  stages: {
    type: Array,
    default: () => [],
  },
  contacts: {
    type: Array,
    default: () => [],
  },
  contactsCount: {
    type: Number,
    default: 0,
  },
  isContactsLoading: {
    type: Boolean,
    default: false,
  },
  showContactsColumn: {
    type: Boolean,
    default: true,
  },
  showGroups: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['select', 'selectContact', 'addStage']);

const store = useStore();
const isFetchingStages = computed(
  () => store.state.crmPipeline.uiFlags.isFetchingStages
);

const stagesList = computed({
  get: () => props.stages,
  set: value => {
    store.dispatch('crmPipeline/reorderStages', {
      stages: value,
    });
  },
});

const dragOptions = {
  animation: 250,
  group: 'pipeline',
  ghostClass: 'opacity-30',
};
</script>

<template>
  <div
    class="flex-1 flex flex-col min-h-0 overflow-hidden bg-n-surface-1 relative"
  >
    <!-- Premium Board Background Gradient -->
    <div
      class="absolute inset-0 bg-gradient-to-br from-n-slate-1 via-n-slate-1 to-n-brand-primary-alpha-1/5 pointer-events-none"
    />

    <main class="flex-1 flex flex-col min-h-0 relative z-10">
      <div
        v-if="!isFetchingStages"
        class="flex-1 overflow-x-auto overflow-y-hidden custom-horizontal-scrollbar"
      >
        <div class="h-full inline-flex p-6 gap-6 min-w-full">
          <ContactsPipelineColumn
            v-if="showContactsColumn"
            :contacts="contacts"
            :total-count="contactsCount"
            :is-loading="isContactsLoading"
            @select-contact="emit('selectContact', $event)"
          />

          <draggable
            v-model="stagesList"
            item-key="id"
            class="flex gap-6 h-full items-start"
            handle=".column-drag-handle"
            v-bind="dragOptions"
          >
            <template #item="{ element: stage }">
              <PipelineColumn
                :stage="stage"
                :show-groups="showGroups"
                @select="emit('select', $event)"
                @select-contact="emit('selectContact', $event)"
              />
            </template>
          </draggable>

          <!-- Add Stage Placeholder -->
          <div class="w-[320px] flex-shrink-0 pt-2">
            <button
              class="group w-full flex flex-col items-center justify-center gap-3 rounded-2xl border-2 border-dashed border-n-slate-3 py-16 text-n-slate-10 transition-all hover:border-n-brand-primary/50 hover:bg-n-brand-primary-alpha-1 hover:text-n-brand-primary dark:border-n-slate-2"
              @click="emit('addStage')"
            >
              <div
                class="flex h-12 w-12 items-center justify-center rounded-full bg-n-slate-2 transition-colors group-hover:bg-n-brand-primary group-hover:text-white"
              >
                <i class="i-lucide-plus text-xl" />
              </div>
              <span class="text-xs font-black uppercase tracking-widest">{{
                $t('CRM.ADD_STAGE')
              }}</span>
            </button>
          </div>
        </div>
      </div>

      <!-- Loading State -->
      <div v-else class="flex h-full min-w-max items-start gap-6 p-6">
        <div
          v-for="i in 4"
          :key="i"
          class="h-full w-[320px] animate-pulse rounded-2xl bg-n-slate-2 dark:bg-n-slate-2/50"
        />
      </div>
    </main>
  </div>
</template>

<style scoped>
/* Ultra-thin Premium Scrollbar */
.custom-horizontal-scrollbar::-webkit-scrollbar {
  height: 6px;
}

.custom-horizontal-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}

.custom-horizontal-scrollbar::-webkit-scrollbar-thumb {
  background: rgba(var(--n-slate-5-rgb), 0.2);
  border-radius: 10px;
  transition: background 0.3s;
}

.custom-horizontal-scrollbar:hover::-webkit-scrollbar-thumb {
  background: rgba(var(--n-slate-5-rgb), 0.4);
}

/* Apple/Linear Theme Overrides */
:global(.apple-theme) .bg-n-surface-1 {
  background: #fbfbfd;
}

:global(.dark.apple-theme) .bg-n-surface-1 {
  background: #000000;
}

:global(.linear-theme) .bg-n-surface-1 {
  background: #080809;
}
</style>
