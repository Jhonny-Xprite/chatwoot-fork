import { frontendURL } from '../../../helper/URLHelper';
const CRMIndex = () => import('./Index.vue');

export default [
  {
    path: frontendURL('accounts/:accountId/crm'),
    name: 'crm_dashboard',
    component: CRMIndex,
    meta: {
      permissions: [],
    },
  },
];
