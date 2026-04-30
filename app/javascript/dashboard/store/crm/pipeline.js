import PipelineAPI from 'dashboard/api/crm/pipeline';

const state = {
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
};

const getters = {
  getAllPipelines: _state => _state.pipelines,
  getActivePipeline: _state =>
    _state.pipelines.find(p => p.id === _state.activePipelineId),
  getStages: _state => _state.stages,
  getConversationsByStage: _state => stageId =>
    _state.conversationsByStage[stageId] || [],
  getMetaByStage: _state => stageId =>
    _state.metaByStage[stageId] || { current_page: 1, total_pages: 1 },
  appliedFilters: _state => _state.filters,
  uiFlags: _state => _state.uiFlags,
};

const mutations = {
  SET_PIPELINES(_state, pipelines) {
    _state.pipelines = pipelines;
  },
  SET_ACTIVE_PIPELINE(_state, pipelineId) {
    _state.activePipelineId = pipelineId;
  },
  SET_STAGES(_state, stages) {
    _state.stages = stages;
  },
  SET_FILTER(_state, { key, value }) {
    _state.filters[key] = value;
  },
  CLEAR_FILTERS(_state) {
    _state.filters = { q: '', assigneeId: null, labels: [] };
  },
  SET_UI_FLAG(_state, { flag, value }) {
    _state.uiFlags[flag] = value;
  },
  SET_CONVERSATIONS(_state, { stageId, conversations, page }) {
    if (page === 1) {
      _state.conversationsByStage[stageId] = conversations;
    } else {
      _state.conversationsByStage[stageId] = [
        ...(_state.conversationsByStage[stageId] || []),
        ...conversations,
      ];
    }
  },
  SET_META(_state, { stageId, meta }) {
    _state.metaByStage[stageId] = meta;
  },
  RESET_STAGE_DATA(_state) {
    _state.conversationsByStage = {};
    _state.metaByStage = {};
  },
  REMOVE_CONVERSATION(_state, { stageId, conversationId }) {
    if (_state.conversationsByStage[stageId]) {
      _state.conversationsByStage[stageId] = _state.conversationsByStage[stageId].filter(
        c => c.id !== conversationId
      );
    }
  },
  ADD_CONVERSATION(_state, { stageId, conversation }) {
    if (!_state.conversationsByStage[stageId]) {
      _state.conversationsByStage[stageId] = [];
    }
    _state.conversationsByStage[stageId].push(conversation);
  },
};

const actions = {
  setFilter({ commit, dispatch }, { key, value }) {
    commit('SET_FILTER', { key, value });
    dispatch('refreshAllStages');
  },

  clearFilters({ commit, dispatch }) {
    commit('CLEAR_FILTERS');
    dispatch('refreshAllStages');
  },

  refreshAllStages({ state: _state, dispatch }) {
    _state.stages.forEach(stage => {
      dispatch('fetchConversations', { stageId: stage.id, page: 1 });
    });
  },

  async fetchPipelines({ commit, state: _state }) {
    commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: true });
    try {
      const response = await PipelineAPI.get();
      commit('SET_PIPELINES', response.data);
      if (response.data.length > 0 && !_state.activePipelineId) {
        commit('SET_ACTIVE_PIPELINE', response.data[0].id);
      }
    } catch (error) {
      // Handle error
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: false });
    }
  },

  async fetchStages({ commit }, pipelineId) {
    commit('SET_UI_FLAG', { flag: 'isFetchingStages', value: true });
    commit('SET_ACTIVE_PIPELINE', pipelineId);
    commit('RESET_STAGE_DATA');
    try {
      const response = await PipelineAPI.getStages(pipelineId);
      commit('SET_STAGES', response.data);
    } catch (error) {
      // Handle error
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingStages', value: false });
    }
  },

  async fetchConversations({ commit, state: _state }, { stageId, page = 1 }) {
    if (_state.uiFlags.isFetchingConversations) return;

    const meta = _state.metaByStage[stageId];
    if (page > 1 && meta && page > meta.total_pages) return;

    commit('SET_UI_FLAG', { flag: 'isFetchingConversations', value: true });
    try {
      const response = await PipelineAPI.getConversations(stageId, page, {
        q: _state.filters.q,
        assignee_id: _state.filters.assigneeId,
        labels: _state.filters.labels,
      });
      const { payload, meta: responseMeta } = response.data.data;

      commit('SET_CONVERSATIONS', { stageId, conversations: payload, page });
      commit('SET_META', { stageId, meta: responseMeta });
    } catch (error) {
      // Error handling
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingConversations', value: false });
    }
  },

  async moveConversation({ commit, state: _state, dispatch }, { conversationId, fromStageId, toStageId }) {
    const conversation = _state.conversationsByStage[fromStageId]?.find(
      c => c.id === conversationId
    );
    if (!conversation) return;

    const updatedConversation = {
      ...conversation,
      pipeline_stage_id: toStageId,
    };

    commit('REMOVE_CONVERSATION', { stageId: fromStageId, conversationId });
    commit('ADD_CONVERSATION', { stageId: toStageId, conversation: updatedConversation });

    try {
      await PipelineAPI.updateConversation(conversationId, toStageId);
    } catch (error) {
      // Rollback
      dispatch('fetchConversations', { stageId: fromStageId, page: 1 });
      dispatch('fetchConversations', { stageId: toStageId, page: 1 });
    }
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
