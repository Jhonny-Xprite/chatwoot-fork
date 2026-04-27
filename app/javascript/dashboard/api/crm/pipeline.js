/* global axios */
import ApiClient from '../ApiClient';

class PipelineAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  getStages(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/stages`);
  }

  getConversations(stageId, page = 1, filters = {}) {
    return axios.get(`${this.baseUrl()}/crm/pipeline_conversations`, {
      params: { stage_id: stageId, page, ...filters },
    });
  }

  updateConversation(conversationId, stageId) {
    return axios.patch(
      `${this.baseUrl()}/crm/pipeline_conversations/${conversationId}`,
      {
        stage_id: stageId,
      }
    );
  }
}

export default new PipelineAPI();
