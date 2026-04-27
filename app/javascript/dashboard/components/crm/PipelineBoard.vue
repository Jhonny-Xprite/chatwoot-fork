<script setup>
import PipelineColumn from './PipelineColumn.vue';

defineProps({
  stages: {
    type: Array,
    required: true,
  },
});

defineEmits(['select']);
</script>

<template>
  <div class="flex-1 overflow-x-auto bg-n-surface-1 min-h-0">
    <div class="flex h-full gap-4 p-4 min-w-max">
      <PipelineColumn
        v-for="stage in stages"
        :key="stage.id"
        :stage="stage"
        @select="$emit('select', $event)"
      />

      <!-- Placeholder for adding new stage -->
      <div
        class="w-80 border-2 border-dashed border-n-weak rounded-xl flex items-center justify-center text-n-slate-10 hover:text-n-brand hover:border-n-brand transition-all cursor-pointer bg-white/50 dark:bg-black/10"
      >
        <div class="flex flex-col items-center gap-2">
          <i class="i-lucide-plus-circle w-8 h-8" />
          <span class="text-sm font-medium">{{ $t('CRM.ADD_STAGE') }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
