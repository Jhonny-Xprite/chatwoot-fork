<script setup>
import { computed } from 'vue';
import { Virtualizer } from 'virtua/vue';
import draggable from 'vuedraggable';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  dragOptions: {
    type: Object,
    default: () => ({}),
  },
  itemKey: {
    type: String,
    default: 'id',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
  overscan: {
    type: Number,
    default: 5,
  },
});

const emit = defineEmits(['update:modelValue', 'start', 'end', 'change']);

const localValue = computed({
  get: () => props.modelValue,
  set: (value) => {
    emit('update:modelValue', value);
  },
});

const mergedDragOptions = computed(() => ({
  ...props.dragOptions,
  disabled: props.disabled,
}));
</script>

<template>
  <Virtualizer
    :item-key="itemKey"
    :overscan="overscan"
    class="flex-1 overflow-y-auto custom-scrollbar scroll-smooth"
  >
    <draggable
      v-model="localValue"
      v-bind="mergedDragOptions"
      class="flex flex-col gap-4"
      tag="div"
      @start="emit('start')"
      @end="emit('end')"
      @change="emit('change', $event)"
    >
      <template #item="{ element, index }">
        <div
          :key="element[itemKey]"
          class="will-change-transform"
        >
          <slot
            name="item"
            :element="element"
            :index="index"
          />
        </div>
      </template>
    </draggable>
  </Virtualizer>
</template>

<style scoped>
.will-change-transform {
  will-change: transform;
}
</style>
