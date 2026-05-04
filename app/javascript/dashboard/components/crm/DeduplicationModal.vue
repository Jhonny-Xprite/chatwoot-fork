<script setup>
import { ref, watch } from 'vue';
import MergeConfirmationDialog from './MergeConfirmationDialog.vue';

const props = defineProps({
  isOpen: { type: Boolean, default: false },
  sourceContact: { type: Object, required: true },
});

const emit = defineEmits(['close', 'merged']);

const duplicates = ref([]);
const selectedIndex = ref(null);
const loading = ref(false);
const merging = ref(false);
const showConfirmation = ref(false);

const confidenceClass = confidence => {
  const base = 'px-3 py-1 rounded-full text-xs font-medium';
  if (confidence === 'HIGH') return `${base} bg-green-100 text-green-800`;
  if (confidence === 'MEDIUM') return `${base} bg-yellow-100 text-yellow-800`;
  return `${base} bg-gray-100 text-gray-800`;
};

const handleClose = () => {
  emit('close');
  selectedIndex.value = null;
  showConfirmation.value = false;
};

const selectDuplicate = idx => {
  selectedIndex.value = idx;
  showConfirmation.value = true;
};

const handleMerge = () => {
  showConfirmation.value = true;
};

const handleExecuteMerge = async () => {
  if (selectedIndex.value === null) return;
  merging.value = true;
  try {
    const target = duplicates.value[selectedIndex.value].contact;
    const response = await fetch(
      `/api/v1/accounts/${props.sourceContact.account_id}/contacts/merge`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({
          source_contact_id: props.sourceContact.id,
          target_contact_id: target.id,
        }),
      }
    );

    if (response.ok) {
      emit('merged', { source: props.sourceContact, target });
      showConfirmation.value = false;
      handleClose();
    }
  } finally {
    merging.value = false;
  }
};

const fetchDuplicates = async () => {
  loading.value = true;
  try {
    const response = await fetch(
      `/api/v1/accounts/${props.sourceContact.account_id}/contacts/deduplicate`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')
            .content,
        },
        body: JSON.stringify({ contact_id: props.sourceContact.id }),
      }
    );

    if (response.ok) {
      const data = await response.json();
      duplicates.value = data.duplicates || [];
    }
  } finally {
    loading.value = false;
  }
};

watch(
  () => props.isOpen,
  async newVal => {
    if (newVal) await fetchDuplicates();
  }
);
</script>

<template>
  <div
    v-show="isOpen"
    class="fixed inset-0 z-[2000] flex items-center justify-center bg-black/50"
  >
    <div
      class="bg-white rounded-lg shadow-xl w-full max-w-2xl mx-4 max-h-[90vh] overflow-auto"
    >
      <!-- Header -->
      <div
        class="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between"
      >
        <h2 class="text-lg font-semibold text-gray-900">
          Duplicate Contacts Detected
        </h2>
        <button
          class="text-gray-400 hover:text-gray-500 transition"
          aria-label="Close dialog"
          @click="handleClose"
        >
          <svg
            class="w-6 h-6"
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>

      <!-- Content -->
      <div class="px-6 py-4">
        <p class="text-gray-600 mb-6">
          We found {{ duplicates.length }} potential duplicate contact{{
            duplicates.length !== 1 ? 's' : ''
          }}. Select which ones you'd like to merge.
        </p>

        <div v-if="loading" class="flex items-center justify-center py-8">
          <div
            class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"
          />
          <span class="ml-2 text-gray-600">Detecting duplicates...</span>
        </div>

        <div
          v-else-if="duplicates.length === 0"
          class="text-center py-8 text-gray-500"
        >
          No duplicate contacts found.
        </div>

        <div v-else class="space-y-4">
          <div
            v-for="(dup, idx) in duplicates"
            :key="idx"
            class="border border-gray-200 rounded-lg p-4 hover:border-blue-300 transition cursor-pointer"
            :class="{ 'bg-blue-50 border-blue-300': selectedIndex === idx }"
            @click="selectDuplicate(idx)"
          >
            <div class="flex items-start justify-between mb-3">
              <div>
                <p class="font-medium text-gray-900">{{ dup.contact.name }}</p>
                <p class="text-sm text-gray-500">{{ dup.reason }}</p>
              </div>
              <span
                class="px-3 py-1 rounded-full text-xs font-medium"
                :class="confidenceClass(dup.confidence)"
              >
                {{ dup.confidence }} Confidence
              </span>
            </div>

            <div class="grid grid-cols-2 gap-4 text-sm">
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">
                  Email
                </p>
                <p class="text-gray-900">{{ dup.contact.email || '-' }}</p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">
                  Phone
                </p>
                <p class="text-gray-900">
                  {{ dup.contact.phone_number || '-' }}
                </p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">
                  Messages
                </p>
                <p class="text-gray-900">
                  {{ dup.contact.message_count || 0 }}
                </p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">
                  Similarity
                </p>
                <p class="text-gray-900">
                  {{
                    dup.similarity_score
                      ? (dup.similarity_score * 100).toFixed(1) + '%'
                      : 'Exact match'
                  }}
                </p>
              </div>
            </div>

            <div
              v-if="selectedIndex === idx"
              class="mt-3 pt-3 border-t border-blue-200"
            >
              <p class="text-xs text-blue-700 font-medium">
                Selected for merge
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Footer -->
      <div
        class="sticky bottom-0 bg-gray-50 border-t border-gray-200 px-6 py-4 flex items-center justify-end gap-3"
      >
        <button
          class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition font-medium"
          @click="handleClose"
        >
          Cancel
        </button>
        <button
          :disabled="selectedIndex === null || merging"
          class="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition font-medium"
          @click="handleMerge"
        >
          <span v-if="merging" class="flex items-center gap-2">
            <svg
              class="animate-spin h-4 w-4"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Merging...
          </span>
          <span v-else>Merge Contacts</span>
        </button>
      </div>
    </div>

    <MergeConfirmationDialog
      v-if="showConfirmation && selectedIndex !== null"
      :source="duplicates[selectedIndex].contact"
      :target="sourceContact"
      :loading="merging"
      @confirm="handleExecuteMerge"
      @cancel="showConfirmation = false"
    />
  </div>
</template>
