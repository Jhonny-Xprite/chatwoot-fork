<script setup>
import { computed, ref, watch } from 'vue';
import { useStore } from 'vuex';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import InlineInput from 'dashboard/components-next/inline-input/InlineInput.vue';
import AddLabel from 'dashboard/components-next/label/AddLabel.vue';
import NextLabel from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  conversation: {
    type: Object,
    required: true,
  },
});

defineEmits(['select']);

const store = useStore();

const contact = computed(() => props.conversation.meta?.sender || {});
const assignee = computed(() => props.conversation.meta?.assignee);
const labels = computed(() => props.conversation.labels || []);

const allLabels = computed(() => store.getters['labels/getLabels']);
const labelMenuItems = computed(() => {
  return allLabels.value.map(label => ({
    id: label.id,
    label: label.title,
    thumbnail: { color: label.color },
    active: labels.value.includes(label.title),
  }));
});

const isEditing = ref(false);
const editableName = ref(contact.value.name || '');
const editableEmail = ref(contact.value.email || '');
const editablePhone = ref(contact.value.phone_number || '');

watch(
  contact,
  newContact => {
    editableName.value = newContact.name || '';
    editableEmail.value = newContact.email || '';
    editablePhone.value = newContact.phone_number || '';
  },
  { deep: true }
);

const lastMessageContent = computed(() => {
  const lastMessage = props.conversation.last_non_activity_message;
  return lastMessage?.content || '';
});

const priorityBadgeClass = computed(() => {
  const priorities = {
    urgent: 'text-red-500 bg-red-50 dark:bg-red-900/20',
    high: 'text-orange-500 bg-orange-50 dark:bg-orange-900/20',
    medium: 'text-blue-500 bg-blue-50 dark:bg-blue-900/20',
    low: 'text-gray-500 bg-gray-50 dark:bg-gray-900/20',
  };
  return `px-1.5 py-0.5 text-[9px] uppercase font-bold rounded ${priorities[props.conversation.priority] || ''}`;
});

const toggleEdit = e => {
  e.stopPropagation();
  isEditing.value = !isEditing.value;
};

const saveContact = async () => {
  if (!isEditing.value) return;

  try {
    const response = await store.dispatch('contacts/update', {
      id: contact.value.id,
      name: editableName.value,
      email: editableEmail.value,
      phoneNumber: editablePhone.value,
    });

    store.dispatch('crmPipeline/updateConversation', {
      ...props.conversation,
      meta: {
        ...props.conversation.meta,
        sender: response.data.payload,
      },
    });

    isEditing.value = false;
  } catch (error) {
    // Error handled by store
  }
};

const cancelEdit = () => {
  editableName.value = contact.value.name || '';
  editableEmail.value = contact.value.email || '';
  editablePhone.value = contact.value.phone_number || '';
  isEditing.value = false;
};

const onUpdateLabel = async label => {
  const labelTitle = label.label;
  let newLabels = [...labels.value];
  if (newLabels.includes(labelTitle)) {
    newLabels = newLabels.filter(l => l !== labelTitle);
  } else {
    newLabels.push(labelTitle);
  }

  try {
    await store.dispatch('conversationLabels/update', {
      conversationId: props.conversation.id,
      labels: newLabels,
    });
    // Local update is usually handled by store subscription,
    // but we can force it if needed
  } catch (error) {
    // Error
  }
};

const removeLabel = labelTitle => {
  const newLabels = labels.value.filter(l => l !== labelTitle);
  store.dispatch('conversationLabels/update', {
    conversationId: props.conversation.id,
    labels: newLabels,
  });
};
</script>

