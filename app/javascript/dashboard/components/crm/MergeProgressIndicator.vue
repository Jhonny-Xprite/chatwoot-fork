<template>
  <Teleport to="body">
    <Transition
      enter-active-class="transition duration-300"
      enter-from-class="opacity-0 translate-y-4"
      enter-to-class="opacity-100 translate-y-0"
      leave-active-class="transition duration-300"
      leave-from-class="opacity-100 translate-y-0"
      leave-to-class="opacity-0 translate-y-4"
    >
      <div
        v-if="isVisible"
        class="fixed bottom-6 right-6 z-[3000] bg-white rounded-lg shadow-lg border border-gray-200 p-4 max-w-sm"
      >
        <!-- Success State -->
        <div v-if="status === 'success'" class="flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg class="h-6 w-6 text-green-500" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="font-semibold text-gray-900">Contacts merged successfully</h3>
            <p class="text-sm text-gray-600 mt-1">
              {{ sourceContact?.name }} has been merged into {{ targetContact?.name }}.
            </p>
            <div class="text-xs text-gray-500 mt-2">
              ✓ {{ messageCount }} messages consolidated<br>
              ✓ Audit trail created<br>
              ✓ Merge can be rolled back if needed
            </div>
            <button
              @click="close"
              class="mt-3 text-sm font-medium text-blue-600 hover:text-blue-700"
            >
              Dismiss
            </button>
          </div>
        </div>

        <!-- Error State -->
        <div v-else-if="status === 'error'" class="flex items-start gap-3">
          <div class="flex-shrink-0">
            <svg class="h-6 w-6 text-red-500" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="font-semibold text-gray-900">Merge failed</h3>
            <p class="text-sm text-gray-600 mt-1">{{ errorMessage }}</p>
            <div class="flex gap-2 mt-3">
              <button
                v-if="mergeLogId"
                @click="rollback"
                class="text-sm font-medium text-blue-600 hover:text-blue-700"
              >
                Rollback
              </button>
              <button
                @click="close"
                class="text-sm font-medium text-gray-600 hover:text-gray-700"
              >
                Dismiss
              </button>
            </div>
          </div>
        </div>

        <!-- Loading State -->
        <div v-else class="flex items-start gap-3">
          <div class="flex-shrink-0 pt-0.5">
            <svg class="animate-spin h-5 w-5 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
          </div>
          <div class="flex-1">
            <h3 class="font-semibold text-gray-900">Merging contacts...</h3>
            <div class="mt-3 space-y-2">
              <!-- Progress steps -->
              <div v-for="(step, idx) in steps" :key="idx" class="flex items-center gap-2 text-sm">
                <svg
                  v-if="idx < currentStep"
                  class="w-4 h-4 text-green-500"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
                </svg>
                <svg
                  v-else-if="idx === currentStep"
                  class="animate-spin w-4 h-4 text-blue-500"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                </svg>
                <svg
                  v-else
                  class="w-4 h-4 text-gray-300"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM7 9a1 1 0 100-2 1 1 0 000 2zm6 0a1 1 0 100-2 1 1 0 000 2z" clip-rule="evenodd" />
                </svg>
                <span :class="idx <= currentStep ? 'text-gray-900' : 'text-gray-400'">
                  {{ step }}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { ref, computed, watch } from 'vue';
import { Teleport, Transition } from 'vue';

const props = defineProps({
  isVisible: {
    type: Boolean,
    default: false
  },
  status: {
    type: String,
    enum: ['loading', 'success', 'error'],
    default: 'loading'
  },
  currentStep: {
    type: Number,
    default: 0
  },
  sourceContact: {
    type: Object,
    default: null
  },
  targetContact: {
    type: Object,
    default: null
  },
  messageCount: {
    type: Number,
    default: 0
  },
  errorMessage: {
    type: String,
    default: 'An unexpected error occurred'
  },
  mergeLogId: {
    type: [String, Number],
    default: null
  }
});

const emit = defineEmits(['close', 'rollback']);

const steps = [
  'Moving conversations...',
  'Creating audit trail...',
  'Updating contact status...',
  'Finalizing...'
];

const close = () => {
  emit('close');
};

const rollback = async () => {
  try {
    const response = await fetch(`/api/v1/admin/contacts/rollback-merge`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ merge_log_id: props.mergeLogId })
    });

    if (response.ok) {
      emit('rollback');
      close();
    }
  } catch (error) {
    console.error('Rollback failed:', error);
  }
};
</script>
