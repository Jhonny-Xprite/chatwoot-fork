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
    isMovingConversation: false,
    loadingStages: {},
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
  isStageLoading: _state => stageId => !!_state.uiFlags.loadingStages[stageId],
};

const mutations = {
  SET_PIPELINES(_state, pipelines) {
    _state.pipelines = pipelines;
  },
  ADD_PIPELINE(_state, pipeline) {
    _state.pipelines.push(pipeline);
  },
  REMOVE_PIPELINE(_state, pipelineId) {
    _state.pipelines = _state.pipelines.filter(p => p.id !== pipelineId);
  },
  SET_ACTIVE_PIPELINE(_state, pipelineId) {
    _state.activePipelineId = pipelineId;
  },
  SET_STAGES(_state, stages) {
    _state.stages = stages;
  },
  ADD_STAGE(_state, stage) {
    _state.stages.push(stage);
  },
  UPDATE_STAGE(_state, stage) {
    const index = _state.stages.findIndex(s => s.id === stage.id);
    if (index > -1) {
      _state.stages.splice(index, 1, stage);
    }
  },
  REMOVE_STAGE(_state, stageId) {
    _state.stages = _state.stages.filter(s => s.id !== stageId);
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
  SET_STAGE_LOADING(_state, { stageId, value }) {
    const loadingStages = { ..._state.uiFlags.loadingStages };

    if (value) {
      loadingStages[stageId] = true;
    } else {
      delete loadingStages[stageId];
    }

    _state.uiFlags.loadingStages = loadingStages;
  },
  SET_CONVERSATIONS(_state, { stageId, conversations, page }) {
    if (page === 1) {
      _state.conversationsByStage[stageId] = conversations;
    } else {
      const existingConversations = _state.conversationsByStage[stageId] || [];
      const mergedConversations = [...existingConversations, ...conversations];

      _state.conversationsByStage[stageId] = mergedConversations.filter(
        (conversation, index, list) =>
          list.findIndex(item => item.id === conversation.id) === index
      );
    }
  },
  SET_META(_state, { stageId, meta }) {
    _state.metaByStage[stageId] = meta;
  },
  RESET_STAGE_DATA(_state) {
    _state.conversationsByStage = {};
    _state.metaByStage = {};
    _state.uiFlags.loadingStages = {};
  },
  UPDATE_STAGE_COUNT(_state, { stageId, delta }) {
    const meta = _state.metaByStage[stageId];
    if (!meta) return;

    _state.metaByStage[stageId] = {
      ...meta,
      total_count: Math.max((meta.total_count || 0) + delta, 0),
    };
  },
  UPDATE_CONVERSATION_STAGE(_state, { conversationId, stageId, pipelineId }) {
    // We update the conversation object itself wherever it is
    Object.keys(_state.conversationsByStage).forEach(key => {
      const conversations = _state.conversationsByStage[key] || [];
      const index = conversations.findIndex(c => c.id === conversationId);
      if (index > -1) {
        const conversation = conversations[index];
        // Only update if it actually changed to avoid unnecessary re-renders
        if (
          conversation.pipeline_stage_id !== stageId ||
          conversation.pipeline_id !== pipelineId
        ) {
          const updatedConversations = [...conversations];
          updatedConversations[index] = {
            ...conversation,
            pipeline_stage_id: stageId,
            pipeline_id: pipelineId,
          };
          _state.conversationsByStage[key] = updatedConversations;
        }
      }
    });
  },
  UPDATE_CONVERSATION(_state, conversation) {
    const stageId = conversation.pipeline_stage_id;
    if (!stageId) return;

    const conversations = _state.conversationsByStage[stageId] || [];
    const index = conversations.findIndex(c => c.id === conversation.id);
    if (index > -1) {
      // Create a new array and object to ensure reactivity
      const newConversations = [...conversations];
      newConversations[index] = { ...newConversations[index], ...conversation };
      _state.conversationsByStage[stageId] = newConversations;
    }
  },
  ADD_MESSAGE(_state, message) {
    const { conversation_id: conversationId } = message;
    Object.keys(_state.conversationsByStage).forEach(stageId => {
      const conversations = _state.conversationsByStage[stageId] || [];
      const index = conversations.findIndex(c => c.id === conversationId);
      if (index > -1) {
        const newConversations = [...conversations];
        const conv = { ...newConversations[index] };
        conv.last_non_activity_message = message;
        conv.updated_at = message.created_at;
        newConversations[index] = conv;
        _state.conversationsByStage[stageId] = newConversations;
      }
    });
  },
  REORDER_CONVERSATIONS(_state, { stageId, conversations }) {
    _state.conversationsByStage = {
      ..._state.conversationsByStage,
      [stageId]: conversations,
    };
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
      const pipelines = response.data;
      commit('SET_PIPELINES', pipelines);

      const activePipeline =
        pipelines.find(pipeline => pipeline.id === _state.activePipelineId) ||
        pipelines[0];

      if (activePipeline) {
        commit('SET_ACTIVE_PIPELINE', activePipeline.id);
        return activePipeline.id;
      }
    } catch (error) {
      // Handle error
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: false });
    }

    return null;
  },

  async createPipeline({ commit }, name) {
    try {
      const response = await PipelineAPI.create({ name });
      commit('ADD_PIPELINE', response.data);
      commit('SET_ACTIVE_PIPELINE', response.data.id);
      commit('SET_STAGES', []);
    } catch (error) {
      throw new Error(error);
    }
  },

  async deletePipeline({ commit, state: _state, dispatch }) {
    const pipelineId = _state.activePipelineId;
    if (!pipelineId) return;

    try {
      await PipelineAPI.delete(pipelineId);
      commit('REMOVE_PIPELINE', pipelineId);
      dispatch('fetchPipelines');
    } catch (error) {
      throw new Error(error);
    }
  },

  async fetchStages({ commit, state: _state }, pipelineId) {
    if (_state.activePipelineId === pipelineId && _state.stages.length > 0) {
      return; // Already fetched
    }

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
  async createStage({ commit, state: _state }, stageName) {
    try {
      const response = await PipelineAPI.createStage(_state.activePipelineId, {
        name: stageName,
        position: _state.stages.length,
      });
      commit('ADD_STAGE', response.data);
    } catch (error) {
      // Handle error
    }
  },

  async updateStage({ commit, state: _state }, { stageId, name }) {
    try {
      const response = await PipelineAPI.updateStage(
        _state.activePipelineId,
        stageId,
        { name }
      );
      commit('UPDATE_STAGE', response.data);
    } catch (error) {
      // Handle error
    }
  },

  async deleteStage({ commit, state: _state }, stageId) {
    try {
      await PipelineAPI.deleteStage(_state.activePipelineId, stageId);
      commit('REMOVE_STAGE', stageId);
    } catch (error) {
      // Handle error
    }
  },

  async fetchConversations({ commit, state: _state }, { stageId, page = 1 }) {
    const meta = _state.metaByStage[stageId];
    if (page > 1 && meta && page > meta.total_pages) return;
    if (_state.uiFlags.loadingStages[stageId]) return;

    commit('SET_STAGE_LOADING', { stageId, value: true });
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
      commit('SET_STAGE_LOADING', { stageId, value: false });
    }
  },

  async moveConversation(
    { commit, state: _state, dispatch },
    { conversationId, fromStageId, toStageId }
  ) {
    if (!fromStageId || fromStageId === toStageId) return;

    commit('SET_UI_FLAG', { flag: 'isMovingConversation', value: true });
    commit('UPDATE_CONVERSATION_STAGE', {
      conversationId,
      stageId: toStageId,
      pipelineId: _state.activePipelineId,
    });
    commit('UPDATE_STAGE_COUNT', { stageId: fromStageId, delta: -1 });
    commit('UPDATE_STAGE_COUNT', { stageId: toStageId, delta: 1 });

    try {
      await PipelineAPI.updateConversation(conversationId, toStageId);
    } catch (error) {
      dispatch('fetchConversations', { stageId: fromStageId, page: 1 });
      dispatch('fetchConversations', { stageId: toStageId, page: 1 });
    } finally {
      commit('SET_UI_FLAG', { flag: 'isMovingConversation', value: false });
    }
  },

  updateConversation({ commit }, conversation) {
    commit('UPDATE_CONVERSATION', conversation);
  },

  addMessage({ commit }, message) {
    commit('ADD_MESSAGE', message);
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
