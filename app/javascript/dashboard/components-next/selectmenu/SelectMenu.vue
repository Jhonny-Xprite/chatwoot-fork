<script setup>
import { ref, computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  modelValue: {
    type: String,
    required: true,
  },
  label: {
    type: String,
    required: true,
  },
  subMenuPosition: {
    type: String,
    default: 'right',
    validator: value => {
      return ['right', 'left', 'bottom'].includes(value);
    },
  },
});

const emit = defineEmits(['update:modelValue']);

const isOpen = ref(false);

const labelValue = computed(() => props.label);

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
};

const handleSelect = value => {
  emit('update:modelValue', value);
  isOpen.value = false;
};
</script>

<template>
  <div
    v-on-clickaway="() => (isOpen = false)"
    class="relative z-[170] flex w-fit flex-col gap-1 overflow-visible"
  >
    <Button
      icon="i-lucide-chevron-down"
      size="sm"
      trailing-icon
      color="slate"
      variant="faded"
      class="!w-fit max-w-40"
      :class="{ 'dark:!bg-n-alpha-2 !bg-n-slate-9/20': isOpen }"
      :label="labelValue"
      @click="toggleMenu"
    />
    <div
      v-if="isOpen"
      class="absolute top-0 z-[180] flex max-w-64 select-none flex-col gap-1 rounded-lg border border-n-weak bg-n-alpha-3 p-1 shadow-xl shadow-black/10 backdrop-blur-[100px] dark:border-n-strong/50"
      :class="{
        'ltr:left-full rtl:right-full ltr:ml-1 rtl:mr-1':
          subMenuPosition === 'right',
        'ltr:right-full rtl:left-full ltr:mr-1 rtl:ml-1':
          subMenuPosition === 'left',
        'top-full mt-1 ltr:right-0 rtl:left-0': subMenuPosition === 'bottom',
      }"
    >
      <Button
        v-for="option in options"
        :key="option.value"
        :label="option.label"
        :icon="option.value === modelValue ? 'i-lucide-check' : ''"
        size="sm"
        variant="ghost"
        color="slate"
        trailing-icon
        class="!justify-end !px-2.5 !h-7"
        :class="{ '!bg-n-alpha-2': option.value === modelValue }"
        @click="handleSelect(option.value)"
      />
    </div>
  </div>
</template>
