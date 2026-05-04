<script setup>
import { computed, ref, useTemplateRef } from 'vue';
import { useDropdownPosition } from 'dashboard/composables/useDropdownPosition';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';

// [{label, icon, value}]
const props = defineProps({
  options: {
    type: Array,
    required: true,
  },
  hideLabel: {
    type: Boolean,
    default: false,
  },
  hideIcon: {
    type: Boolean,
    default: false,
  },
  variant: {
    type: String,
    default: 'faded',
  },
  label: {
    type: String,
    default: null,
  },
});

const selected = defineModel({
  type: [String, Number],
  required: true,
});

const triggerRef = useTemplateRef('triggerRef');
const dropdownRef = useTemplateRef('dropdownRef');
const isOpenLocal = ref(false);

const { position } = useDropdownPosition(triggerRef, dropdownRef, isOpenLocal);

const selectedOption = computed(() => {
  return props.options?.find(o => o.value === selected.value) || {};
});

const iconToRender = computed(() => {
  if (props.hideIcon) return null;
  return selectedOption.value.icon || 'i-lucide-chevron-down';
});

const updateSelected = (newValue, close) => {
  selected.value = newValue;
  close();
};

const onToggle = toggle => {
  toggle();
  isOpenLocal.value = !isOpenLocal.value;
};
</script>

<template>
  <DropdownContainer @close="isOpenLocal = false">
    <template #trigger="{ toggle }">
      <slot name="trigger" :toggle="() => onToggle(toggle)">
        <Button
          ref="triggerRef"
          type="button"
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="selectedOption.icon ? false : true"
          :label="label || (hideLabel ? null : selectedOption.label)"
          @click="onToggle(toggle)"
        />
      </slot>
    </template>
    <template #default="{ close }">
      <DropdownBody
        ref="dropdownRef"
        class="min-w-56"
        :class="position.class"
        :style="position.style"
        strong
      >
        <DropdownSection class="[&>ul]:max-h-72">
          <template v-for="option in options" :key="option.value">
            <li
              v-if="option.disabled"
              class="px-2 py-1.5 text-xs font-medium text-n-slate-10 select-none"
            >
              {{ option.label }}
            </li>
            <DropdownItem
              v-else
              :label="option.label"
              :icon="option.icon"
              @click="updateSelected(option.value, close)"
            />
          </template>
        </DropdownSection>
      </DropdownBody>
    </template>
  </DropdownContainer>
</template>
