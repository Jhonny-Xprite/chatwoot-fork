import { ref, computed } from 'vue';

export function useContactDeduplication() {
  const deduplicationModal = ref({
    isOpen: false,
    sourceContact: null
  });

  const mergeProgress = ref({
    isVisible: false,
    status: 'loading',
    currentStep: 0,
    sourceContact: null,
    targetContact: null,
    messageCount: 0,
    errorMessage: '',
    mergeLogId: null
  });

  const closeMergeProgress = () => {
    mergeProgress.value.isVisible = false;
  };

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
    setTimeout(() => { closeMergeProgress(); }, 5000);
  };

  const completeMergeError = (error, mergeLogId = null) => {
    mergeProgress.value.status = 'error';
    mergeProgress.value.errorMessage = error;
    mergeProgress.value.mergeLogId = mergeLogId;
  };

  const detectDuplicates = async (accountId, contactId) => {
    const response = await fetch(`/api/v1/accounts/${accountId}/contacts/deduplicate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ contact_id: contactId })
    });

    if (!response.ok) throw new Error('Failed to detect duplicates');
    const data = await response.json();
    return data.duplicates || [];
  };

  const mergeDuplicates = async (accountId, sourceId, targetId) => {
    showMergeProgress({ id: sourceId }, { id: targetId });
    updateMergeProgress(0);

    const response = await fetch(`/api/v1/accounts/${accountId}/contacts/merge`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        source_contact_id: sourceId,
        target_contact_id: targetId
      })
    });

    if (!response.ok) {
      const error = await response.json();
      completeMergeError(error.error || 'Merge failed');
      throw new Error(error.error);
    }

    updateMergeProgress(1);
    updateMergeProgress(2);
    updateMergeProgress(3);

    const data = await response.json();
    completeMergeSuccess(data.total_message_count || 0, data.merge_log_id);
    return data;
  };

  const getMergeLogs = async (accountId, contactId, page = 1, perPage = 10) => {
    const response = await fetch(
      `/api/v1/accounts/${accountId}/contacts/merge_logs?contact_id=${contactId}&page=${page}&per_page=${perPage}`
    );
    if (!response.ok) throw new Error('Failed to fetch merge logs');
    return await response.json();
  };

  const rollbackMerge = async (accountId, mergeLogId) => {
    const response = await fetch(`/api/v1/accounts/${accountId}/contacts/rollback_merge`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ merge_log_id: mergeLogId })
    });
    if (!response.ok) throw new Error('Failed to rollback merge');
    return await response.json();
  };

  return {
    deduplicationModal: computed(() => deduplicationModal.value),
    mergeProgress: computed(() => mergeProgress.value),
    openDeduplicationModal,
    closeDeduplicationModal,
    showMergeProgress,
    updateMergeProgress,
    completeMergeSuccess,
    completeMergeError,
    closeMergeProgress,
    detectDuplicates,
    mergeDuplicates,
    getMergeLogs,
    rollbackMerge
  };
}
