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
    </div>
  </div>
</template>
