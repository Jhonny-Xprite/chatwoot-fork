<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

// Componentes da UI (Sistema Novo - Next)
import NextButton from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import TagInput from 'dashboard/components-next/taginput/TagInput.vue';
import Select from 'dashboard/components-next/select/Select.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

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
const operators = computed(() => [
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.EQUAL_TO'),
    value: 'equal_to',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.NOT_EQUAL_TO'),
    value: 'not_equal_to',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.CONTAINS'),
    value: 'contains',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.DOES_NOT_CONTAIN'),
    value: 'does_not_contain',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.IS_PRESENT'),
    value: 'is_present',
  },
  {
    label: t('CRM.SCORING.MODAL.CONDITION_LABELS.IS_NOT_PRESENT'),
    value: 'is_not_present',
  },
]);

// Modelos de dados suportados pelo motor de scoring
const attributeModels = computed(() => [
  { label: t('CRM.SCORING.MODELS.CONTACT'), value: 'contact_attribute' },
  {
    label: t('CRM.SCORING.MODELS.CONVERSATION'),
    value: 'conversation_attribute',
  },
  { label: t('CRM.SCORING.MODELS.LABEL'), value: 'label' },
]);

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

// Watch para resetar a chave do atributo quando o modelo muda
// eslint-disable-next-line no-unused-vars
watch(
  () => newRule.value.attribute_model,
  newModel => {
    if (newModel === 'label') {
      newRule.value.attribute_key = 'labels';
    } else {
      newRule.value.attribute_key = '';
    }
    newRule.value.values = [];
  }
);

