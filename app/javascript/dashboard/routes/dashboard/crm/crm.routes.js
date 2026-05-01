import { frontendURL } from '../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';

const CRMIndex = () => import('./Index.vue');
const CRMDashboard = () => import('./Dashboard.vue');
const CRMPipelines = () => import('./Pipelines.vue');
const CRMSettings = () => import('./Settings.vue');
const CRMScoring = () => import('./LeadScoring.vue');

export default [
  {
    path: frontendURL('accounts/:accountId/crm'),
    component: CRMIndex,
    children: [
      {
        path: '',
        redirect: 'dashboard',
      },
      {
        path: 'dashboard',
        name: 'crm_dashboard_root',
        component: CRMDashboard,
        meta: {
          permissions: ROLES,
        },
      },
      {
        path: 'pipelines',
        name: 'crm_pipelines',
        component: CRMPipelines,
        meta: {
          permissions: ROLES,
        },
      },
      {
        path: 'scoring',
        name: 'crm_scoring',
        component: CRMScoring,
        meta: {
          permissions: ROLES,
        },
      },
      {
        path: 'settings',
        name: 'crm_settings',
        component: CRMSettings,
        meta: {
          permissions: ROLES,
        },
      },
    ],
  },
];
