import { frontendURL } from '../../../helper/URLHelper';
import { ROLES } from 'dashboard/constants/permissions.js';
const CRMIndex = () => import('./Index.vue');

export default [
  {
    path: frontendURL('accounts/:accountId/crm'),
    name: 'crm_dashboard',
    component: CRMIndex,
    meta: {
      permissions: ROLES,
    },
  },
];
