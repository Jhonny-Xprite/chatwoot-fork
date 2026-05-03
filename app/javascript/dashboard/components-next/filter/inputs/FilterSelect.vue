<script setup>
import { computed, ref } from 'vue';
import { useElementBounding, useWindowSize } from '@vueuse/core';
import DropdownContainer from 'next/dropdown-menu/base/DropdownContainer.vue';
import DropdownSection from 'next/dropdown-menu/base/DropdownSection.vue';
import DropdownBody from 'next/dropdown-menu/base/DropdownBody.vue';
import DropdownItem from 'next/dropdown-menu/base/DropdownItem.vue';

import Button from 'next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

// [{label, icon, thumbnail, value}]
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

const triggerRef = ref(null);
const dropdownRef = ref(null);

const { top } = useElementBounding(triggerRef);
const { height } = useWindowSize();
const { height: dropdownHeight } = useElementBounding(dropdownRef);

const selectedOption = computed(() => {
  return props.options?.find(o => o.value === selected.value) || {};
});

const iconToRender = computed(() => {
  if (props.hideIcon) return null;
  if (selectedOption.value.thumbnail) return null;
  return selectedOption.value.icon || 'i-lucide-chevron-down';
});

const dropdownPosition = computed(() => {
  const DROPDOWN_MAX_HEIGHT = 340;
  // Get actual height if available or use default
  const menuHeight = dropdownHeight.value
    ? dropdownHeight.value + 20
    : DROPDOWN_MAX_HEIGHT;
  const spaceBelow = height.value - top.value;
  return spaceBelow < menuHeight ? 'bottom-0' : 'top-0';
});

const updateSelected = newValue => {
  selected.value = newValue;
};
</script>

<template>
  <DropdownContainer>
    <template #trigger="{ toggle }">
      <slot name="trigger" :toggle="toggle">
        <Button
          ref="triggerRef"
          type="button"
          sm
          slate
          :variant
          :icon="iconToRender"
          :trailing-icon="
            selectedOption.icon || selectedOption.thumbnail ? false : true
          "
          :label="label || (hideLabel ? null : selectedOption.label)"
          @click="toggle"
        >
          <template v-if="selectedOption.thumbnail" #icon>
            <Avatar
              :src="selectedOption.thumbnail"
              :name="selectedOption.label"
              :size="16"
              class="mr-1"
            />
          </template>
        </Button>
      </slot>
    </template>
    <DropdownBody
      ref="dropdownRef"
      class="min-w-56 z-50"
      :class="dropdownPosition"
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
          <DropdownItem v-else @click="updateSelected(option.value)">
            <div class="flex items-center gap-2 w-full">
              <Avatar
                v-if="option.thumbnail"
                :src="option.thumbnail"
                :name="option.label"
                :size="18"
              />
              <Icon
                v-else-if="option.icon"
                :icon="option.icon"
                class="size-4 text-n-slate-11"
              />
              <span class="truncate flex-1">{{ option.label }}</span>
              <Icon
                v-if="option.value === selected"
                icon="i-lucide-check"
                class="size-3 text-n-brand"
              />
            </div>
          </DropdownItem>
        </template>
      </DropdownSection>
    </DropdownBody>
  </DropdownContainer>
</template>
