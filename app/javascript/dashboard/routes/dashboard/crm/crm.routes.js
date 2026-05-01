import { frontendURL } from '../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';
import ConversationView from '../conversation/ConversationView.vue';
import ContactManageView from '../contacts/pages/ContactManageView.vue';

const CRMIndex = () => import('./Index.vue');
const CRMDashboard = () => import('./Dashboard.vue');
const CRMPipelines = () => import('./Pipelines.vue');
const CRMSettings = () => import('./Settings.vue');

const crmRouteMeta = {
  permissions: ROLES,
};

export default [
  {
    path: frontendURL('accounts/:accountId/crm'),
    component: CRMIndex,
    children: [
      {
        path: '',
        redirect: 'pipelines',
      },
      {
        path: 'dashboard',
        name: 'crm_dashboard_root',
        component: CRMDashboard,
        meta: crmRouteMeta,
      },
      {
        path: 'pipelines',
        name: 'crm_pipelines',
        component: CRMPipelines,
        meta: crmRouteMeta,
      },
      {
        path: 'pipelines/:pipelineId',
        name: 'crm_pipeline_details',
        component: CRMPipelines,
        props: route => ({
          pipelineId: route.params.pipelineId,
        }),
        meta: crmRouteMeta,
      },
      {
        path: 'views/:viewId',
        name: 'crm_view',
        component: CRMPipelines,
        props: route => ({
          viewId: route.params.viewId,
        }),
        meta: crmRouteMeta,
      },
      {
        path: 'contacts/:contactId',
        name: 'crm_contact',
        component: ContactManageView,
        meta: crmRouteMeta,
      },
      {
        path: 'conversations/:conversationId',
        name: 'crm_conversation',
        component: ConversationView,
        props: route => ({
          inboxId: 0,
          conversationId: route.params.conversationId,
        }),
        meta: crmRouteMeta,
      },
      {
        path: 'settings',
        name: 'crm_settings',
        component: CRMSettings,
        meta: crmRouteMeta,
      },
    ],
  },
];
