import PipelineAPI from 'dashboard/api/crm/pipeline';

// Helper: Extrai o timestamp de atividade mais recente de uma conversa
const getConversationActivityTimestamp = conversation => {
  return Number(
    conversation?.last_non_activity_message?.created_at ||
      conversation?.last_activity_at ||
      conversation?.updated_at ||
      conversation?.created_at ||
      0
  );
};

// Helper: Ordena conversas pela atividade mais recente (Padrão do Kanban)
const sortConversationsByActivity = conversations => {
  return [...conversations].sort((left, right) => {
    return (
      getConversationActivityTimestamp(right) -
      getConversationActivityTimestamp(left)
    );
  });
};

const state = {
  pipelines: [], // Lista de todos os funis de venda
  activePipelineId: null, // ID do funil selecionado atualmente
  stages: [], // Lista de estágios (colunas) da pipeline ativa
  conversationsByStage: {}, // Leads organizados por ID de estágio
  conversationLookupMap: {}, // O(1) lookup: Busca instantânea de leads por ID
  metaByStage: {}, // Metadados (paginação, total) de cada coluna
  filters: {
    q: '',
    assigneeId: null,
    labels: [],
    status: '',
    inboxId: null,
    teamId: null,
    priority: '',
  },
  uiFlags: {
    isFetchingPipelines: false,
    isFetchingStages: false,
    isMovingConversation: false,
    loadingStages: {},
  },
  viewPreferences: {
    // Preferências de visualização salvas no LocalStorage
    showLabels: true,
    showSla: true,
    showPriority: true,
    showAssignee: true,
    showLastMessage: true,
    showCompanyName: true,
    showChannel: true,
    showScore: true,
    density: 'comfortable', // Densidade: compact | comfortable
    customAttributes: [], // Chaves de atributos customizados para exibir no card
  },
};

const getters = {
  getAllPipelines: _state => _state.pipelines,
  getActivePipeline: _state =>
    _state.pipelines.find(p => p.id === _state.activePipelineId),
  getStages: _state =>
    [..._state.stages].sort(
      (a, b) => (a.position || 0) - (b.position || 0) || a.id - b.id
    ),
  getConversationsByStage: _state => stageId =>
    _state.conversationsByStage[stageId] || [],
  getMetaByStage: _state => stageId =>
    _state.metaByStage[stageId] || { current_page: 1, total_pages: 1 },
  appliedFilters: _state => _state.filters,
  uiFlags: _state => _state.uiFlags,
  isStageLoading: _state => stageId => !!_state.uiFlags.loadingStages[stageId],
  // Performance de Elite: Busca um lead sem precisar varrer todas as colunas
  findConversationById: _state => conversationId => {
    return _state.conversationLookupMap[conversationId] || null;
  },
  viewPreferences: _state => _state.viewPreferences,
};

