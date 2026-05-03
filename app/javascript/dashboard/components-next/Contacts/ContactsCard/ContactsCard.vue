<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import ContactDeleteSection from 'dashboard/components-next/Contacts/ContactsCard/ContactDeleteSection.vue';
import Checkbox from 'dashboard/components-next/checkbox/Checkbox.vue';
import countries from 'shared/constants/countries';
import Tooltip from 'dashboard/components-next/tooltip/Tooltip.vue';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  availabilityStatus: { type: String, default: null },
  isExpanded: { type: Boolean, default: false },
  isUpdating: { type: Boolean, default: false },
  selectable: { type: Boolean, default: false },
  isSelected: { type: Boolean, default: false },
});

const emit = defineEmits([
  'toggle',
  'updateContact',
  'showContact',
  'select',
  'avatarHover',
]);

const { t } = useI18n();
const router = useRouter();

const contactsFormRef = ref(null);

const getInitialContactData = () => ({
  id: props.id,
  name: props.name,
  email: props.email,
  phoneNumber: props.phoneNumber,
  additionalAttributes: props.additionalAttributes,
});

const contactData = ref(getInitialContactData());

const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const countryDetails = computed(() => {
  const attributes = props.additionalAttributes || {};
  const { country, countryCode, city } = attributes;

  if (!country && !countryCode) return null;

  const activeCountry =
    countriesMap.value[country] || countriesMap.value[countryCode];

  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';

  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const handleUpdateContact = () => {
  emit('updateContact', contactData.value);
};

const onClickExpand = () => {
  emit('toggle');
  contactData.value = getInitialContactData();
};

const onClickViewDetails = () => emit('showContact', props.id);

const toggleSelect = checked => {
  emit('select', checked);
};

const handleAvatarHover = isHovered => {
  emit('avatarHover', isHovered);
};

const startConversation = () => {
  router.push({
    name: 'conversations_new',
    params: { contactId: props.id },
  });
};
</script>

<template>
  <div class="group/contact-card relative">
    <CardLayout
      :key="id"
      layout="row"
      class="premium-contact-row !transition-all !duration-500 !ease-out"
      :class="{
        'selected-row !bg-n-brand-primary/5 !border-n-brand-primary/30':
          isSelected,
        'expanded-row': isExpanded,
      }"
    >
      <div class="flex items-center justify-start flex-1 gap-5">
        <!-- Avatar Section with Interaction -->
        <div
          class="relative avatar-container"
          @mouseenter="handleAvatarHover(true)"
          @mouseleave="handleAvatarHover(false)"
        >
          <div
            class="absolute -inset-2 bg-n-brand-primary/10 rounded-full opacity-0 scale-50 transition-all duration-500 group-hover/contact-card:opacity-100 group-hover/contact-card:scale-100"
          />
          <Avatar
            :name="name"
            :src="thumbnail"
            :size="56"
            :status="availabilityStatus"
            hide-offline-status
            rounded-full
            class="relative z-10 border-2 border-white dark:border-n-slate-1 shadow-md transition-transform duration-500 group-hover/contact-card:scale-105"
          >
            <template v-if="selectable || isSelected" #overlay="{ size }">
              <label
                class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-20 bg-black/20 backdrop-blur-[4px] border border-white/20 transition-all duration-300"
                :style="{ width: `${size}px`, height: `${size}px` }"
                @click.stop
              >
                <Checkbox
                  :model-value="isSelected"
                  class="transform scale-125"
                  @change="event => toggleSelect(event.target.checked)"
                />
              </label>
            </template>
          </Avatar>
        </div>

        <!-- Info Section -->
        <div class="flex flex-col gap-1 flex-1 min-w-0">
          <div class="flex flex-wrap items-center gap-x-3 gap-y-1">
            <h3
              class="text-lg font-black tracking-tight truncate text-n-slate-12 cursor-pointer hover:text-n-brand-primary transition-colors duration-300"
              @click="onClickViewDetails"
            >
              {{ name || t('CRM.UNKNOWN_CONTACT') }}
            </h3>

            <div
              v-if="additionalAttributes?.companyName"
              class="flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-n-slate-2 dark:bg-n-slate-3 border border-n-slate-3/50"
            >
              <span class="i-ph-building-fill size-3.5 text-n-slate-10" />
              <span
                class="text-[11px] font-bold uppercase tracking-wider text-n-slate-11"
              >
                {{ additionalAttributes.companyName }}
              </span>
            </div>
          </div>

          <div
            class="flex flex-wrap items-center justify-start gap-x-4 gap-y-1.5"
          >
            <!-- Email -->
            <div
              v-if="email"
              class="flex items-center gap-1.5 group/meta cursor-copy"
              :title="email"
            >
              <span
                class="i-lucide-mail size-3.5 text-n-slate-8 group-hover/meta:text-n-brand-primary transition-colors"
              />
              <span
                class="text-xs font-medium text-n-slate-11 group-hover/meta:text-n-slate-12 transition-colors"
              >
                {{ email }}
              </span>
            </div>

            <!-- Phone -->
            <div
              v-if="phoneNumber"
              class="flex items-center gap-1.5 group/meta cursor-copy"
            >
              <span
                class="i-lucide-phone size-3.5 text-n-slate-8 group-hover/meta:text-n-brand-primary transition-colors"
              />
              <span
                class="text-xs font-medium text-n-slate-11 group-hover/meta:text-n-slate-12 transition-colors"
              >
                {{ phoneNumber }}
              </span>
            </div>

            <!-- Location -->
            <div v-if="countryDetails" class="flex items-center gap-1.5">
              <Flag
                :country="countryDetails.countryCode"
                class="size-3.5 rounded-sm grayscale-[0.2]"
              />
              <span class="text-xs font-medium text-n-slate-11">
                {{ formattedLocation }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Actions Bar (Hidden by default, shown on hover) -->
      <div
        class="flex items-center gap-2 opacity-0 transform translate-x-4 transition-all duration-500 group-hover/contact-card:opacity-100 group-hover/contact-card:translate-x-0"
      >
        <Tooltip
          :content="t('CONTACTS_LAYOUT.HEADER.ACTIVE_TITLE')"
          placement="top"
        >
          <Button
            icon="i-lucide-message-square"
            variant="ghost"
            color="slate"
            size="sm"
            class="!rounded-xl hover:!bg-n-brand-primary hover:!text-white"
            @click="startConversation"
          />
        </Tooltip>

        <Tooltip :content="t('CRM.PIPELINE')" placement="top">
          <Button
            icon="i-lucide-kanban"
            variant="ghost"
            color="slate"
            size="sm"
            class="!rounded-xl hover:!bg-n-brand-primary hover:!text-white"
            @click="onClickViewDetails"
          />
        </Tooltip>

        <div class="w-px h-6 bg-n-slate-3 dark:bg-n-slate-2/30 mx-1" />

        <Button
          :icon="isExpanded ? 'i-lucide-chevron-up' : 'i-lucide-settings-2'"
          variant="ghost"
          color="slate"
          size="sm"
          class="!rounded-xl transition-all"
          :class="{ '!bg-n-slate-3 !text-n-brand-primary': isExpanded }"
          @click="onClickExpand"
        />
      </div>

      <template #after>
        <div
          class="transition-all duration-500 ease-in-out grid overflow-hidden"
          :class="
            isExpanded
              ? 'grid-rows-[1fr] opacity-100'
              : 'grid-rows-[0fr] opacity-0'
          "
        >
          <div class="overflow-hidden">
            <div
              class="flex flex-col gap-8 p-8 border-t border-n-slate-3/50 dark:border-n-slate-2/20 bg-n-slate-1/30 backdrop-blur-sm"
            >
              <ContactsForm
                ref="contactsFormRef"
                :contact-data="contactData"
                @update="handleFormUpdate"
              />
              <div class="flex items-center justify-end gap-3">
                <Button
                  :label="t('CRM.CANCEL')"
                  variant="ghost"
                  color="slate"
                  size="sm"
                  @click="onClickExpand"
                />
                <Button
                  :label="
                    t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')
                  "
                  size="sm"
                  variant="solid"
                  color="brand"
                  class="!px-8 !rounded-xl shadow-lg shadow-n-brand-primary/20"
                  :is-loading="isUpdating"
                  :disabled="isUpdating || isFormInvalid"
                  @click="handleUpdateContact"
                />
              </div>
            </div>
            <ContactDeleteSection
              class="bg-red-50/30 dark:bg-red-950/10"
              :selected-contact="{
                id: props.id,
                name: props.name,
              }"
            />
          </div>
        </div>
      </template>
    </CardLayout>
  </div>
</template>

<style scoped>
.premium-contact-row {
  @apply relative border border-n-slate-3/30 dark:border-n-slate-2/10 bg-white/40 dark:bg-n-slate-1/40 backdrop-blur-md shadow-sm rounded-2xl;
  transition: all 0.5s cubic-bezier(0.2, 0.8, 0.2, 1);
}

.premium-contact-row:hover {
  @apply border-n-brand-primary/20 dark:border-n-brand-primary/10 shadow-2xl shadow-n-brand-primary/5 -translate-y-1;
  background: linear-gradient(
    to bottom right,
    rgba(255, 255, 255, 0.9),
    rgba(255, 255, 255, 0.5)
  );
}

:global(.dark) .premium-contact-row:hover {
  background: linear-gradient(
    to bottom right,
    rgba(30, 41, 59, 0.6),
    rgba(15, 23, 42, 0.3)
  );
}

.selected-row {
  @apply ring-2 ring-n-brand-primary/50 ring-offset-4 dark:ring-offset-n-slate-1 !bg-n-brand-primary/5 !border-n-brand-primary/30;
}

.expanded-row {
  @apply !shadow-2xl !-translate-y-1 z-10 !border-n-brand-primary/40 !bg-white/60 dark:!bg-n-slate-1/60;
}

.avatar-container {
  perspective: 1000px;
}

.cursor-copy {
  cursor: pointer;
}

.cursor-copy:active {
  transform: scale(0.98);
}
</style>
