<script setup>
import { computed, ref } from 'vue';
import { useRoute } from 'vue-router';

import ContactListHeaderWrapper from 'dashboard/components-next/Contacts/ContactsHeader/ContactListHeaderWrapper.vue';
import ContactsActiveFiltersPreview from 'dashboard/components-next/Contacts/ContactsHeader/components/ContactsActiveFiltersPreview.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import ContactsLoadMore from 'dashboard/components-next/Contacts/ContactsLoadMore.vue';

const props = defineProps({
  searchValue: { type: String, default: '' },
  headerTitle: { type: String, default: '' },
  showPaginationFooter: { type: Boolean, default: true },
  currentPage: { type: Number, default: 1 },
  totalItems: { type: Number, default: 100 },
  itemsPerPage: { type: Number, default: 15 },
  activeSort: { type: String, default: '' },
  activeOrdering: { type: String, default: '' },
  activeSegment: { type: Object, default: null },
  segmentsId: { type: [String, Number], default: 0 },
  hasAppliedFilters: { type: Boolean, default: false },
  isFetchingList: { type: Boolean, default: false },
  useInfiniteScroll: { type: Boolean, default: false },
  hasMore: { type: Boolean, default: false },
  isLoadingMore: { type: Boolean, default: false },
});

const emit = defineEmits([
  'update:currentPage',
  'update:sort',
  'search',
  'applyFilter',
  'clearFilters',
  'loadMore',
]);

const route = useRoute();

const contactListHeaderWrapper = ref(null);

const isNotSegmentView = computed(() => {
  return route.name !== 'contacts_dashboard_segments_index';
});

const isActiveView = computed(() => {
  return route.name === 'contacts_dashboard_active';
});

const isLabelView = computed(
  () => route.name === 'contacts_dashboard_labels_index'
);

const showActiveFiltersPreview = computed(() => {
  return (
    (props.hasAppliedFilters || !isNotSegmentView.value) &&
    !props.isFetchingList &&
    !isLabelView.value &&
    !isActiveView.value
  );
});

const updateCurrentPage = page => {
  emit('update:currentPage', page);
};

const openFilter = () => {
  contactListHeaderWrapper.value?.onToggleFilters();
};

const showLoadMore = computed(() => {
  return props.useInfiniteScroll && props.hasMore;
});

const showPagination = computed(() => {
  return !props.useInfiniteScroll && props.showPaginationFooter;
});
</script>

<template>
  <section
    class="flex w-full h-full gap-0 overflow-hidden justify-evenly bg-immersive"
  >
    <div
      class="flex flex-col w-full h-full transition-all duration-300 relative"
    >
      <!-- Decorative Background Elements -->
      <div
        class="absolute top-0 left-0 w-full h-64 bg-gradient-to-b from-n-brand-primary/5 to-transparent pointer-events-none"
      />

      <ContactListHeaderWrapper
        ref="contactListHeaderWrapper"
        class="sticky top-0 z-30 !bg-white/40 dark:!bg-n-slate-1/40 backdrop-blur-xl border-b border-n-slate-3/50 dark:border-n-slate-2/30 shadow-sm"
        :show-search="isNotSegmentView && !isActiveView"
        :search-value="searchValue"
        :active-sort="activeSort"
        :active-ordering="activeOrdering"
        :header-title="headerTitle"
        :active-segment="activeSegment"
        :segments-id="segmentsId"
        :has-applied-filters="hasAppliedFilters"
        :is-label-view="isLabelView"
        :is-active-view="isActiveView"
        @update:sort="emit('update:sort', $event)"
        @search="emit('search', $event)"
        @apply-filter="emit('applyFilter', $event)"
        @clear-filters="emit('clearFilters')"
      />

      <main class="flex-1 overflow-y-auto px-6 py-8 custom-scrollbar">
        <div class="w-full mx-auto max-w-7xl">
          <ContactsActiveFiltersPreview
            v-if="showActiveFiltersPreview"
            :active-segment="activeSegment"
            class="mb-6"
            @clear-filters="emit('clearFilters')"
            @open-filter="openFilter"
          />

          <div class="flex flex-col gap-5 min-h-[400px]">
            <slot name="default" />
          </div>

          <ContactsLoadMore
            v-if="showLoadMore"
            class="mt-8"
            :is-loading="isLoadingMore"
            @load-more="emit('loadMore')"
          />
        </div>
      </main>

      <footer
        v-if="showPagination"
        class="sticky bottom-0 z-20 px-6 py-4 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md border-t border-n-slate-3/50 dark:border-n-slate-2/30"
      >
        <div class="max-w-7xl mx-auto flex justify-center">
          <PaginationFooter
            current-page-info="CONTACTS_LAYOUT.PAGINATION_FOOTER.SHOWING"
            :current-page="currentPage"
            :total-items="totalItems"
            class="w-full !max-w-none !bg-transparent !border-none !p-0"
            :items-per-page="itemsPerPage"
            @update:current-page="updateCurrentPage"
          />
        </div>
      </footer>
    </div>
  </section>
</template>

<style scoped>
.bg-immersive {
  background-color: var(--n-surface-1);
  background-image: radial-gradient(
      at 0% 0%,
      rgba(var(--n-brand-primary-rgb), 0.03) 0px,
      transparent 50%
    ),
    radial-gradient(
      at 100% 0%,
      rgba(var(--n-brand-primary-rgb), 0.02) 0px,
      transparent 50%
    );
}

.custom-scrollbar::-webkit-scrollbar {
  width: 6px;
}
.custom-scrollbar::-webkit-scrollbar-track {
  background: transparent;
}
.custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-4);
  border-radius: 9999px;
}
:global(.dark) .custom-scrollbar::-webkit-scrollbar-thumb {
  background: var(--n-slate-3);
}
</style>
