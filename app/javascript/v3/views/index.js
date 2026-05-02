import { createRouter, createWebHistory } from 'vue-router';

import routes from './routes';
import AnalyticsHelper from 'dashboard/helper/AnalyticsHelper';
import { validateRouteAccess } from '../helpers/RouteHelper';
import { installViteChunkReload } from 'shared/helpers/viteChunkReload';

export const router = createRouter({ history: createWebHistory(), routes });

const sensitiveRouteNames = ['auth_password_edit'];

export const initalizeRouter = () => {
  installViteChunkReload(router);

  router.beforeEach((to, _, next) => {
    if (!sensitiveRouteNames.includes(to.name)) {
      AnalyticsHelper.page(to.name || '', {
        path: to.path,
        name: to.name,
      });
    }

    return validateRouteAccess(to, next, window.chatwootConfig);
  });
};

export default router;
