/* eslint-disable no-alert */
<script setup>
import { useStore } from 'vuex';
import PipelineColumn from './PipelineColumn.vue';

defineProps({
  stages: {
    type: Array,
    required: true,
  },
});

defineEmits(['select']);

const store = useStore();

const addStage = () => {
  const name = window.prompt('Nome da nova etapa:');
  if (name) {
    store.dispatch('crmPipeline/createStage', name);
  }
};
</script>

<template>
  <div class="flex-1 overflow-x-auto overflow-y-hidden bg-[#F8FAFC] dark:bg-n-slate-1 min-h-0 custom-scrollbar">
    <div class="flex h-full gap-5 p-6 min-w-max items-start overflow-y-hidden">
      <PipelineColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        class="shadow-sm border border-n-weak hover:shadow-md transition-shadow max-h-full"
        @select="$emit('select', $event)"
      />

      <!-- Add Stage Button -->
      <button
        class="flex items-center justify-center w-80 h-[52px] bg-white dark:bg-n-slate-2 hover:bg-n-brand/5 border-2 border-dashed border-n-slate-4 hover:border-n-brand rounded-xl text-n-slate-11 hover:text-n-brand font-bold transition-all gap-2 flex-shrink-0 group/add-stage"
        @click="addStage"
      >
        <i class="i-lucide-plus w-5 h-5 group-hover/add-stage:scale-110 transition-transform" />
        <span class="text-sm uppercase tracking-wide">{{ $t('CRM.ADD_STAGE') }}</span>
      </button>
    </div>
  </div>
</template>
