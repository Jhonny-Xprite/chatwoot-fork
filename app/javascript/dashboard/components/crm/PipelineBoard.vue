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
  <div class="flex-1 overflow-x-auto bg-n-surface-1 min-h-0">
    <div class="flex h-full gap-4 p-4 min-w-max items-start">
      <PipelineColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        @select="$emit('select', $event)"
      />

      <!-- Add Stage Button -->
      <button
        class="flex items-center justify-center w-80 h-12 bg-n-slate-2 hover:bg-n-slate-3 border-2 border-dashed border-n-slate-4 rounded-xl text-n-slate-11 font-medium transition-all gap-2"
        @click="addStage"
      >
        <i class="i-lucide-plus w-4 h-4" />
        {{ $t('CRM.ADD_STAGE') }}
      </button>
    </div>
  </div>
</template>
