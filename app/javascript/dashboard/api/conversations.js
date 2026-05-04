/* global axios */
import ApiClient from './ApiClient';

class ConversationApi extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  getLabels(conversationID) {
    return axios.get(`${this.url}/${conversationID}/labels`);
  }

  updateLabels(conversationID, labels) {
    return axios.post(`${this.url}/${conversationID}/labels`, { labels });
  }

  markUnread(conversationID) {
    return axios.patch(`${this.url}/${conversationID}`, {
      unread_at: new Date().toISOString(),
    });
  }

  markRead(conversationID) {
    return axios.patch(`${this.url}/${conversationID}`, {
      unread_at: null,
    });
  }

  markPinned(conversationID) {
    return axios.patch(`${this.url}/${conversationID}`, {
      pinned_at: new Date().toISOString(),
    });
  }

  markUnpinned(conversationID) {
    return axios.patch(`${this.url}/${conversationID}`, {
      pinned_at: null,
    });
  }
}

export default new ConversationApi();
