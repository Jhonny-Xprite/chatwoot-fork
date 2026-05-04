import { ref, computed } from 'vue';

export function useContactDeduplication() {
  const deduplicationModal = ref({
    isOpen: false,
    sourceContact: null
  });

  const mergeProgress = ref({
    isVisible: false,
    status: 'loading', // loading | success | error
    currentStep: 0,
    sourceContact: null,
    targetContact: null,
    messageCount: 0,
    errorMessage: '',
    mergeLogId: null
  });

  const openDeduplicationModal = (contact) => {
    deduplicationModal.value = {
      isOpen: true,
      sourceContact: contact
    };
  };

  const closeDeduplicationModal = () => {
    deduplicationModal.value.isOpen = false;
  };

  const showMergeProgress = (source, target) => {
    mergeProgress.value = {
      isVisible: true,
      status: 'loading',
      currentStep: 0,
      sourceContact: source,
      targetContact: target,
      messageCount: 0,
      errorMessage: '',
      mergeLogId: null
    };
  };

  const updateMergeProgress = (step) => {
    mergeProgress.value.currentStep = step;
  };

  const completeMergeSuccess = (messageCount, mergeLogId) => {
    mergeProgress.value.status = 'success';
    mergeProgress.value.messageCount = messageCount;
    mergeProgress.value.mergeLogId = mergeLogId;

    // Auto-close after 5 seconds
    setTimeout(() => {
      closeMergeProgress();
    }, 5000);
  };

  const completeMergeError = (error, mergeLogId = null) => {
    mergeProgress.value.status = 'error';
    mergeProgress.value.errorMessage = error;
    mergeProgress.value.mergeLogId = mergeLogId;
  };

  const closeMergeProgress = () => {
    mergeProgress.value.isVisible = false;
  };

  const detectDuplicates = async (contactId) => {
    try {
      const response = await fetch(`/api/v1/admin/contacts/deduplicate`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ contact_id: contactId })
      });

      if (!response.ok) {
        throw new Error('Failed to detect duplicates');
      }

      const data = await response.json();
      return data.duplicates || [];
    } catch (error) {
      console.error('Error detecting duplicates:', error);
      throw error;
    }
  };

  const mergeDuplicates = async (sourcePath, targetId) => {
    try {
      showMergeProgress(
        { id: sourcePath },
        { id: targetId }
      );

      updateMergeProgress(0); // Moving conversations

      const response = await fetch(`/api/v1/admin/contacts/merge`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({
          source_contact_id: sourcePath,
          target_contact_id: targetId
        })
      });

      if (!response.ok) {
        const error = await response.json();
        completeMergeError(error.error || 'Merge failed');
        throw new Error(error.error);
      }

      updateMergeProgress(1); // Audit trail
      updateMergeProgress(2); // Contact status
      updateMergeProgress(3); // Finalizing

      const data = await response.json();
      completeMergeSuccess(
        data.total_message_count || 0,
        data.merge_log_id
      );

      return data;
    } catch (error) {
      console.error('Error merging duplicates:', error);
      throw error;
    }
  };

  const getMergeLogs = async (contactId, page = 1, perPage = 10) => {
    try {
      const response = await fetch(
        `/api/v1/admin/contacts/merge-logs?contact_id=${contactId}&page=${page}&per_page=${perPage}`
      );

      if (!response.ok) {
        throw new Error('Failed to fetch merge logs');
      }

      return await response.json();
    } catch (error) {
      console.error('Error fetching merge logs:', error);
      throw error;
    }
  };

  const rollbackMerge = async (mergeLogId) => {
    try {
      const response = await fetch(`/api/v1/admin/contacts/rollback-merge`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ merge_log_id: mergeLogId })
      });

      if (!response.ok) {
        throw new Error('Failed to rollback merge');
      }

      return await response.json();
    } catch (error) {
      console.error('Error rolling back merge:', error);
      throw error;
    }
  };

  return {
    // State
    deduplicationModal: computed(() => deduplicationModal.value),
    mergeProgress: computed(() => mergeProgress.value),

    // Modal controls
    openDeduplicationModal,
    closeDeduplicationModal,

    // Progress controls
    showMergeProgress,
    updateMergeProgress,
    completeMergeSuccess,
    completeMergeError,
    closeMergeProgress,

    // API methods
    detectDuplicates,
    mergeDuplicates,
    getMergeLogs,
    rollbackMerge
  };
}
