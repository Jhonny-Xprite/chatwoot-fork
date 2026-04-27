import { defineStore } from 'pinia';
import PipelineAPI from 'dashboard/api/crm/pipeline';

export const useCrmPipelineStore = defineStore('crmPipeline', {
  state: () => ({
    pipelines: [],
    activePipelineId: null,
    stages: [],
    conversationsByStage: {},
    metaByStage: {},
    filters: {
      q: '',
      assigneeId: null,
      labels: [],
    },
    uiFlags: {
      isFetchingPipelines: false,
      isFetchingStages: false,
      isFetchingConversations: false,
    },
  }),

  getters: {
    getAllPipelines: state => state.pipelines,
    getActivePipeline: state =>
      state.pipelines.find(p => p.id === state.activePipelineId),
    getStages: state => state.stages,
    getConversationsByStage: state => stageId =>
      state.conversationsByStage[stageId] || [],
    getMetaByStage: state => stageId =>
      state.metaByStage[stageId] || { current_page: 1, total_pages: 1 },
    appliedFilters: state => state.filters,
  },

  actions: {
    setFilter(key, value) {
      this.filters[key] = value;
      this.refreshAllStages();
    },

    clearFilters() {
      this.filters = { q: '', assigneeId: null, labels: [] };
      this.refreshAllStages();
    },

    refreshAllStages() {
      this.stages.forEach(stage => {
        this.fetchConversations(stage.id, 1);
      });
    },

    async fetchPipelines() {
      this.uiFlags.isFetchingPipelines = true;
      try {
        const response = await PipelineAPI.get();
        this.pipelines = response.data;
        if (this.pipelines.length > 0 && !this.activePipelineId) {
          this.activePipelineId = this.pipelines[0].id;
        }
      } catch (error) {
        // Handle error
      } finally {
        this.uiFlags.isFetchingPipelines = false;
      }
    },

    async fetchStages(pipelineId) {
      this.uiFlags.isFetchingStages = true;
      this.activePipelineId = pipelineId;
      try {
        const response = await PipelineAPI.getStages(pipelineId);
        this.stages = response.data;
        // Reset conversations mapping for new pipeline
        this.conversationsByStage = {};
        this.metaByStage = {};
      } catch (error) {
        // Handle error
      } finally {
        this.uiFlags.isFetchingStages = false;
      }
    },

    async fetchConversations(stageId, page = 1) {
      if (this.uiFlags.isFetchingConversations) return;

      const meta = this.metaByStage[stageId];
      if (page > 1 && meta && page > meta.total_pages) return;

      this.uiFlags.isFetchingConversations = true;
      try {
        const response = await PipelineAPI.getConversations(stageId, page, {
          q: this.filters.q,
          assignee_id: this.filters.assigneeId,
          labels: this.filters.labels,
        });
        // Matching Jbuilder structure: { data: { payload: [...], meta: {...} } }
        const { payload, meta: responseMeta } = response.data.data;

        if (page === 1) {
          this.conversationsByStage[stageId] = payload;
        } else {
          this.conversationsByStage[stageId] = [
            ...(this.conversationsByStage[stageId] || []),
            ...payload,
          ];
        }
        this.metaByStage[stageId] = responseMeta;
      } catch (error) {
        // Error handling
      } finally {
        this.uiFlags.isFetchingConversations = false;
      }
    },

    async moveConversation({ conversationId, fromStageId, toStageId }) {
      // Find the conversation to move
      const conversation = this.conversationsByStage[fromStageId]?.find(
        c => c.id === conversationId
      );
      if (!conversation) return;

      // Optimistic update: move in UI immediately
      this.conversationsByStage[fromStageId] = this.conversationsByStage[
        fromStageId
      ].filter(c => c.id !== conversationId);
      if (!this.conversationsByStage[toStageId])
        this.conversationsByStage[toStageId] = [];

      // Update local stage ID
      const updatedConversation = {
        ...conversation,
        pipeline_stage_id: toStageId,
      };
      this.conversationsByStage[toStageId].push(updatedConversation);

      try {
        await PipelineAPI.updateConversation(conversationId, toStageId);
      } catch (error) {
        // Rollback on failure
        this.fetchConversations(fromStageId, 1);
        this.fetchConversations(toStageId, 1);
      }
    },
  },
});
