<script setup>
// Importação de utilitários do Vue e Chatwoot
import { computed, onMounted, ref } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

// Componentes da UI (Sistema Novo - Next)
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';

const store = useStore();
const { t } = useI18n();

// Estado reativo da página
const rules = ref([]); // Lista de regras de scoring vinda do banco
const createRuleDialogRef = ref(null); // Referência para abrir/fechar o modal
const isRecalculating = ref(false); // Estado de loading do botão de recálculo

// Getters para buscar atributos e etiquetas disponíveis no sistema
const contactAttributes = useMapGetter('attributes/getContactAttributes');
const conversationAttributes = useMapGetter(
  'attributes/getConversationAttributes'
);
const labels = useMapGetter('labels/getLabels');

// Estado do formulário de nova regra
const newRule = ref({
  attribute_model: 'contact_attribute', // Origem: Contato, Conversa ou Etiqueta
  attribute_key: '', // Chave do atributo selecionado
  filter_operator: 'equal_to', // Condição (Igual, Contém, etc)
  values: [], // Valores esperados para validar a regra
  score: 10, // Pontuação a ser atribuída
});

// Opções de operadores para o seletor da UI
const operators = [
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.EQUAL_TO') || 'Igual a',
    value: 'equal_to',
  },
  {
    label:
      t('CRM.SCORING.MODAL.CONDITION_LABELS.NOT_EQUAL_TO') || 'Diferente de',
    value: 'not_equal_to',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.CONTAINS') || 'Contém',
    value: 'contains',
  },
  {
    label:
      t('CRM.SCORING.MODAL.CONDITION_LABELS.DOES_NOT_CONTAIN') || 'Não contém',
    value: 'does_not_contain',
  },
  {
    label:
      t('CRM.SCORING.MODAL.CONDITION_LABELS.IS_PRESENT') || 'Está presente',
    value: 'is_present',
  },
  {
    label:
      t('CRM.SCORING.MODAL.CONDITION_LABELS.IS_NOT_PRESENT') ||
      'Não está presente',
    value: 'is_not_present',
  },
];

// Modelos de dados suportados pelo motor de scoring
const attributeModels = [
  { label: t('CRM.SCORING.MODELS.CONTACT'), value: 'contact_attribute' },
  {
    label: t('CRM.SCORING.MODELS.CONVERSATION'),
    value: 'conversation_attribute',
  },
  { label: t('CRM.SCORING.MODELS.LABEL'), value: 'label' },
];

// Filtra os atributos baseados na origem selecionada
const availableAttributes = computed(() => {
  if (newRule.value.attribute_model === 'contact_attribute') {
    return contactAttributes.value.map(a => ({
      label: a.attributeDisplayName,
      value: a.attributeKey,
    }));
  }
  if (newRule.value.attribute_model === 'conversation_attribute') {
    return conversationAttributes.value.map(a => ({
      label: a.attributeDisplayName,
      value: a.attributeKey,
    }));
  }
  return [{ label: t('CRM.LABELS'), value: 'labels' }];
});

// Busca as regras existentes no backend
const fetchRules = async () => {
  // eslint-disable-next-line no-console
  console.log('[CRM] Buscando regras de lead scoring...');
  try {
    const response = await window.axios.get(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules`
    );
    rules.value = response.data;
    // eslint-disable-next-line no-console
    console.log('[CRM] Regras carregadas:', rules.value.length);
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[CRM] Erro ao buscar regras:', error);
  }
};

// Dispara o recálculo total de pontos para todos os contatos (Job em background)
const recalculateAll = async () => {
  // eslint-disable-next-line no-console
  console.log('[CRM] Iniciando recálculo total de leads...');
  isRecalculating.value = true;
  try {
    await window.axios.post(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules/recalculate`
    );
    // eslint-disable-next-line no-console
    console.log('[CRM] Recálculo enfileirado com sucesso');
    useAlert(t('CRM.SCORING.RECALCULATE_SUCCESS'));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[CRM] Erro ao disparar recálculo:', error);
    useAlert(t('CRM.SCORING.RECALCULATE_ERROR'));
  } finally {
    isRecalculating.value = false;
  }
};

onMounted(() => {
  fetchRules();
  // Garante que atributos e etiquetas estejam carregados na store global
  store.dispatch('attributes/get');
  store.dispatch('labels/get');
});

