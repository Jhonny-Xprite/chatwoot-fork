import { describe, it, expect, beforeEach } from 'vitest';
import { createStore } from 'vuex';
import crmPipelineModule from 'dashboard/store/crm/pipeline';

describe('Kanban Status Filter Tests', () => {
  let store;

  beforeEach(() => {
    store = createStore({
      modules: {
        crmPipeline: crmPipelineModule,
      },
    });
  });

  describe('Status Filter State Management', () => {
    it('should initialize with empty status filter', () => {
      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.status).toBe('');
    });

    it('should update status filter via setFilter action', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '1',
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.status).toBe('1');
    });

    it('should clear status filter when set to empty string', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '1',
      });

      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '',
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.status).toBe('');
    });

    it('should clear all filters including status', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '1',
      });

      await store.dispatch('crmPipeline/clearFilters');

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.status).toBe('');
    });

    it('should restore status filter from view object', async () => {
      const view = {
        query: {
          payload: [
            {
              attribute_key: 'stage_id',
              filter_operator: 'equal_to',
              values: ['5'],
            },
          ],
        },
      };

      // Simulate extracting filters from view
      const statusFilter = view.query.payload.find(
        f => f.attribute_key === 'stage_id'
      )?.values?.[0];

      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: statusFilter,
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.status).toBe('5');
    });
  });

  describe('Status Filter Combinations', () => {
    it('should work with search filter', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'q',
        value: 'John',
      });

      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '2',
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.q).toBe('John');
      expect(filters.status).toBe('2');
    });

    it('should work with labels filter', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'labels',
        value: ['vip', 'premium'],
      });

      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '3',
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.labels).toEqual(['vip', 'premium']);
      expect(filters.status).toBe('3');
    });

    it('should work with score band filter', async () => {
      await store.dispatch('crmPipeline/setFilter', {
        key: 'scoreBand',
        value: 'hot',
      });

      await store.dispatch('crmPipeline/setFilter', {
        key: 'status',
        value: '1',
      });

      const filters = store.getters['crmPipeline/appliedFilters'];
      expect(filters.scoreBand).toBe('hot');
      expect(filters.status).toBe('1');
    });
  });
});
