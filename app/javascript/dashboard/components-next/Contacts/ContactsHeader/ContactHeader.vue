<script setup>
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Tooltip from 'dashboard/components-next/tooltip/Tooltip.vue';
import ContactSortMenu from './components/ContactSortMenu.vue';
import ContactMoreActions from './components/ContactMoreActions.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { useI18n } from 'vue-i18n';

defineProps({
  showSearch: { type: Boolean, default: true },
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, required: true },
  buttonLabel: { type: String, default: '' },
  activeSort: { type: String, default: 'last_activity_at' },
  activeOrdering: { type: String, default: '' },
  isSegmentsView: { type: Boolean, default: false },
  hasActiveFilters: { type: Boolean, default: false },
  isLabelView: { type: Boolean, default: false },
  isActiveView: { type: Boolean, default: false },
});

const emit = defineEmits([
  'search',
  'filter',
  'update:sort',
  'add',
  'import',
  'export',
  'createSegment',
  'deleteSegment',
]);

const { t } = useI18n();
</script>

<template>
  <header class="w-full">
    <div
      class="flex items-center justify-between w-full py-6 gap-6 mx-auto max-w-7xl px-6"
    >
      <div class="flex flex-col min-w-0">
        <h1 class="text-2xl font-black tracking-tight text-n-slate-12 truncate">
          {{ headerTitle }}
        </h1>
        <p
          v-if="!isSegmentsView && !isLabelView && !isActiveView"
          class="text-xs font-medium text-n-slate-10 uppercase tracking-widest mt-0.5"
        >
          {{ $t('CONTACTS_LAYOUT.HEADER.TITLE') }}
        </p>
      </div>

      <div class="flex items-center flex-shrink-0 gap-4">
        <!-- Modern Search Input -->
        <div v-if="showSearch" class="relative group/search">
          <Input
            :model-value="searchValue"
            type="search"
            :placeholder="$t('CONTACTS_LAYOUT.HEADER.SEARCH_PLACEHOLDER')"
            :custom-input-class="[
              'h-10 !w-72 !rounded-xl !border-n-slate-3/50 !bg-n-slate-2/40 hover:!bg-n-slate-2/60 focus:!bg-white dark:focus:!bg-n-slate-1 !transition-all !duration-300 ltr:!pl-10 rtl:!pr-10 shadow-sm',
            ]"
            @input="emit('search', $event.target.value)"
          >
            <template #prefix>
              <span
                class="i-lucide-search absolute ltr:left-3.5 rtl:right-3.5 top-1/2 -translate-y-1/2 text-n-slate-9 group-focus-within/search:text-n-brand-primary transition-colors size-4"
              />
            </template>
          </Input>
        </div>

        <div
          class="flex items-center flex-shrink-0 gap-3 bg-n-slate-2/50 dark:bg-n-slate-3/20 p-1 rounded-2xl border border-n-slate-3/30 dark:border-n-slate-2/10"
        >
          <div v-if="!isLabelView && !isActiveView" class="relative">
            <Tooltip
              :content="t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.TITLE')"
              placement="top"
            >
              <Button
                id="toggleContactsFilterButton"
                :icon="
                  isSegmentsView ? 'i-lucide-pen-line' : 'i-lucide-list-filter'
                "
                color="slate"
                size="sm"
                class="!rounded-xl transition-all"
                :class="
                  hasActiveFilters
                    ? '!text-n-brand-primary !bg-n-brand-primary/10'
                    : 'variant-ghost'
                "
                variant="ghost"
                @click="emit('filter')"
              />
            </Tooltip>
            <slot name="filter" />
          </div>

          <Tooltip
            v-if="
              hasActiveFilters &&
              !isSegmentsView &&
              !isLabelView &&
              !isActiveView
            "
            :content="
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.CREATE_SEGMENT.TITLE')
            "
            placement="top"
          >
            <Button
              icon="i-lucide-save"
              color="slate"
              size="sm"
              variant="ghost"
              class="!rounded-xl"
              @click="emit('createSegment')"
            />
          </Tooltip>

          <Tooltip
            v-if="isSegmentsView && !isLabelView && !isActiveView"
            :content="
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.FILTERS.DELETE_SEGMENT.TITLE')
            "
            placement="top"
          >
            <Button
              icon="i-lucide-trash"
              color="slate"
              size="sm"
              variant="ghost"
              class="!rounded-xl hover:!text-red-500"
              @click="emit('deleteSegment')"
            />
          </Tooltip>

          <ContactSortMenu
            :active-sort="activeSort"
            :active-ordering="activeOrdering"
            @update:sort="emit('update:sort', $event)"
          />

          <ContactMoreActions
            @add="emit('add')"
            @import="emit('import')"
            @export="emit('export')"
          />

          <div class="w-px h-6 bg-n-slate-3/50 dark:bg-n-slate-2/20 mx-1" />

          <ComposeConversation>
            <template #trigger>
              <Button
                :label="buttonLabel"
                size="sm"
                variant="solid"
                color="brand"
                class="!rounded-xl !px-5 shadow-lg shadow-n-brand-primary/20"
              />
            </template>
          </ComposeConversation>
        </div>
      </div>
    </div>
  </header>
</template>