const mutations = {
  // Atualiza as preferências de UI e persiste no navegador
  UPDATE_VIEW_PREFERENCES(_state, preferences) {
    _state.viewPreferences = {
      ..._state.viewPreferences,
      ...preferences,
    };
    localStorage.setItem(
      'chatwoot_crm_view_prefs',
      JSON.stringify(_state.viewPreferences)
    );
  },
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
    _state.filters = {
      q: '',
      assigneeId: null,
      labels: [],
      status: '',
      inboxId: null,
      teamId: null,
      priority: '',
    };
  },
  REPLACE_FILTERS(_state, filters) {
    _state.filters = {
      q: '',
      assigneeId: null,
      labels: [],
      status: '',
      inboxId: null,
      teamId: null,
      priority: '',
      ...filters,
    };
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
    // Seta os leads em uma coluna específica, garantindo que não haja duplicatas
    if (page === 1) {
      _state.conversationsByStage[stageId] =
        sortConversationsByActivity(conversations);
    } else {
      const existingConversations = _state.conversationsByStage[stageId] || [];
      const mergedConversations = [...existingConversations, ...conversations];
      const conversationMap = new Map();
      mergedConversations.forEach(c => conversationMap.set(c.id, c));
      _state.conversationsByStage[stageId] = sortConversationsByActivity(
        Array.from(conversationMap.values())
      );
    }

    // Atualiza o mapa de busca para manter a performance O(1)
    conversations.forEach(conversation => {
      _state.conversationLookupMap[conversation.id] = conversation;
    });
  },
  SET_META(_state, { stageId, meta }) {
    _state.metaByStage[stageId] = meta;
  },
  RESET_STAGE_DATA(_state) {
    _state.conversationsByStage = {};
    _state.metaByStage = {};
    _state.conversationLookupMap = {};
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
  UPSERT_CONVERSATION(_state, conversation) {
    // Adiciona ou atualiza um lead no Kanban de forma atômica
    const targetStageId = conversation.pipeline_stage_id;
    if (!targetStageId) return;

    // Remove o lead de QUALQUER outra coluna para evitar o bug de duplicação visual
    Object.keys(_state.conversationsByStage).forEach(stageId => {
      _state.conversationsByStage[stageId] = (
        _state.conversationsByStage[stageId] || []
      ).filter(item => item.id !== conversation.id);
    });

    const previousConversation = _state.conversationLookupMap[conversation.id];
    const mergedConversation = {
      ...previousConversation,
      ...conversation,
    };
    _state.conversationLookupMap[conversation.id] = mergedConversation;

    if (_state.conversationsByStage[targetStageId]) {
      const stageConversations = _state.conversationsByStage[targetStageId];
      const filtered = stageConversations.filter(c => c.id !== conversation.id);
      _state.conversationsByStage[targetStageId] = sortConversationsByActivity([
        mergedConversation,
        ...filtered,
      ]);
    }
  },
  UPDATE_CONVERSATION_STAGE(_state, { conversationId, stageId, pipelineId }) {
    const conversation = _state.conversationLookupMap[conversationId];
    if (conversation) {
      conversation.pipeline_stage_id = stageId;
      conversation.pipeline_id = pipelineId;
    }
  },
  ADD_MESSAGE(_state, message) {
    const { conversation_id: conversationId } = message;
    const conversation = _state.conversationLookupMap[conversationId];
    if (!conversation) return;

    conversation.last_non_activity_message = message;
    conversation.updated_at = message.created_at;
    conversation.last_activity_at = message.created_at;

    if (message.message_type === 0) {
      conversation.unread_count = (conversation.unread_count || 0) + 1;
    }
  },
};

