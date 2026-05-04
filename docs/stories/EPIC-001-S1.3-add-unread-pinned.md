# Story 1.3: Add "Marcar como não lido" + Destaque

**ID:** EPIC-001-S1.3  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 1 - UX Quick Wins  
**Status:** 📝 Ready for Dev  
**Priority:** 🟡 High  

---

## User Story

```gherkin
Como agente,
Quero marcar conversas como "não lido" e destacá-las,
Para que eu possa priorizar conversas importantes.
```

---

## Descrição

Adicionar funcionalidade de marcar conversa/card como não lido (similar a Slack) e destacar visualmente com pin para retomar depois. Similar a Slack/Gmail unread + star features.

---

## Acceptance Criteria

- [ ] Botão "Marcar como não lido" (icon de bell/eye) aparece no conversation header
- [ ] Botão "Destacar" ou pin (icon star/pin) aparece no card e conversation header
- [ ] Cards não lidos têm indicador visual (badge 🔴, cor, ícone)
- [ ] Cards destacados têm ícone de pin no topo (visível)
- [ ] Estado persiste no reload da página
- [ ] Contador de "não lidos" aparece no sidebar/inbox
- [ ] Filtro "Mostrar não lidos" funciona (integrado com Story 2.2)
- [ ] Tooltip explica a ação ("Marcar como não lido", "Destacar para depois")
- [ ] Atalho de teclado opcional (ex: Cmd+Shift+U para unread)

---

## Estimativa & Complexidade

**Complexity:** 🟡 Média  
**Story Points:** 5  
**Estimate:** 2-3 dias  
**Dependências:** Story 2.2 (Filtro por Status) - para o filtro "Não lidos" funcionar

---

## Arquivos Afetados

```
app/javascript/dashboard/components/conversation/ConversationHeader.vue
app/javascript/dashboard/components/crm/ContactPipelineCard.vue
app/models/conversation.rb
db/migrate/[timestamp]_add_unread_pinned_to_conversations.rb
app/javascript/dashboard/store/modules/conversations/actions.js
```

---

## Database Migration

**New columns in `conversations` table:**
```sql
ALTER TABLE conversations ADD COLUMN is_unread BOOLEAN DEFAULT false;
ALTER TABLE conversations ADD COLUMN is_pinned BOOLEAN DEFAULT false;
ALTER TABLE conversations ADD INDEX idx_is_unread (is_unread);
```

---

## Notas Técnicas

- Usar checkbox/toggle com visual feedback imediato
- Adicionar scope no modelo: `scope :unread, -> { where(is_unread: true) }`
- Considerar `updated_at` quando marca como não lido (para sorting)
- API endpoints:
  - `PATCH /conversations/:id/mark_unread` → set `is_unread = true`
  - `PATCH /conversations/:id/mark_read` → set `is_unread = false`
  - `PATCH /conversations/:id/pin` → set `is_pinned = true`
  - `PATCH /conversations/:id/unpin` → set `is_pinned = false`

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Migration syntax validation
- [ ] API endpoint security (auth check)
- [ ] State consistency (unread + pinned don't conflict)
- [ ] UI: toggle button accessibility

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. Create migration: add `is_unread` and `is_pinned` columns to conversations
2. Update `Conversation` model:
   - Add scopes: `:unread`, `:pinned`
   - Add validation (optional)
3. Add API endpoints in conversations controller
4. Update `ConversationHeader.vue`:
   - Add 2 buttons: "Mark unread" + "Pin"
   - Show visual indicators when active
5. Update `ContactPipelineCard.vue`:
   - Show unread badge (red dot)
   - Show pin icon if pinned
6. Update store actions to call new API endpoints
7. Add to Filters (Story 2.2): option to show only unread

**Testing:**
- Click "Mark unread" → verify visual change + persist reload
- Click "Pin" → verify pin icon shows + persist reload
- Open Filter → see "Não lidos" option available
- Counter in sidebar shows correct unread count

**PR Title:** `feat(conversation): add unread and pin features`

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Blocks:** None  
**Blocked By:** Story 2.2 (for filter integration)  
**Story Template Version:** 1.0
