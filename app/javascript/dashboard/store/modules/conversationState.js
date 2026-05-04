/**
 * Conversation State Module
 * Manages unread and pinned states for conversations
 * State: { unreadConversations: Set, pinnedConversations: Set }
 * Mutations: updateUnreadState, updatePinnedState
 * Actions: markUnread, markRead, markPinned, unmarkPinned
 */

import * as types from '../mutation-types';

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
    // TODO: Make API call to persist state
    // await ConversationAPI.markUnread(conversationId);
  },

  async markConversationRead({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_READ, conversationId);
    // TODO: Make API call to persist state
    // await ConversationAPI.markRead(conversationId);
  },

  async markConversationPinned({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_PINNED, conversationId);
    // TODO: Make API call to persist state
    // await ConversationAPI.markPinned(conversationId);
  },

  async unmarkConversationPinned({ commit }, conversationId) {
    commit(types.SET_CONVERSATION_UNPINNED, conversationId);
    // TODO: Make API call to persist state
    // await ConversationAPI.unmarkPinned(conversationId);
  },

  async loadUnreadConversations() {
    // TODO: Implement API call to load unread conversations
    // const { data } = await ConversationAPI.getUnread(accountId);
    // const unreadIds = data.map(c => c.id);
    // commit(types.SET_ALL_UNREAD_CONVERSATIONS, unreadIds);
  },

  async loadPinnedConversations() {
    // TODO: Implement API call to load pinned conversations
    // const { data } = await ConversationAPI.getPinned(accountId);
    // const pinnedIds = data.map(c => c.id);
    // commit(types.SET_ALL_PINNED_CONVERSATIONS, pinnedIds);
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