const actions = {
  initializeViewPreferences({ commit }) {
    const savedPrefs = localStorage.getItem('chatwoot_crm_view_prefs');
    if (savedPrefs) {
      try {
        commit('UPDATE_VIEW_PREFERENCES', JSON.parse(savedPrefs));
      } catch (e) {
        // Ignore malformed JSON
      }
    }
  },
  setFilter({ commit, dispatch }, { key, value }) {
    commit('SET_FILTER', { key, value });
    return dispatch('refreshAllStages');
  },
  clearFilters({ commit, dispatch }) {
    commit('CLEAR_FILTERS');
    return dispatch('refreshAllStages');
  },
  replaceFilters({ commit, dispatch, state: _state }, filters) {
    commit('REPLACE_FILTERS', filters);
    if (_state.stages.length) {
      return dispatch('refreshAllStages');
    }
    return Promise.resolve();
  },
  refreshAllStages({ state: _state, dispatch }) {
    return Promise.all(
      _state.stages.map(stage =>
        dispatch('fetchConversations', { stageId: stage.id, page: 1 })
      )
    );
  },
  async fetchPipelines({ commit, state: _state }, preferredPipelineId = null) {
    commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: true });
    try {
      const response = await PipelineAPI.get();
      const pipelines = response.data;
      commit('SET_PIPELINES', pipelines);

      const activePipeline =
        pipelines.find(pipeline => pipeline.id === preferredPipelineId) ||
        pipelines.find(pipeline => pipeline.id === _state.activePipelineId) ||
        pipelines.find(pipeline => pipeline.is_default) ||
        pipelines[0];

      if (activePipeline) {
        commit('SET_ACTIVE_PIPELINE', activePipeline.id);
        return activePipeline.id;
      }
    } catch (error) {
      // Ignore error
    } finally {
      commit('SET_UI_FLAG', { flag: 'isFetchingPipelines', value: false });
    }

    return null;
  },
  async fetchStages({ commit, dispatch, state: _state }, pipelineId) {
    if (_state.activePipelineId === pipelineId && _state.stages.length > 0) {
      return;
    }

    commit('SET_UI_FLAG', { flag: 'isFetchingStages', value: true });
    commit('SET_ACTIVE_PIPELINE', pipelineId);
    commit('RESET_STAGE_DATA');

    try {
      const response = await PipelineAPI.getStages(pipelineId);
      const stages = response.data;
      commit('SET_STAGES', stages);

      await Promise.all(
        stages.map(stage =>
          dispatch('fetchConversations', { stageId: stage.id, page: 1 })
        )
      );
    } catch (error) {
      // Ignore error
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
        status: _state.filters.status,
        inbox_id: _state.filters.inboxId,
        team_id: _state.filters.teamId,
        priority: _state.filters.priority,
      });
      const { payload, meta: responseMeta } = response.data.data;
      commit('SET_CONVERSATIONS', { stageId, conversations: payload, page });
      commit('SET_META', { stageId, meta: responseMeta });
    } catch (error) {
      // Ignore error
    } finally {
      commit('SET_STAGE_LOADING', { stageId, value: false });
    }
  },
  async moveConversation(
    { commit, getters: crmGetters, dispatch, state: _state },
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
      commit('UPSERT_CONVERSATION', response.data);
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
    commit('UPSERT_CONVERSATION', conversation);
  },
  addConversation({ commit }, conversation) {
    commit('UPSERT_CONVERSATION', conversation);
  },
  addMessage({ commit }, message) {
    commit('ADD_MESSAGE', message);
  },
  async createPipeline({ dispatch }, name) {
    const response = await PipelineAPI.create({
      pipeline: {
        name,
      },
    });
    const nextPipelineId = await dispatch('fetchPipelines', response.data.id);

    if (nextPipelineId) {
      await dispatch('fetchStages', nextPipelineId);
    }

    return nextPipelineId;
  },
  async updatePipeline({ dispatch }, { pipelineId, pipeline }) {
    await PipelineAPI.update(pipelineId, { pipeline });
    const nextPipelineId = await dispatch('fetchPipelines');

    if (nextPipelineId) {
      await dispatch('fetchStages', nextPipelineId);
    }
  },
  async setDefaultPipeline({ dispatch }, pipelineId) {
    await dispatch('updatePipeline', {
      pipelineId,
      pipeline: { is_default: true },
    });
  },
  async createStage({ dispatch, state: _state }, { pipelineId, stage }) {
    const targetPipelineId = pipelineId || _state.activePipelineId;
    await PipelineAPI.createStage(targetPipelineId, stage);
    await dispatch('fetchStages', targetPipelineId);
  },
  async updateStage(
    { dispatch, state: _state },
    { pipelineId, stageId, stage }
  ) {
    const targetPipelineId = pipelineId || _state.activePipelineId;
    await PipelineAPI.updateStage(targetPipelineId, stageId, stage);
    await dispatch('fetchStages', targetPipelineId);
  },
  async deleteStage({ dispatch, state: _state }, { pipelineId, stageId }) {
    const targetPipelineId = pipelineId || _state.activePipelineId;
    await PipelineAPI.deleteStage(targetPipelineId, stageId);
    await dispatch('fetchStages', targetPipelineId);
  },
  async reorderStages({ dispatch, state: _state }, { pipelineId, stages }) {
    const targetPipelineId = pipelineId || _state.activePipelineId;
    await PipelineAPI.reorderStages(targetPipelineId, stages);
    await dispatch('fetchStages', targetPipelineId);
  },
  async deletePipeline({ dispatch }, pipelineId) {
    await PipelineAPI.delete(pipelineId);
    const nextPipelineId = await dispatch('fetchPipelines');

    if (nextPipelineId) {
      await dispatch('fetchStages', nextPipelineId);
    }

    return nextPipelineId;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  mutations,
  actions,
};
