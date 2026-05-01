<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const props = defineProps({
  file: { type: File, required: true },
});

const emit = defineEmits(['map', 'cancel']);
const { t } = useI18n();
const store = useStore();

const headers = ref([]);
const previewRow = ref({});
const mapping = ref({});
const isLoading = ref(true);

const isCreateAttributeModalOpen = ref(false);
const newAttribute = ref({
  displayName: '',
  displayType: 'text',
});

const contactAttributes = useMapGetter('attributes/getContactAttributes');

const standardFields = [
  { key: 'name', label: 'Name' },
  { key: 'email', label: 'Email' },
  { key: 'phone_number', label: 'Phone Number' },
  { key: 'identifier', label: 'External ID' },
  { key: 'company_name', label: 'Company Name' },
  { key: 'city', label: 'City' },
];

const availableFields = computed(() => {
  const fields = [...standardFields.map(f => ({ ...f, type: 'standard' }))];
  contactAttributes.value.forEach(attr => {
    fields.push({
      key: `custom_attribute:${attr.attributeKey}`,
      label: `${attr.attributeDisplayName} (Custom)`,
      type: 'custom',
    });
  });
  return fields;
});

const parseCsvPreview = () => {
  const reader = new FileReader();
  reader.onload = e => {
    const text = e.target.result;
    const lines = text.split(/\r?\n/);
    if (lines.length > 0) {
      const parseLine = (line, delimiter = ',') => {
        const result = [];
        let cur = '';
        let inQuote = false;
        for (let i = 0; i < line.length; i++) {
          const char = line[i];
          if (char === '"') inQuote = !inQuote;
          else if (char === delimiter && !inQuote) {
            result.push(cur.trim().replace(/^"|"$/g, ''));
            cur = '';
          } else cur += char;
        }
        result.push(cur.trim().replace(/^"|"$/g, ''));
        return result;
      };

      const firstLine = lines[0];
      const commaCount = (firstLine.match(/,/g) || []).length;
      const semicolonCount = (firstLine.match(/;/g) || []).length;
      const delimiter = semicolonCount > commaCount ? ';' : ',';

      headers.value = parseLine(firstLine, delimiter);
      if (lines.length > 1) {
        const values = parseLine(lines[1], delimiter);
        headers.value.forEach((header, index) => {
          previewRow.value[header] = values[index] || '';
          const lowerHeader = header.toLowerCase();
          const match = availableFields.value.find(
            f =>
              f.label.toLowerCase() === lowerHeader ||
              f.key.toLowerCase() === lowerHeader ||
              f.key.split(':').pop().toLowerCase() === lowerHeader
          );
          if (match) mapping.value[header] = match.key;
        });
      }
    }
    isLoading.value = false;
  };
  reader.readAsText(props.file.slice(0, 10000));
};

const handleImport = () => {
  emit('map', mapping.value);
};

const openCreateAttributeModal = () => {
  isCreateAttributeModalOpen.value = true;
};

const createCustomAttribute = async () => {
  if (!newAttribute.value.displayName) return;

  try {
    const attributeKey = newAttribute.value.displayName
      .toLowerCase()
      .replace(/[^a-z0-9]/g, '_')
      .replace(/_+/g, '_');

    await store.dispatch('attributes/create', {
      attribute_display_name: newAttribute.value.displayName,
      attribute_key: attributeKey,
      attribute_model: 'contact_attribute',
      attribute_display_type: newAttribute.value.displayType,
    });

    isCreateAttributeModalOpen.value = false;
    newAttribute.value = { displayName: '', displayType: 'text' };
  } catch (error) {
    // Error handled by store/alert
  }
};

onMounted(() => {
  parseCsvPreview();
});
</script>

