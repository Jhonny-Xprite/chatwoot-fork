<script setup>
import { onKeyStroke, useToggle } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { ref, watch } from 'vue';
import { provideDropdownContext } from './provider.js';

const emit = defineEmits(['close']);
const [isOpen, toggle] = useToggle(false);
const triggerElement = ref(null);

const closeMenu = () => {
  if (isOpen.value) {
    emit('close');
    toggle(false);
  }
};

onKeyStroke('Escape', e => {
  if (isOpen.value) {
    e.preventDefault();
    closeMenu();
  }
});

watch(isOpen, val => {
  if (val) {
    triggerElement.value = document.activeElement;
  } else {
    triggerElement.value?.focus();
    triggerElement.value = null;
  }
});

provideDropdownContext({
  isOpen,
  toggle,
  closeMenu,
});
</script>

<template>
  <div v-on-click-outside="closeMenu" class="relative space-y-2">
    <slot name="trigger" :is-open="isOpen" :toggle="() => toggle()" />
    <slot v-if="isOpen" :is-open="isOpen" :close="closeMenu" />
  </div>
</template>
