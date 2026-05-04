import * as types from '../../../mutation-types';
import conversationState from '../../conversationState';

// Mock the ConversationApi
vi.mock('../../conversations', () => ({
  default: {
    markUnread: vi.fn(),
    markRead: vi.fn(),
    markPinned: vi.fn(),
    markUnpinned: vi.fn(),
  },
}));

const commit = vi.fn();

describe('#actions', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('#markConversationUnread', () => {
    it('commits SET_CONVERSATION_UNREAD on success', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markUnread.mockResolvedValue({ status: 200 });

      await conversationState.actions.markConversationUnread({ commit }, 1);

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNREAD, 1);
    });

    it('reverts to READ on API failure', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markUnread.mockRejectedValue(new Error('API Error'));

      try {
        await conversationState.actions.markConversationUnread({ commit }, 1);
      } catch (e) {
        // Error expected
      }

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNREAD, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_READ, 1);
    });
  });

  describe('#markConversationRead', () => {
    it('commits SET_CONVERSATION_READ on success', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markRead.mockResolvedValue({ status: 200 });

      await conversationState.actions.markConversationRead({ commit }, 1);

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_READ, 1);
    });

    it('reverts to UNREAD on API failure', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markRead.mockRejectedValue(new Error('API Error'));

      try {
        await conversationState.actions.markConversationRead({ commit }, 1);
      } catch (e) {
        // Error expected
      }

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_READ, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNREAD, 1);
    });
  });

  describe('#markConversationPinned', () => {
    it('commits SET_CONVERSATION_PINNED on success', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markPinned.mockResolvedValue({ status: 200 });

      await conversationState.actions.markConversationPinned({ commit }, 1);

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_PINNED, 1);
    });

    it('reverts to UNPINNED on API failure', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markPinned.mockRejectedValue(new Error('API Error'));

      try {
        await conversationState.actions.markConversationPinned({ commit }, 1);
      } catch (e) {
        // Error expected
      }

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_PINNED, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNPINNED, 1);
    });
  });

  describe('#unmarkConversationPinned', () => {
    it('commits SET_CONVERSATION_UNPINNED on success', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markUnpinned.mockResolvedValue({ status: 200 });

      await conversationState.actions.unmarkConversationPinned({ commit }, 1);

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNPINNED, 1);
    });

    it('reverts to PINNED on API failure', async () => {
      const ConversationApi = await import('../../conversations');
      ConversationApi.default.markUnpinned.mockRejectedValue(new Error('API Error'));

      try {
        await conversationState.actions.unmarkConversationPinned({ commit }, 1);
      } catch (e) {
        // Error expected
      }

      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_UNPINNED, 1);
      expect(commit).toHaveBeenCalledWith(types.SET_CONVERSATION_PINNED, 1);
    });
  });

  describe('#loadUnreadConversations', () => {
    it('commits SET_ALL_UNREAD_CONVERSATIONS with filtered IDs', async () => {
      const conversations = [
        { id: 1, unread_at: '2026-05-04T10:00:00Z' },
        { id: 2, unread_at: null },
        { id: 3, unread_at: '2026-05-04T11:00:00Z' },
      ];

      await conversationState.actions.loadUnreadConversations({ commit }, conversations);

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_UNREAD_CONVERSATIONS,
        [1, 3]
      );
    });

    it('handles empty conversation list', async () => {
      await conversationState.actions.loadUnreadConversations({ commit }, []);

      expect(commit).toHaveBeenCalledWith(types.SET_ALL_UNREAD_CONVERSATIONS, []);
    });
  });

  describe('#loadPinnedConversations', () => {
    it('commits SET_ALL_PINNED_CONVERSATIONS with filtered IDs', async () => {
      const conversations = [
        { id: 1, pinned_at: '2026-05-04T10:00:00Z' },
        { id: 2, pinned_at: null },
        { id: 3, pinned_at: '2026-05-04T11:00:00Z' },
      ];

      await conversationState.actions.loadPinnedConversations({ commit }, conversations);

      expect(commit).toHaveBeenCalledWith(
        types.SET_ALL_PINNED_CONVERSATIONS,
        [1, 3]
      );
    });

    it('handles empty conversation list', async () => {
      await conversationState.actions.loadPinnedConversations({ commit }, []);

      expect(commit).toHaveBeenCalledWith(types.SET_ALL_PINNED_CONVERSATIONS, []);
    });
  });

  describe('#clearConversationState', () => {
    it('commits CLEAR_CONVERSATION_STATE', () => {
      conversationState.actions.clearConversationState({ commit });

      expect(commit).toHaveBeenCalledWith(types.CLEAR_CONVERSATION_STATE);
    });
  });
});
