<script setup>
import { ref, computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ContactImportMapper from './ContactImportMapper.vue';

const emit = defineEmits(['import']);
const { t } = useI18n();

const uiFlags = useMapGetter('contacts/getUIFlags');
const isImportingContact = computed(() => uiFlags.value.isImporting);

const dialogRef = ref(null);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');
const showMapper = ref(false);

const csvUrl = '/downloads/import-contacts-sample.csv';

const handleFileClick = () => fileInput.value?.click();

const processFileName = fileName => {
  const lastDotIndex = fileName.lastIndexOf('.');
  const extension = fileName.slice(lastDotIndex);
  const baseName = fileName.slice(0, lastDotIndex);

  return baseName.length > 20
    ? `${baseName.slice(0, 20)}...${extension}`
    : fileName;
};

const handleFileChange = () => {
  const file = fileInput.value?.files[0];
  hasSelectedFile.value = file;
  selectedFileName.value = file ? processFileName(file.name) : '';
};

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  selectedFileName.value = '';
  showMapper.value = false;
};

const proceedToMapping = () => {
  if (!hasSelectedFile.value) return;
  showMapper.value = true;
};

const onMapComplete = mapping => {
  emit('import', { file: hasSelectedFile.value, mapping });
};

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.TITLE')"
    :is-loading="isImportingContact"
    :disable-confirm-button="isImportingContact || !hasSelectedFile"
    :show-footer="!showMapper"
    size="medium"
    @confirm="proceedToMapping"
  >
    <template v-if="!showMapper" #description>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DESCRIPTION') }}
        <a
          :href="csvUrl"
          target="_blank"
          rel="noopener noreferrer"
          download="import-contacts-sample.csv"
          class="text-n-blue-11"
        >
          {{
            t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.DOWNLOAD_LABEL')
          }}
        </a>
      </p>
    </template>

    <div v-if="!showMapper" class="flex flex-col gap-2 py-4">
      <div class="flex items-center gap-2">
        <label class="text-sm text-n-slate-12 whitespace-nowrap">
          {{ t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.LABEL') }}
        </label>
        <div class="flex items-center justify-between w-full gap-2">
          <span v-if="hasSelectedFile" class="text-sm text-n-slate-12">
            {{ selectedFileName }}
          </span>
          <Button
            v-if="!hasSelectedFile"
            :label="
              t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CHOOSE_FILE')
            "
            icon="i-lucide-upload"
            color="slate"
            variant="ghost"
            size="sm"
            class="!w-fit"
            @click="handleFileClick"
          />
          <div class="flex items-center gap-1">
            <Button
              :label="t('CONTACTS_LAYOUT.HEADER.ACTIONS.IMPORT_CONTACT.CHANGE')"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleFileClick"
            />
            <div class="w-px h-3 bg-n-strong" />
            <Button
              icon="i-lucide-trash"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleRemoveFile"
            />
          </div>
        </div>
      </div>
    </div>

    <ContactImportMapper
      v-if="showMapper"
      :file="hasSelectedFile"
      @map="onMapComplete"
      @cancel="showMapper = false"
    />

    <input
      ref="fileInput"
      type="file"
      accept="text/csv"
      class="hidden"
      @change="handleFileChange"
    />
  </Dialog>
</template>
