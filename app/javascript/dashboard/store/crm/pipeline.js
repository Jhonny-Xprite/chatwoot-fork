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
  findConversationById: _state => conversationId => {
    return Object.values(_state.conversationsByStage)
      .flat()
      .find(conversation => conversation.id === conversationId);
  },
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
    Object.keys(_state.conversationsByStage).forEach(key => {
      const conversations = _state.conversationsByStage[key] || [];
      const index = conversations.findIndex(c => c.id === conversationId);
      if (index > -1) {
        const conversation = conversations[index];
        const updatedConversations = [...conversations];
        updatedConversations[index] = {
          ...conversation,
          pipeline_stage_id: stageId,
          pipeline_id: pipelineId,
        };
        _state.conversationsByStage[key] = updatedConversations;
      }
    });
  },
  REORDER_CONVERSATIONS(_state, { stageId, conversations }) {
    _state.conversationsByStage = {
      ..._state.conversationsByStage,
      [stageId]: conversations,
    };
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
        // Increment unread count if it's an incoming message
        if (message.message_type === 0) {
          conv.unread_count = (conv.unread_count || 0) + 1;
        }
        newConversations[index] = conv;
        _state.conversationsByStage[stageId] = newConversations;
      }
    });
  },
  UPDATE_CONVERSATION(_state, conversation) {
    Object.keys(_state.conversationsByStage).forEach(stageId => {
      const conversations = _state.conversationsByStage[stageId] || [];
      const index = conversations.findIndex(c => c.id === conversation.id);
      if (index > -1) {
        const newConversations = [...conversations];
        newConversations[index] = {
          ...newConversations[index],
          ...conversation,
        };
        _state.conversationsByStage[stageId] = newConversations;
      }
    });
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
      // Log error but continue
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: false });
    }
    return null;
  },
  async fetchStages({ commit, state: _state }, pipelineId) {
    if (_state.activePipelineId === pipelineId && _state.stages.length > 0) {
      return;
    }
    commit('SET_UI_FLAG', { flag: 'isFetchingStages', value: true });
    commit('SET_ACTIVE_PIPELINE', pipelineId);
    commit('RESET_STAGE_DATA');
    try {
      const response = await PipelineAPI.getStages(pipelineId);
      commit('SET_STAGES', response.data);
    } catch (error) {
      // Log error but continue
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingStages', value: false });
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
      // Log error but continue
    } finally {
      commit('SET_STAGE_LOADING', { stageId, value: false });
    }
  },
  async moveConversation(
    { commit, state: _state, getters: crmGetters, dispatch },
    { conversationId, fromStageId, toStageId }
  ) {
    const conversation = crmGetters.findConversationById(conversationId);
    const currentStageId =
      fromStageId || conversation?.pipeline_stage_id || null;
    if (currentStageId === toStageId) return;

    commit('SET_UI_FLAG', { flag: 'isMovingConversation', value: true });
    commit('UPDATE_CONVERSATION_STAGE', {
      conversationId,
      stageId: toStageId,
      pipelineId: _state.activePipelineId,
    });

    if (currentStageId) {
      commit('UPDATE_STAGE_COUNT', { stageId: currentStageId, delta: -1 });
    }
    commit('UPDATE_STAGE_COUNT', { stageId: toStageId, delta: 1 });

    try {
      const response = await PipelineAPI.updateConversation(
        conversationId,
        toStageId
      );
      commit('UPDATE_CONVERSATION', response.data);
    } catch (error) {
      const refreshes = [
        dispatch('fetchConversations', { stageId: toStageId, page: 1 }),
      ];
      if (currentStageId) {
        refreshes.push(
          dispatch('fetchConversations', { stageId: currentStageId, page: 1 })
        );
      }
      await Promise.all(refreshes);
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
