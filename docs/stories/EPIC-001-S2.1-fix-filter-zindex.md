# Story 2.1: Fix Z-INDEX do Filtro

**ID:** EPIC-001-S2.1  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 2 - Funcionalidade  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como usuário,
Quero que o filtro seja acessível e não fique escondido atrás de outros elementos,
Para que eu consiga filtrar conversas/cards eficientemente.
```

---

## Descrição

Filtro tem problema de Z-INDEX - fica escondido atrás de cards, headers, outros elementos. Dropdown é inacessível e não clicável. Precisa aparecer sempre acima.

---

## Acceptance Criteria

- [ ] Dropdown do filtro aparece acima de todos os cards (z-index adequado)
- [ ] Dropdown não é cortado nas bordas da viewport (repositioning automático)
- [ ] Clique fora do dropdown fecha ele (comportamento padrão)
- [ ] Z-index >= 50 (ou apropriado para stack context da app)
- [ ] Funciona em todas as resoluções (mobile 320px, tablet, desktop 1920px+)
- [ ] Funciona com scroll ativo (não some ao scrollar)
- [ ] Acessibilidade: navegação via Tab e Escape funciona
- [ ] Teste com DevTools (inspecionar z-index stack)

---

## Estimativa & Complexidade

**Complexity:** 🟢 Baixa  
**Story Points:** 2  
**Estimate:** 1 dia  
**Dependências:** Nenhuma

---

## Arquivos Afetados

```
app/javascript/dashboard/components/crm/FilterBar.vue
app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue
app/javascript/dashboard/styles/filter.scss
(Possível) app/javascript/dashboard/styles/z-index.scss
```

---

## Notas Técnicas

- Usar `position: fixed` ou `position: absolute` com parent `position: relative`
- Considerar usar Popper.js (se já usado em app) para posicionamento inteligente
- Z-index stack: card containers < filter dropdown < modal
- Exemplo:
  ```css
  .filter-dropdown {
    position: absolute;
    z-index: 50; /* above cards (10-40), below modals (999) */
    min-width: 200px;
  }
  ```

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Z-index validation (no conflicts)
- [ ] Position property check (fixed vs absolute)
- [ ] Viewport edge detection (no clipping)
- [ ] Mobile breakpoint testing

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. Open `FilterBar.vue` and check dropdown structure
2. Add/increase z-index to dropdown container: `z-index: 50`
3. Ensure parent element has `position: relative` if using absolute positioning
4. Test dropdown positioning at edges (left, right, bottom)
5. Verify dropdown doesn't disappear when scrolling

**Testing:**
- Open FilterBar
- Click dropdown → appears above all cards
- Move mouse to edges of viewport → dropdown repositions or extends properly
- Scroll down → filter dropdown stays visible
- Click outside → closes dropdown
- Press Escape → closes dropdown

**PR Title:** `fix(filter): fix z-index to make dropdown visible`

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Blocks:** Story 2.2 (Z-INDEX must be fixed first)  
**Story Template Version:** 1.0
