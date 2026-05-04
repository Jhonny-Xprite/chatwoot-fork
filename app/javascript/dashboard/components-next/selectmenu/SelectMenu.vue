<script setup>
import { ref, computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import { vOnClickOutside } from '@vueuse/components';
import TeleportWithDirection from 'dashboard/components-next/TeleportWithDirection.vue';

const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  modelValue: {
    type: [String, Number],
    default: '',
  },
  label: {
    type: String,
    required: true,
  },
  subMenuPosition: {
    type: String,
    default: 'bottom',
    validator: value => {
      return ['right', 'left', 'bottom'].includes(value);
    },
  },
});

const emit = defineEmits(['update:modelValue']);

const isOpen = ref(false);
const triggerRef = ref(null);
const menuRef = ref(null);

const { fixedPosition, updatePosition } = useDropdownPosition(
  triggerRef,
  menuRef,
  isOpen,
  {
    align: props.subMenuPosition === 'left' ? 'start' : 'end',
    zIndex: 1000,
  }
);

const labelValue = computed(() => props.label);

const toggleMenu = () => {
  isOpen.value = !isOpen.value;
  if (isOpen.value) {
    updatePosition();
  }
};

const handleSelect = value => {
  emit('update:modelValue', value);
  isOpen.value = false;
};

const handleClickOutside = event => {
  if (triggerRef.value?.contains(event.target)) return;
  isOpen.value = false;
};

const triggerElement = ref(null);

import { onKeyStroke } from '@vueuse/core';
import { watch } from 'vue';

onKeyStroke('Escape', e => {
  if (isOpen.value) {
    e.preventDefault();
    isOpen.value = false;
  }
});

watch(isOpen, val => {
  if (val) {
    triggerElement.value = document.activeElement;
  } else {
    triggerElement.value?.focus();
  }
});
</script>

<template>
  <div class="relative flex w-fit flex-col gap-1 overflow-visible">
    <div ref="triggerRef" class="w-fit">
      <Button
        icon="i-lucide-chevron-down"
        size="sm"
        trailing-icon
        color="slate"
        variant="faded"
        class="!w-fit max-w-40"
        :class="{ 'dark:!bg-n-alpha-2 !bg-n-slate-9/20': isOpen }"
        :label="labelValue"
        @click.stop="toggleMenu"
      />
    </div>

    <TeleportWithDirection to="body">
      <div
        v-if="isOpen"
        ref="menuRef"
        v-on-click-outside="handleClickOutside"
        :class="fixedPosition.class"
        :style="fixedPosition.style"
        class="flex max-w-64 select-none flex-col gap-1 rounded-lg border border-n-weak bg-n-alpha-3 p-1 shadow-xl shadow-black/10 backdrop-blur-[100px] dark:border-n-strong/50"
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
          @click.stop="handleSelect(option.value)"
        />
      </div>
    </TeleportWithDirection>
  </div>
</template>