// Busca as regras existentes no backend
const fetchRules = async () => {
  try {
    const response = await window.axios.get(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules`
    );
    rules.value = response.data;
  } catch (error) {
    // eslint-disable-next-line no-console
    console.error('[CRM] Erro ao buscar regras:', error);
  }
};

// Dispara o recálculo total de pontos para todos os contatos (Job em background)
const recalculateAll = async () => {
  isRecalculating.value = true;
  try {
    await window.axios.post(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules/recalculate`
    );
    useAlert(t('CRM.SCORING.RECALCULATE_SUCCESS'));
  } catch (error) {
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
  try {
    await window.axios.post(
      `/api/v1/accounts/${store.getters.getCurrentAccountId}/crm/lead_scoring_rules`,
      {
        lead_scoring_rule: newRule.value,
      }
    );
    createRuleDialogRef.value?.close();
    fetchRules();
    useAlert(t('CRM.SCORING.CREATE_SUCCESS'));
  } catch (error) {
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
  attributeModels.value.find(m => m.value === value)?.label || value;
const getOperatorLabel = value =>
  operators.value.find(o => o.value === value)?.label || value;

// Formata as etiquetas para o componente TagInput
const labelMenuItems = computed(() => {
  return labels.value.map(l => ({ label: l.title, value: l.title }));
});

const getRuleIcon = model => {
  if (model === 'contact_attribute') return 'i-lucide-user';
  if (model === 'conversation_attribute') return 'i-lucide-message-square';
  return 'i-lucide-tag';
};
</script>

<template>
  <div class="flex-1 overflow-auto bg-n-surface-1">
    <div class="max-w-5xl px-8 py-10 mx-auto">
      <header class="flex items-end justify-between mb-12">
        <div class="flex flex-col gap-1">
          <h2 class="text-3xl font-bold tracking-tight text-n-slate-12">
            {{ t('CRM.SCORING.TITLE') }}
          </h2>
          <p class="text-base text-n-slate-11">
            {{ t('CRM.SCORING.SUBTITLE') }}
          </p>
        </div>
        <div class="flex items-center gap-3">
          <NextButton
            variant="faded"
            color="slate"
            icon="i-lucide-refresh-cw"
            :is-loading="isRecalculating"
            class="!bg-white dark:!bg-n-slate-2"
            @click="recalculateAll"
          >
            {{ t('CRM.SCORING.RECALCULATE_ALL') }}
          </NextButton>
          <NextButton
            icon="i-lucide-plus"
            color="blue"
            size="lg"
            @click="openCreateModal"
          >
            {{ t('CRM.SCORING.ADD_RULE') }}
          </NextButton>
        </div>
      </header>

      <div class="flex flex-col gap-4">
        <div
          v-for="rule in rules"
          :key="rule.id"
          class="group relative flex items-center justify-between p-5 transition-all bg-white border border-n-weak rounded-2xl hover:border-n-brand-primary/30 hover:shadow-md dark:bg-n-slate-1"
        >
          <div class="flex items-center flex-1 gap-6 min-w-0">
            <div
              class="flex items-center justify-center flex-shrink-0 size-12 rounded-xl bg-n-alpha-1 text-n-slate-11 group-hover:text-n-brand-primary group-hover:bg-n-brand-primary-alpha-1 transition-colors"
            >
              <Icon :icon="getRuleIcon(rule.attribute_model)" class="size-6" />
            </div>

            <div class="flex flex-col gap-0.5 min-w-0 flex-1">
              <div class="flex items-center gap-2">
                <span
                  class="text-[10px] font-black uppercase tracking-widest text-n-slate-9"
                >
                  {{ getModelLabel(rule.attribute_model) }}
                </span>
                <span class="size-1 rounded-full bg-n-slate-4" />
                <span class="text-sm font-bold text-n-slate-12 truncate">
                  {{ rule.attribute_key }}
                </span>
              </div>
              <div class="flex items-center gap-2 text-sm text-n-slate-11">
                <span class="italic">{{
                  getOperatorLabel(rule.filter_operator)
                }}</span>
                <div v-if="rule.values.length" class="flex flex-wrap gap-1.5">
                  <span
                    v-for="v in rule.values"
                    :key="v"
                    class="px-2 py-0.5 bg-n-alpha-2 border border-n-strong rounded-md text-[11px] font-bold text-n-slate-12"
                  >
                    {{ v }}
                  </span>
                </div>
              </div>
            </div>

            <div class="flex flex-col items-end pr-4 border-r border-n-weak">
              <span
                class="text-2xl font-black tabular-nums tracking-tighter"
                :class="rule.score >= 0 ? 'text-n-teal-11' : 'text-n-ruby-11'"
              >
                {{ rule.score > 0 ? `+${rule.score}` : rule.score }}
              </span>
              <span class="text-[9px] font-black uppercase text-n-slate-9">
                {{ t('CRM.SCORING.MODAL.POINTS_UNIT') }}
              </span>
            </div>
          </div>

          <div class="flex items-center pl-4">
            <NextButton
              icon="i-lucide-trash-2"
              variant="ghost"
              color="ruby"
              size="sm"
              class="opacity-0 group-hover:opacity-100 transition-opacity"
              @click="deleteRule(rule.id)"
            />
          </div>
        </div>

        <div
          v-if="rules.length === 0"
          class="flex flex-col items-center justify-center py-20 bg-n-alpha-1 border border-dashed border-n-strong rounded-3xl"
        >
          <div
            class="flex items-center justify-center size-16 mb-4 rounded-full bg-n-alpha-2 text-n-slate-9"
          >
            <Icon icon="i-lucide-scroll-text" class="size-8" />
          </div>
          <p class="text-base font-medium text-n-slate-11 text-center max-w-sm">
            {{ t('CRM.SCORING.TABLE.EMPTY') }}
          </p>
          <NextButton
            variant="ghost"
            color="blue"
            class="mt-4"
            @click="openCreateModal"
          >
            {{ t('CRM.SCORING.MODAL.START_NOW') }}
          </NextButton>
        </div>
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
      <div class="flex flex-col gap-6 py-6">
        <!-- Passo 1: Origem e Campo -->
        <div
          class="flex flex-col gap-4 p-4 rounded-2xl bg-n-alpha-1 border border-n-strong"
        >
          <div class="flex items-center gap-2 mb-1">
            <span
              class="flex items-center justify-center size-5 rounded-full bg-n-brand-primary text-[10px] font-bold text-white"
            >
              {{ 1 }}
            </span>
            <h4
              class="text-xs font-black uppercase tracking-tight text-n-slate-12"
            >
              {{ t('CRM.SCORING.MODAL.STEP_1') }}
            </h4>
          </div>

          <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <div class="flex flex-col gap-1.5">
              <label class="text-[11px] font-bold text-n-slate-11 ml-1">
                {{ t('CRM.SCORING.MODAL.SOURCE_LABEL') }}
              </label>
              <Select
                v-model="newRule.attribute_model"
                :options="attributeModels"
                class="!w-full"
              />
            </div>
            <div class="flex flex-col gap-1.5">
              <label class="text-[11px] font-bold text-n-slate-11 ml-1">
                {{ t('CRM.SCORING.MODAL.FIELD_LABEL') }}
              </label>
              <Select
                v-model="newRule.attribute_key"
                :options="availableAttributes"
                :placeholder="t('CRM.SCORING.MODAL.FIELD_PLACEHOLDER')"
                class="!w-full"
              />
            </div>
          </div>
        </div>

        <!-- Passo 2: Condição -->
        <div
          class="flex flex-col gap-4 p-4 rounded-2xl bg-n-alpha-1 border border-n-strong"
        >
          <div class="flex items-center gap-2 mb-1">
            <span
              class="flex items-center justify-center size-5 rounded-full bg-n-brand-primary text-[10px] font-bold text-white"
            >
              {{ 2 }}
            </span>
            <h4
              class="text-xs font-black uppercase tracking-tight text-n-slate-12"
            >
              {{ t('CRM.SCORING.MODAL.STEP_2') }}
            </h4>
          </div>

          <div class="flex flex-col gap-4">
            <div class="flex flex-col gap-1.5">
              <label class="text-[11px] font-bold text-n-slate-11 ml-1">
                {{ t('CRM.SCORING.MODAL.CONDITION_LABEL') }}
              </label>
              <Select
                v-model="newRule.filter_operator"
                :options="operators"
                class="!w-full"
              />
            </div>

            <div
              v-if="
                !['is_present', 'is_not_present'].includes(
                  newRule.filter_operator
                )
              "
              class="flex flex-col gap-1.5"
            >
              <label class="text-[11px] font-bold text-n-slate-11 ml-1">
                {{ t('CRM.SCORING.MODAL.VALUES_LABEL') }}
              </label>
              <div v-if="newRule.attribute_model === 'label'">
                <TagInput
                  v-model="newRule.values"
                  :menu-items="labelMenuItems"
                  :placeholder="t('CRM.SCORING.MODAL.LABELS_PLACEHOLDER')"
                  show-dropdown
                  class="!rounded-xl"
                />
              </div>
              <div v-else>
                <Input
                  :value="newRule.values.join(', ')"
                  :placeholder="t('CRM.SCORING.MODAL.VALUES_PLACEHOLDER')"
                  class="!rounded-xl"
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
        </div>

        <!-- Passo 3: Pontuação -->
        <div
          class="flex flex-col gap-4 p-4 rounded-2xl bg-n-teal-1/30 border border-n-teal-3 dark:bg-n-teal-9/10 dark:border-n-teal-8/30"
        >
          <div class="flex items-center gap-2 mb-1">
            <span
              class="flex items-center justify-center size-5 rounded-full bg-n-teal-9 text-[10px] font-bold text-white"
            >
              {{ 3 }}
            </span>
            <h4
              class="text-xs font-black uppercase tracking-tight text-n-teal-11"
            >
              {{ t('CRM.SCORING.MODAL.STEP_3') }}
            </h4>
          </div>

          <div class="flex items-center gap-4">
            <div class="flex-1 flex flex-col gap-1.5">
              <label class="text-[11px] font-bold text-n-teal-11 ml-1">
                {{ t('CRM.SCORING.MODAL.POINTS_LABEL') }}
              </label>
              <Input
                v-model="newRule.score"
                type="number"
                placeholder="Ex: 10"
                class="!bg-white dark:!bg-n-slate-1 !border-n-teal-4/50 !rounded-xl"
              />
            </div>
            <div
              class="flex items-center gap-2 px-4 py-3 rounded-xl bg-white dark:bg-n-slate-1 border border-n-weak shadow-sm self-end h-[42px]"
            >
              <span class="text-sm font-bold text-n-slate-11">
                {{ t('CRM.SCORING.MODAL.RESULT') }}
              </span>
              <span
                class="text-lg font-black"
                :class="
                  newRule.score >= 0 ? 'text-n-teal-11' : 'text-n-ruby-11'
                "
              >
                {{ newRule.score > 0 ? `+${newRule.score}` : newRule.score }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </Dialog>
  </div>
</template>

<style scoped>
/* Transição suave para os cards */
.group {
  backface-visibility: hidden;
  transform: translateZ(0);
}
</style>