<template>
  <div class="flex flex-col h-full gap-4 overflow-hidden min-h-[400px]">
    <div class="flex items-center justify-between gap-1">
      <div class="flex flex-col">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('CONTACTS_LAYOUT.IMPORT_MAPPER.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ t('CONTACTS_LAYOUT.IMPORT_MAPPER.DESCRIPTION') }}
        </p>
      </div>
      <Button
        label="Create New Field"
        icon="i-lucide-plus"
        variant="ghost"
        color="blue"
        size="sm"
        @click="openCreateAttributeModal"
      />
    </div>

    <div
      class="flex-1 overflow-y-auto border rounded-xl border-n-strong bg-n-alpha-1"
    >
      <table class="w-full text-left border-collapse">
        <thead
          class="sticky top-0 z-10 bg-n-surface-2 border-b border-n-strong shadow-sm"
        >
          <tr>
            <th
              class="px-4 py-3 text-xs font-semibold uppercase text-n-slate-11 tracking-wider"
            >
              Column in CSV
            </th>
            <th
              class="px-4 py-3 text-xs font-semibold uppercase text-n-slate-11 tracking-wider"
            >
              Example Value
            </th>
            <th
              class="px-4 py-3 text-xs font-semibold uppercase text-n-slate-11 tracking-wider"
            >
              Chatwoot Field
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-strong">
          <tr
            v-for="header in headers"
            :key="header"
            class="group hover:bg-n-alpha-2 transition-colors"
          >
            <td class="px-4 py-3">
              <span class="text-sm font-medium text-n-slate-12">{{
                header
              }}</span>
            </td>
            <td class="px-4 py-3">
              <span
                class="text-sm text-n-slate-10 italic truncate max-w-[200px] block"
                :title="previewRow[header]"
              >
                {{ previewRow[header] || '-' }}
              </span>
            </td>
            <td class="px-4 py-3">
              <select
                v-model="mapping[header]"
                class="w-full h-9 px-3 text-sm rounded-lg bg-n-surface-1 border border-n-strong focus:outline-none focus:ring-2 focus:ring-n-blue-8 transition-all appearance-none cursor-pointer hover:border-n-blue-7"
              >
                <option value="">Do not import</option>
                <optgroup label="Standard Fields">
                  <option
                    v-for="field in standardFields"
                    :key="field.key"
                    :value="field.key"
                  >
                    {{ field.label }}
                  </option>
                </optgroup>
                <optgroup
                  v-if="contactAttributes.length"
                  label="Custom Attributes"
                >
                  <option
                    v-for="attr in contactAttributes"
                    :key="attr.attributeKey"
                    :value="`custom_attribute:${attr.attributeKey}`"
                  >
                    {{ attr.attributeDisplayName }}
                  </option>
                </optgroup>
              </select>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div
      class="flex items-center justify-end gap-3 pt-4 border-t border-n-strong"
    >
      <Button
        :label="t('CONTACTS_LAYOUT.IMPORT_MAPPER.CANCEL')"
        color="slate"
        variant="ghost"
        @click="emit('cancel')"
      />
      <Button
        :label="t('CONTACTS_LAYOUT.IMPORT_MAPPER.PROCEED')"
        color="blue"
        variant="filled"
        @click="handleImport"
      />
    </div>

    <!-- Create Attribute Dialog -->
    <Dialog
      v-if="isCreateAttributeModalOpen"
      title="Create Custom Attribute"
      confirm-button-label="Create Field"
      @confirm="createCustomAttribute"
      @close="isCreateAttributeModalOpen = false"
    >
      <div class="flex flex-col gap-4 py-4">
        <Input
          v-model="newAttribute.displayName"
          label="Field Name"
          placeholder="e.g. Sales Tier"
          required
        />
        <div class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">Field Type</label>
          <select
            v-model="newAttribute.displayType"
            class="w-full h-10 px-3 text-sm rounded-lg bg-n-surface-1 border border-n-strong focus:outline-none focus:ring-2 focus:ring-n-blue-8 transition-all"
          >
            <option value="text">Text</option>
            <option value="number">Number</option>
            <option value="date">Date</option>
            <option value="link">Link</option>
            <option value="checkbox">Checkbox</option>
          </select>
        </div>
      </div>
    </Dialog>
  </div>
</template>

<style scoped>
select {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 24 24' stroke='%2364748b'%3E%3Cpath stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M19 9l-7 7-7-7'%3E%3C/path%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  background-size: 1rem;
}
</style>
