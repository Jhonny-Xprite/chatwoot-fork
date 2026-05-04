# Story 3.1: Implementar Drag & Drop tipo Trello/ClickUp

**ID:** EPIC-001-S3.1  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 3 - Interação  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como agente,
Quero arrastar cards entre estágios como no Trello/ClickUp,
Para que eu mude status de forma intuitiva, visual e sem clicks múltiplos.
```

---

## Descrição

Melhorar drag & drop do Kanban. Hoje card não segue o mouse quando arrastado. Esperado: card levanta visualmente, segue cursor, feedback claro, soltar realoca para novo estágio com animação suave.

---

## Acceptance Criteria

- [ ] Card levanta quando clicado e mantido (mousedown + 200ms delay)
- [ ] Card segue o cursor do mouse enquanto arrasta (até mouseup)
- [ ] Card tem sombra/elevação visual indicando que está sendo arrastado
- [ ] Quando mouse cruza coluna destino, coluna fica destacada (border/sombra)
- [ ] Linha visual mostra posição exata onde card será inserido
- [ ] Ao soltar (mouseup), card se realoca para novo estágio
- [ ] Animação suave (200-300ms) ao realocar card
- [ ] Funciona com muitos cards (100+) sem lag notável
- [ ] Funciona em mobile/tablet (touch events: touchstart, touchmove, touchend)
- [ ] Estado persiste no backend (POST /conversations/:id/move_to_stage)
- [ ] Drag abortado se mouse sai da janela (volta para posição original)
- [ ] Undo não necessário (operação é atômica)
- [ ] Acessibilidade: navegação via teclado suportada (ex: Ctrl+Arrow keys - opcional)

---

## Estimativa & Complexidade

**Complexity:** 🔴 Alta  
**Story Points:** 13  
**Estimate:** 4-5 dias  
**Dependências:** Nenhuma (mas comece APÓS Wave 1 + 2)

---

## Arquivos Afetados

```
app/javascript/dashboard/components/crm/PipelineBoard.vue
app/javascript/dashboard/components/crm/PipelineColumn.vue
app/javascript/dashboard/components/crm/ContactPipelineCard.vue
app/javascript/dashboard/api/crm/pipeline.js
app/controllers/api/v1/accounts/crm/conversations_controller.rb
app/javascript/dashboard/styles/kanban-drag-drop.scss
```

---

## API Endpoint to Add

**Backend:**
```
POST /api/v1/accounts/:account_id/crm/conversations/:id/move_to_stage
Body: { pipeline_stage_id: <stage_id> }
Response: { success: true, conversation: {...} }
```

**Database:**
- Ensure index on `conversations.pipeline_stage_id` for performance

---

## Implementation Strategy

**Option A: Use `vuedraggable` (if already installed)**
```javascript
// In PipelineColumn.vue
<draggable 
  v-model="stageConversations"
  :options="dragOptions"
  @change="onDragEnd"
>
  <ContactPipelineCard v-for="card in stageConversations" />
</draggable>
```

**Option B: Native Drag Events (HTML5 API)**
```javascript
// On card mousedown:
// 1. Create drag overlay (visual feedback)
// 2. Listen to mousemove (follow cursor)
// 3. Check drop target on mouseup
// 4. Validate and POST to backend
```

**Recommendation:** Use `vuedraggable` if available (cleaner), otherwise native events.

---

## Notas Técnicas

- **Performance:** With 100+ cards, use virtual scrolling if needed
- **Debounce:** dragover events to avoid excessive reflows
- **Feedback:** Show visual indicators (shadow, highlight, drop zone)
- **Touch Support:** Implement touchstart/touchmove/touchend handlers
- **Rate Limiting:** Max 1 move per conversation every 1 second
- **Error Handling:** If move fails, revert card to original position with error toast
- **Browser Testing:** Firefox has different drag behavior than Chrome

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Drag event listener cleanup (removeEventListener)
- [ ] Performance: no memory leaks on large lists
- [ ] Touch event support (iOS/Android)
- [ ] Accessibility: keyboard alternative (optional)
- [ ] Error handling: network failure cases

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. **Backend:**
   - Add endpoint: `POST /conversations/:id/move_to_stage`
   - Validate conversation ownership
   - Update `pipeline_stage_id`
   - Return updated conversation

2. **Frontend:**
   - Add drag event listeners to `ContactPipelineCard.vue`
   - Or update `PipelineColumn.vue` to use `vuedraggable`
   - Add visual feedback: shadow, highlight on drag
   - Add drop zone highlighting
   - On drop: call API endpoint to persist

3. **Styling:**
   - Card being dragged: shadow + scale(1.05)
   - Column drop zone: border highlight
   - Drop placeholder: gray line showing insert position

**Testing:**
- Click + hold card → see visual feedback (shadow)
- Drag card across columns → columns highlight
- Drag card to different stage → release → card moves + persists
- Reload page → card in new position
- Test with many cards (100+) → no lag
- Test on mobile (long press + drag) → works
- Network error during drag → revert card with error message

**PR Title:** `feat(kanban): implement smooth drag-and-drop between stages`

---

## Performance Considerations

- Virtual scrolling: Only render visible cards (if 100+)
- Debounce dragover: max 100ms between updates
- useCallback for drag handlers
- useMemo for computed drop zones

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Blocks:** None  
**Blocked By:** None (but do AFTER Wave 1 + 2)  
**Story Template Version:** 1.0
