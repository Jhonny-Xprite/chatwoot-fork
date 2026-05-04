<template>
  <div class="fixed inset-0 z-[2100] flex items-center justify-center bg-black/50">
    <div class="bg-white rounded-lg shadow-xl w-full max-w-4xl mx-4">
      <div class="border-b border-gray-200 px-6 py-4">
        <h2 class="text-lg font-semibold text-gray-900">Confirm Merge</h2>
        <p class="text-sm text-gray-500 mt-1">Review the contacts before merging</p>
      </div>

      <div class="px-6 py-6">
        <div class="grid grid-cols-2 gap-6 mb-6">
          <div class="border-2 border-red-200 rounded-lg p-4 bg-red-50">
            <div class="flex items-center justify-between mb-4">
              <h3 class="font-semibold text-gray-900">Source Contact</h3>
              <span class="inline-block px-2 py-1 bg-red-200 text-red-800 text-xs rounded font-medium">
                Will be deleted
              </span>
            </div>
            <div class="space-y-3 text-sm">
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Name</p>
                <p class="text-gray-900 font-medium">{{ source.name }}</p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Email</p>
                <p class="text-gray-900">{{ source.email || '-' }}</p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Phone</p>
                <p class="text-gray-900">{{ source.phone_number || '-' }}</p>
              </div>
              <div class="pt-2 border-t border-red-200">
                <p class="text-gray-500 text-xs uppercase tracking-wider">Messages</p>
                <p class="text-gray-900 font-medium">{{ source.message_count || 0 }}</p>
              </div>
            </div>
          </div>

          <div class="border-2 border-green-200 rounded-lg p-4 bg-green-50">
            <div class="flex items-center justify-between mb-4">
              <h3 class="font-semibold text-gray-900">Target Contact</h3>
              <span class="inline-block px-2 py-1 bg-green-200 text-green-800 text-xs rounded font-medium">
                Will receive messages
              </span>
            </div>
            <div class="space-y-3 text-sm">
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Name</p>
                <p class="text-gray-900 font-medium">{{ target.name }}</p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Email</p>
                <p class="text-gray-900">{{ target.email || '-' }}</p>
              </div>
              <div>
                <p class="text-gray-500 text-xs uppercase tracking-wider">Phone</p>
                <p class="text-gray-900">{{ target.phone_number || '-' }}</p>
              </div>
              <div class="pt-2 border-t border-green-200">
                <p class="text-gray-500 text-xs uppercase tracking-wider">Messages</p>
                <p class="text-gray-900 font-medium">{{ target.message_count || 0 }}</p>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-6">
          <div class="flex items-start gap-3">
            <svg class="w-5 h-5 text-blue-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M18 5v8a2 2 0 01-2 2h-5l-5 4v-4H4a2 2 0 01-2-2V5a2 2 0 012-2h12a2 2 0 012 2zm-11-1h2v2H7V4zm2 4H7v2h2V8zm2-4h2v2h-2V4zm2 4h-2v2h2V8z" clip-rule="evenodd" />
            </svg>
            <div>
              <p class="font-medium text-blue-900">{{ source.message_count + target.message_count }} messages will be consolidated</p>
              <p class="text-sm text-blue-800 mt-1">All messages from "{{ source.name }}" will be moved to "{{ target.name }}" and appear in chronological order.</p>
            </div>
          </div>
        </div>

        <div class="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <div class="flex items-start gap-3">
            <svg class="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
            <div>
              <p class="font-medium text-yellow-900">This action cannot be easily undone</p>
              <p class="text-sm text-yellow-800 mt-1">The source contact will be marked as deleted but can be restored by an administrator if needed.</p>
            </div>
          </div>
        </div>
      </div>

      <div class="border-t border-gray-200 bg-gray-50 px-6 py-4 flex items-center justify-end gap-3">
        <button
          @click="emit('cancel')"
          :disabled="loading"
          class="px-4 py-2 text-gray-700 hover:bg-gray-100 rounded-lg transition font-medium disabled:opacity-50"
        >
          Cancel
        </button>
        <button
          @click="emit('confirm')"
          :disabled="loading"
          class="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 disabled:opacity-50 disabled:cursor-not-allowed transition font-medium flex items-center gap-2"
        >
          <svg v-if="loading" class="animate-spin h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          <span>{{ loading ? 'Merging...' : 'Confirm Merge' }}</span>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  source: {
    type: Object,
    required: true
  },
  target: {
    type: Object,
    required: true
  },
  loading: {
    type: Boolean,
    default: false
  }
});

defineEmits(['confirm', 'cancel']);
</script>
