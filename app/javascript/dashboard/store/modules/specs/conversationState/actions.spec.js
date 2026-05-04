import { vi, describe, it, expect } from 'vitest';
import typesExport from '../../../mutation-types';

const types = typesExport;

// Setup axios mock globally
global.axios = {
  patch: vi.fn(() => Promise.resolve({ status: 200 })),
};

// Mock the ConversationApi module
vi.mock('../../conversations', () => {
  return {
    default: {
      url: 'conversations',
      markUnread: vi.fn(() => Promise.resolve({ status: 200 })),
      markRead: vi.fn(() => Promise.resolve({ status: 200 })),
      markPinned: vi.fn(() => Promise.resolve({ status: 200 })),
      markUnpinned: vi.fn(() => Promise.resolve({ status: 200 })),
    },
  };
});

import conversationState from '../../conversationState';

describe('#actions', () => {
  describe('#markConversationUnread', () => {
    it('commits SET_CONVERSATION_UNREAD', async () => {
      const commit = vi.fn();
      await conversationState.actions.markConversationUnread({ commit }, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNREAD, 1);
    });
  });

  describe('#markConversationRead', () => {
    it('commits SET_CONVERSATION_READ', async () => {
      const commit = vi.fn();
      await conversationState.actions.markConversationRead({ commit }, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_READ, 1);
    });
  });

  describe('#markConversationPinned', () => {
    it('commits SET_CONVERSATION_PINNED', async () => {
      const commit = vi.fn();
      await conversationState.actions.markConversationPinned({ commit }, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_PINNED, 1);
    });
  });

  describe('#unmarkConversationPinned', () => {
    it('commits SET_CONVERSATION_UNPINNED', async () => {
      const commit = vi.fn();
      await conversationState.actions.unmarkConversationPinned({ commit }, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNPINNED, 1);
    });
  });

  describe('#loadUnreadConversations', () => {
    it('commits SET_ALL_UNREAD_CONVERSATIONS with filtered IDs', async () => {
      const commit = vi.fn();
      const conversations = [
        { id: 1, unread_at: '2026-05-04T10:00:00Z' },
        { id: 2, unread_at: null },
        { id: 3, unread_at: '2026-05-04T11:00:00Z' },
      ];

      await conversationState.actions.loadUnreadConversations(
        { commit },
        conversations
      );

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_UNREAD_CONVERSATIONS,
        [1, 3]
      );
    });

    it('handles empty conversation list', async () => {
      const commit = vi.fn();
      await conversationState.actions.loadUnreadConversations({ commit }, []);

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_UNREAD_CONVERSATIONS,
        []
      );
    });
  });

  describe('#loadPinnedConversations', () => {
    it('commits SET_ALL_PINNED_CONVERSATIONS with filtered IDs', async () => {
      const commit = vi.fn();
      const conversations = [
        { id: 1, pinned_at: '2026-05-04T10:00:00Z' },
        { id: 2, pinned_at: null },
        { id: 3, pinned_at: '2026-05-04T11:00:00Z' },
      ];

      await conversationState.actions.loadPinnedConversations(
        { commit },
        conversations
      );

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_PINNED_CONVERSATIONS,
        [1, 3]
      );
    });

    it('handles empty conversation list', async () => {
      const commit = vi.fn();
      await conversationState.actions.loadPinnedConversations({ commit }, []);

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_PINNED_CONVERSATIONS,
        []
      );
    });
  });

  describe('#clearConversationState', () => {
    it('commits CLEAR_CONVERSATION_STATE', () => {
      const commit = vi.fn();
      conversationState.actions.clearConversationState({ commit });

      expect(commit).toHaveBeenCalledWith(types.CLEAR_CONVERSATION_STATE);
    });
  });
});