// Prepara e abre o modal de criação
const openCreateModal = () => {
  newRule.value = {
    attribute_model: 'contact_attribute',
    attribute_key: '',
    filter_operator: 'equal_to',
    values: [],
    score: 10,
  };
  createRuleDialogRef.value?.open();
};

// Salva a nova regra no banco
const createRule = async () => {
  // eslint-disable-next-line no-console
  console.log('[CRM] Criando nova regra:', newRule.value);
  try {
    await window.axios.post(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules`,
      {
        lead_scoring_rule: newRule.value,
      }
    );
    // eslint-disable-next-line no-console
    console.log('[CRM] Regra criada com sucesso');
    createRuleDialogRef.value?.close();
    fetchRules();
    useAlert(t('CRM.SCORING.CREATE_SUCCESS'));
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[CRM] Erro ao criar regra:', error);
    useAlert(t('CRM.SCORING.CREATE_ERROR'));
  }
};

// Remove uma regra permanentemente
const deleteRule = async id => {
  try {
    await window.axios.delete(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules/${id}`
    );
    fetchRules();
    useAlert(t('CRM.SCORING.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(t('CRM.SCORING.DELETE_ERROR'));
  }
};

// Helpers para exibir labels amigáveis na tabela
const getModelLabel = value =>
  attributeModels.find(m => m.value === value)?.label || value;
const getOperatorLabel = value =>
  operators.find(o => o.value === value)?.label || value;

// Formata as etiquetas para o componente TagInput
const labelMenuItems = computed(() => {
  return labels.value.map(l => ({ label: l.title, value: l.title }));
});
</script>

<template>
  <div class="flex-1 p-6 overflow-auto bg-n-surface-1">
    <div class="max-w-6xl mx-auto">
      <div class="flex items-center justify-between mb-8">
        <div>
          <h2 class="text-2xl font-bold text-n-slate-12">
            {{ t('CRM.SCORING.TITLE') }}
          </h2>
          <p class="text-n-slate-11">
            {{ t('CRM.SCORING.SUBTITLE') }}
          </p>
        </div>
        <div class="flex gap-2">
          <NextButton
            :label="t('CRM.SCORING.RECALCULATE_ALL')"
            variant="faded"
            color="slate"
            icon="i-lucide-refresh-cw"
            :is-loading="isRecalculating"
            @click="recalculateAll"
          />
          <NextButton
            :label="t('CRM.SCORING.ADD_RULE')"
            icon="i-lucide-plus"
            color="blue"
            @click="openCreateModal"
          />
        </div>
      </div>

      <div
        class="overflow-hidden bg-white border dark:bg-n-slate-1 border-n-weak rounded-2xl shadow-sm"
      >
        <table class="w-full text-left">
          <thead class="border-b bg-n-alpha-1 border-n-weak">
            <tr>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11"
              >
                {{ t('CRM.SCORING.TABLE.SOURCE') }}
              </th>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11"
              >
                {{ t('CRM.SCORING.TABLE.FIELD') }}
              </th>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11"
              >
                {{ t('CRM.SCORING.TABLE.CONDITION') }}
              </th>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11"
              >
                {{ t('CRM.SCORING.TABLE.VALUE') }}
              </th>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11 text-center"
              >
                {{ t('CRM.SCORING.TABLE.POINTS') }}
              </th>
              <th
                class="px-6 py-4 text-xs font-bold uppercase tracking-wider text-n-slate-11"
              />
            </tr>
          </thead>
          <tbody class="divide-y divide-n-weak">
            <tr
              v-for="rule in rules"
              :key="rule.id"
              class="transition-colors hover:bg-n-alpha-1"
            >
              <td class="px-6 py-4 text-sm text-n-slate-12">
                {{ getModelLabel(rule.attribute_model) }}
              </td>
              <td class="px-6 py-4 text-sm font-medium text-n-slate-12">
                {{ rule.attribute_key }}
              </td>
              <td class="px-6 py-4 text-sm text-n-slate-11">
                {{ getOperatorLabel(rule.filter_operator) }}
              </td>
              <td class="px-6 py-4">
                <div class="flex flex-wrap gap-1">
                  <span
                    v-for="v in rule.values"
                    :key="v"
                    class="px-2 py-0.5 bg-n-alpha-2 rounded-full text-xs text-n-slate-12"
                  >
                    {{ v }}
                  </span>
                </div>
              </td>
              <td class="px-6 py-4 text-center">
                <span
                  class="font-black"
                  :class="rule.score >= 0 ? 'text-n-teal-11' : 'text-n-ruby-11'"
                >
                  {{ rule.score > 0 ? `+${rule.score}` : rule.score }}
                </span>
              </td>
              <td class="px-6 py-4 text-right">
                <NextButton
                  icon="i-lucide-trash-2"
                  variant="ghost"
                  color="ruby"
                  size="sm"
                  @click="deleteRule(rule.id)"
                />
              </td>
            </tr>
            <tr v-if="rules.length === 0">
              <td colspan="6" class="px-6 py-12 text-center text-n-slate-11">
                {{ t('CRM.SCORING.TABLE.EMPTY') }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- Create Rule Dialog -->
    <Dialog
      ref="createRuleDialogRef"
      :title="t('CRM.SCORING.MODAL.TITLE')"
      :confirm-button-label="t('CRM.SCORING.MODAL.CONFIRM')"
      width="md"
      @confirm="createRule"
    >
      <div class="flex flex-col gap-5 py-4">
        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-bold uppercase text-n-slate-11">
              {{ t('CRM.SCORING.MODAL.SOURCE_LABEL') }}
            </label>
            <select
              v-model="newRule.attribute_model"
              class="w-full h-10 px-3 border outline-none bg-n-alpha-1 border-n-weak rounded-xl text-sm focus:border-n-brand-primary"
            >
              <option
                v-for="m in attributeModels"
                :key="m.value"
                :value="m.value"
              >
                {{ m.label }}
              </option>
            </select>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-bold uppercase text-n-slate-11">
              {{ t('CRM.SCORING.MODAL.FIELD_LABEL') }}
            </label>
            <select
              v-model="newRule.attribute_key"
              class="w-full h-10 px-3 border outline-none bg-n-alpha-1 border-n-weak rounded-xl text-sm focus:border-n-brand-primary"
            >
              <option value="" disabled>
                {{ t('CRM.SCORING.MODAL.FIELD_PLACEHOLDER') }}
              </option>
              <option
                v-for="a in availableAttributes"
                :key="a.value"
                :value="a.value"
              >
                {{ a.label }}
              </option>
            </select>
          </div>
        </div>

        <div class="grid grid-cols-2 gap-4">
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-bold uppercase text-n-slate-11">
              {{ t('CRM.SCORING.MODAL.CONDITION_LABEL') }}
            </label>
            <select
              v-model="newRule.filter_operator"
              class="w-full h-10 px-3 border outline-none bg-n-alpha-1 border-n-weak rounded-xl text-sm focus:border-n-brand-primary"
            >
              <option v-for="o in operators" :key="o.value" :value="o.value">
                {{ o.label }}
              </option>
            </select>
          </div>
          <div class="flex flex-col gap-1.5">
            <label class="text-xs font-bold uppercase text-n-slate-11">
              {{ t('CRM.SCORING.MODAL.POINTS_LABEL') }}
            </label>
            <Input v-model="newRule.score" type="number" placeholder="Ex: 10" />
          </div>
        </div>

        <div
          v-if="
            !['is_present', 'is_not_present'].includes(newRule.filter_operator)
          "
          class="flex flex-col gap-1.5"
        >
          <label class="text-xs font-bold uppercase text-n-slate-11">
            {{ t('CRM.SCORING.MODAL.VALUES_LABEL') }}
          </label>
          <div v-if="newRule.attribute_model === 'label'">
            <TagInput
              v-model="newRule.values"
              :menu-items="labelMenuItems"
              :placeholder="t('CRM.SCORING.MODAL.LABELS_PLACEHOLDER')"
              show-dropdown
            />
          </div>
          <div v-else>
            <Input
              :value="newRule.values.join(', ')"
              :placeholder="t('CRM.SCORING.MODAL.VALUES_PLACEHOLDER')"
              @input="
                e =>
                  (newRule.values = e.target.value
                    .split(',')
                    .map(v => v.trim()))
              "
            />
          </div>
        </div>
      </div>
    </Dialog>
  </div>
</template>