<template>
  <div
    class="group/card p-3 mb-3 bg-white border rounded-lg shadow-sm border-n-weak hover:border-n-brand dark:bg-n-slate-1 transition-all cursor-grab active:cursor-grabbing relative"
    @click="!isEditing && $emit('select', conversation)"
  >
    <div class="flex items-start gap-2 mb-2">
      <Avatar
        :src="contact.thumbnail"
        :name="contact.name"
        size="20px"
        class="mt-0.5"
      />
      <div class="flex-1 min-w-0">
        <template v-if="!isEditing">
          <h3
            class="text-sm font-semibold text-n-slate-12 truncate leading-tight flex items-center gap-1"
          >
            {{ contact.name }}
            <button
              class="opacity-0 group-hover/card:opacity-100 p-0.5 hover:bg-n-slate-2 rounded transition-all"
              @click="toggleEdit"
            >
              <i class="i-lucide-pencil w-3 h-3 text-n-slate-10" />
            </button>
          </h3>
          <div class="flex flex-col gap-0.5 mt-1">
            <div
              v-if="contact.email"
              class="flex items-center gap-1.5 text-[11px] text-n-slate-11 truncate"
            >
              <i class="i-lucide-mail w-3 h-3 flex-shrink-0" />
              <span class="truncate">{{ contact.email }}</span>
            </div>
            <div
              v-if="contact.phone_number"
              class="flex items-center gap-1.5 text-[11px] text-n-slate-11"
            >
              <i class="i-lucide-phone w-3 h-3 flex-shrink-0" />
              <span>{{ contact.phone_number }}</span>
            </div>
          </div>
        </template>
        <template v-else>
          <div class="flex flex-col gap-2" @click.stop>
            <InlineInput
              v-model="editableName"
              placeholder="Nome"
              class="!h-7 font-semibold"
              focus-on-mount
              @enter-press="saveContact"
              @escape-press="cancelEdit"
            />
            <InlineInput
              v-model="editableEmail"
              placeholder="E-mail"
              class="!h-6 text-xs"
              @enter-press="saveContact"
              @escape-press="cancelEdit"
            />
            <InlineInput
              v-model="editablePhone"
              :placeholder="$t('CRM.PHONE')"
              class="!h-6 text-xs"
              @enter-press="saveContact"
              @escape-press="cancelEdit"
            />
            <div class="flex items-center gap-2 mt-1">
              <button
                class="px-2 py-1 bg-n-brand text-white text-[10px] rounded font-medium hover:brightness-110"
                @click="saveContact"
              >
                {{ $t('CRM.SAVE') }}
              </button>
              <button
                class="px-2 py-1 bg-n-slate-3 text-n-slate-11 text-[10px] rounded font-medium hover:bg-n-slate-4"
                @click="cancelEdit"
              >
                {{ $t('CRM.CANCEL') }}
              </button>
            </div>
          </div>
        </template>
      </div>
      <span v-if="conversation.priority" :class="priorityBadgeClass">
        {{ conversation.priority }}
      </span>
    </div>

    <p
      v-if="lastMessageContent && !isEditing"
      class="text-xs text-n-slate-11 mb-3 line-clamp-2"
    >
      {{ lastMessageContent }}
    </p>

    <!-- Labels Section -->
    <div class="flex flex-wrap gap-1 mb-3 min-h-[1.5rem]">
      <NextLabel
        v-for="label in labels"
        :key="label"
        :label="label"
        compact
        color="slate"
      >
        <template v-if="isEditing" #action>
          <button
            class="hover:text-n-ruby-9 transition-colors ml-1"
            @click.stop="removeLabel(label)"
          >
            <i class="i-lucide-x w-2.5 h-2.5" />
          </button>
        </template>
      </NextLabel>
      <AddLabel
        v-if="isEditing"
        :label-menu-items="labelMenuItems"
        @update-label="onUpdateLabel"
      />
    </div>

    <div class="flex items-center justify-end h-5">
      <Avatar
        v-if="assignee"
        :src="assignee.thumbnail"
        :name="assignee.name"
        size="20px"
        :title="assignee.name"
      />
    </div>
  </div>
</template>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
