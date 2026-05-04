import typesExport from '../../../mutation-types';
import conversationState from '../../conversationState';

const types = typesExport;
const { mutations } = conversationState;

describe('#mutations', () => {
  describe('#SET_CONVERSATION_UNREAD', () => {
    it('adds conversation ID to unreadConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_UNREAD](state, 1);
      expect(state.unreadConversations.has(1)).toBe(true);
    });

    it('handles multiple unread conversations', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_UNREAD](state, 1);
      mutations[types.SET_CONVERSATION_UNREAD](state, 2);
      expect(state.unreadConversations.size).toBe(2);
      expect(state.unreadConversations.has(1)).toBe(true);
      expect(state.unreadConversations.has(2)).toBe(true);
    });
  });

  describe('#SET_CONVERSATION_READ', () => {
    it('removes conversation ID from unreadConversations Set', () => {
      const state = {
        unreadConversations: new Set([1, 2]),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_READ](state, 1);
      expect(state.unreadConversations.has(1)).toBe(false);
      expect(state.unreadConversations.has(2)).toBe(true);
    });

    it('handles removing from empty Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_READ](state, 1);
      expect(state.unreadConversations.size).toBe(0);
    });
  });

  describe('#SET_CONVERSATION_PINNED', () => {
    it('adds conversation ID to pinnedConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_PINNED](state, 1);
      expect(state.pinnedConversations.has(1)).toBe(true);
    });

    it('handles multiple pinned conversations', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_CONVERSATION_PINNED](state, 1);
      mutations[types.SET_CONVERSATION_PINNED](state, 2);
      expect(state.pinnedConversations.size).toBe(2);
      expect(state.pinnedConversations.has(1)).toBe(true);
      expect(state.pinnedConversations.has(2)).toBe(true);
    });
  });

  describe('#SET_CONVERSATION_UNPINNED', () => {
    it('removes conversation ID from pinnedConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2]),
      };
      mutations[types.SET_CONVERSATION_UNPINNED](state, 1);
      expect(state.pinnedConversations.has(1)).toBe(false);
      expect(state.pinnedConversations.has(2)).toBe(true);
    });
  });

  describe('#SET_ALL_UNREAD_CONVERSATIONS', () => {
    it('replaces entire unreadConversations Set with new array', () => {
      const state = {
        unreadConversations: new Set([1, 2, 3]),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_ALL_UNREAD_CONVERSATIONS](state, [4, 5]);
      expect(state.unreadConversations.has(1)).toBe(false);
      expect(state.unreadConversations.has(4)).toBe(true);
      expect(state.unreadConversations.has(5)).toBe(true);
      expect(state.unreadConversations.size).toBe(2);
    });

    it('handles empty array', () => {
      const state = {
        unreadConversations: new Set([1, 2]),
        pinnedConversations: new Set(),
      };
      mutations[types.SET_ALL_UNREAD_CONVERSATIONS](state, []);
      expect(state.unreadConversations.size).toBe(0);
    });
  });

  describe('#SET_ALL_PINNED_CONVERSATIONS', () => {
    it('replaces entire pinnedConversations Set with new array', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2, 3]),
      };
      mutations[types.SET_ALL_PINNED_CONVERSATIONS](state, [4, 5]);
      expect(state.pinnedConversations.has(1)).toBe(false);
      expect(state.pinnedConversations.has(4)).toBe(true);
      expect(state.pinnedConversations.has(5)).toBe(true);
      expect(state.pinnedConversations.size).toBe(2);
    });
  });

  describe('#CLEAR_CONVERSATION_STATE', () => {
    it('clears both unread and pinned Sets', () => {
      const state = {
        unreadConversations: new Set([1, 2]),
        pinnedConversations: new Set([3, 4]),
      };
      mutations[types.CLEAR_CONVERSATION_STATE](state);
      expect(state.unreadConversations.size).toBe(0);
      expect(state.pinnedConversations.size).toBe(0);
    });
  });
});
