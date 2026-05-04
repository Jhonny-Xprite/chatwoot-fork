import conversationState from '../../conversationState';

describe('#getters', () => {
  describe('#isConversationUnread', () => {
    it('returns true if conversation ID is in unreadConversations Set', () => {
      const state = {
        unreadConversations: new Set([1, 2, 3]),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.isConversationUnread(state);
      expect(getter(1)).toBe(true);
      expect(getter(2)).toBe(true);
    });

    it('returns false if conversation ID is not in unreadConversations Set', () => {
      const state = {
        unreadConversations: new Set([1, 2]),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.isConversationUnread(state);
      expect(getter(3)).toBe(false);
      expect(getter(4)).toBe(false);
    });

    it('returns false for empty Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.isConversationUnread(state);
      expect(getter(1)).toBe(false);
    });
  });

  describe('#isConversationPinned', () => {
    it('returns true if conversation ID is in pinnedConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2, 3]),
      };
      const getter = conversationState.getters.isConversationPinned(state);
      expect(getter(1)).toBe(true);
      expect(getter(2)).toBe(true);
    });

    it('returns false if conversation ID is not in pinnedConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2]),
      };
      const getter = conversationState.getters.isConversationPinned(state);
      expect(getter(3)).toBe(false);
    });
  });

  describe('#unreadCount', () => {
    it('returns the size of unreadConversations Set', () => {
      const state = {
        unreadConversations: new Set([1, 2, 3]),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.unreadCount(state);
      expect(getter).toBe(3);
    });

    it('returns 0 for empty Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.unreadCount(state);
      expect(getter).toBe(0);
    });
  });

  describe('#pinnedCount', () => {
    it('returns the size of pinnedConversations Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2]),
      };
      const getter = conversationState.getters.pinnedCount(state);
      expect(getter).toBe(2);
    });

    it('returns 0 for empty Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.pinnedCount(state);
      expect(getter).toBe(0);
    });
  });

  describe('#unreadConversationIds', () => {
    it('returns array of unread conversation IDs', () => {
      const state = {
        unreadConversations: new Set([1, 2, 3]),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.unreadConversationIds(state);
      expect(Array.isArray(getter)).toBe(true);
      expect(getter.length).toBe(3);
      expect(getter).toContain(1);
      expect(getter).toContain(2);
      expect(getter).toContain(3);
    });

    it('returns empty array for empty Set', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set(),
      };
      const getter = conversationState.getters.unreadConversationIds(state);
      expect(getter).toEqual([]);
    });
  });

  describe('#pinnedConversationIds', () => {
    it('returns array of pinned conversation IDs', () => {
      const state = {
        unreadConversations: new Set(),
        pinnedConversations: new Set([1, 2]),
      };
      const getter = conversationState.getters.pinnedConversationIds(state);
      expect(Array.isArray(getter)).toBe(true);
      expect(getter.length).toBe(2);
      expect(getter).toContain(1);
      expect(getter).toContain(2);
    });
  });
});
