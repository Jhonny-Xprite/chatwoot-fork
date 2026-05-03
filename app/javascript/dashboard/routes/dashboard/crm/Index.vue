<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';

const route = useRoute();
const { t } = useI18n();

const tabs = computed(() => [
  {
    name: 'Dashboard',
    routeName: 'crm_dashboard_root',
    icon: 'i-lucide-layout-dashboard',
  },
  {
    name: 'Pipelines',
    routeName: 'crm_pipelines',
    icon: 'i-lucide-kanban',
  },
  {
    name: 'Lead Scoring',
    routeName: 'crm_scoring',
    icon: 'i-lucide-award',
  },
  {
    name: t('CRM.TABS.SETTINGS') || 'Configurações',
    routeName: 'crm_settings',
    icon: 'i-lucide-settings-2',
  },
]);
</script>

<template>
  <div class="flex flex-col flex-1 h-full min-h-0 bg-n-surface-1">
    <!-- CRM Global Navigation -->
    <div
      class="flex items-center px-4 pt-4 bg-n-alpha-2 border-b border-n-weak"
    >
      <div class="flex gap-1">
        <router-link
          v-for="tab in tabs"
          :key="tab.routeName"
          :to="{ name: tab.routeName }"
          class="flex items-center gap-2 px-4 py-2 text-sm font-bold transition-all rounded-t-xl border-b-2"
          :class="
            route.name === tab.routeName
              ? 'text-n-brand-primary border-n-brand-primary bg-n-alpha-3'
              : 'text-n-slate-11 border-transparent hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
        >
          <span :class="tab.icon" class="text-lg" />
          {{ tab.name }}
        </router-link>
      </div>
    </div>

    <!-- Child View Container -->
    <div class="flex-1 flex flex-col min-h-0 overflow-hidden">
      <router-view />
    </div>
  </div>
</template>

<style scoped>
.router-link-active {
  /* Nuance for active state if needed beyond computed class */
}
</style>
