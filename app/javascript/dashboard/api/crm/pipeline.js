/* global axios */
import ApiClient from '../ApiClient';

class PipelineAPI extends ApiClient {
  constructor() {
    super('crm/pipelines', { accountScoped: true });
  }

  create(data) {
    return axios.post(this.url, data);
  }

  update(pipelineId, data) {
    return axios.patch(`${this.url}/${pipelineId}`, data);
  }

  delete(pipelineId) {
    return axios.delete(`${this.url}/${pipelineId}`);
  }

  getStages(pipelineId) {
    return axios.get(`${this.url}/${pipelineId}/stages`);
  }

  createStage(pipelineId, stageData) {
    return axios.post(`${this.url}/${pipelineId}/stages`, {
      stage: stageData,
    });
  }

  updateStage(pipelineId, stageId, stageData) {
    return axios.patch(`${this.url}/${pipelineId}/stages/${stageId}`, {
      stage: stageData,
    });
  }

  deleteStage(pipelineId, stageId) {
    return axios.delete(`${this.url}/${pipelineId}/stages/${stageId}`);
  }

  reorderStages(pipelineId, positions) {
    return axios.patch(`${this.url}/${pipelineId}/stages/reorder`, {
      positions,
    });
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
