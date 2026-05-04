/**
 * Conversation State Module
 * Manages unread and pinned states for conversations
 * State: { unreadConversations: Set, pinnedConversations: Set }
 * Mutations: updateUnreadState, updatePinnedState
 * Actions: markUnread, markRead, markPinned, unmarkPinned
 */

import typesExport from '../mutation-types';
import ConversationApi from '../../api/conversations';

const types = typesExport;

const state = {
  unreadConversations: new Set(),
  pinnedConversations: new Set(),
};

const getters = {
  isConversationUnread: _state => conversationId => {
    return _state.unreadConversations.has(conversationId);
  },

  isConversationPinned: _state => conversationId => {
    return _state.pinnedConversations.has(conversationId);
  },

  unreadCount: _state => {
    return _state.unreadConversations.size;
  },

  pinnedCount: _state => {
    return _state.pinnedConversations.size;
  },

  unreadConversationIds: _state => {
    return Array.from(_state.unreadConversations);
  },

  pinnedConversationIds: _state => {
    return Array.from(_state.pinnedConversations);
  },
};

const mutations = {
  [types.SET_CONVERSATION_UNREAD](_state, conversationId) {
    _state.unreadConversations.add(conversationId);
  },

  [types.SET_CONVERSATION_READ](_state, conversationId) {
    _state.unreadConversations.delete(conversationId);
  },

  [types.SET_CONVERSATION_PINNED](_state, conversationId) {
    _state.pinnedConversations.add(conversationId);
  },

  [types.SET_CONVERSATION_UNPINNED](_state, conversationId) {
    _state.pinnedConversations.delete(conversationId);
  },

  [types.SET_ALL_UNREAD_CONVERSATIONS](_state, unreadIds) {
    _state.unreadConversations = new Set(unreadIds);
  },

  [types.SET_ALL_PINNED_CONVERSATIONS](_state, pinnedIds) {
    _state.pinnedConversations = new Set(pinnedIds);
  },

  [types.CLEAR_CONVERSATION_STATE](_state) {
    _state.unreadConversations.clear();
    _state.pinnedConversations.clear();
  },
};

const actions = {
  async markConversationUnread({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_UNREAD, conversationId);
    try {
      await ConversationApi.markUnread(conversationId);
    } catch (error) {
      commit(types.SET_CONVERSATION_READ, conversationId);
      throw error;
    }
  },

  async markConversationRead({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_READ, conversationId);
    try {
      await ConversationApi.markRead(conversationId);
    } catch (error) {
      commit(types.SET_CONVERSATION_UNREAD, conversationId);
      throw error;
    }
  },

  async markConversationPinned({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_PINNED, conversationId);
    try {
      await ConversationApi.markPinned(conversationId);
    } catch (error) {
      commit(types.SET_CONVERSATION_UNPINNED, conversationId);
      throw error;
    }
  },

  async unmarkConversationPinned({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_UNPINNED, conversationId);
    try {
      await ConversationApi.markUnpinned(conversationId);
    } catch (error) {
      commit(types.SET_CONVERSATION_PINNED, conversationId);
      throw error;
    }
  },

  async loadUnreadConversations({ commit }, conversations) {
    const unreadIds = conversations.filter(c => c.unread_at).map(c => c.id);
    commit(types.SET_ALL_UNREAD_CONVERSATIONS, unreadIds);
  },

  async loadPinnedConversations({ commit }, conversations) {
    const pinnedIds = conversations.filter(c => c.pinned_at).map(c => c.id);
    commit(types.SET_ALL_PINNED_CONVERSATIONS, pinnedIds);
  },

  clearConversationState({ commit }) {
    commit(types.CLEAR_CONVERSATION_STATE);
  },
};

export default {
  state,
  getters,
  mutations,
  actions,
};
