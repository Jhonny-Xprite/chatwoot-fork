# Story 1.2: Fix Scheme de Cores no Conversation Detail

**ID:** EPIC-001-S1.2  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 1 - UX Quick Wins  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como agente,
Quero que o conversation detail tenha cores legíveis,
Para que eu consiga entender a conversa rapidamente.
```

---

## Descrição

Conversation detail view tem problemas de contraste - texto difícil de ler, cores confundem mensagens de entrada/saída, timestamps invisíveis. Precisa de scheme visual claro.

---

## Acceptance Criteria

- [ ] Mensagens do cliente têm fundo/cor diferente de mensagens do agente
- [ ] Todo texto tem contrast ratio >= 4.5:1
- [ ] Sender info (nome, avatar) é claramente identificado
- [ ] Timestamps são visíveis e legíveis
- [ ] Status de mensagem (enviada/lida/erro) é claro e visível
- [ ] Funciona em modo light e dark theme
- [ ] Layout responsivo em mobile também está legível
- [ ] Teste com daltonismo (usar ferramentas como Coblis)

---

## Estimativa & Complexidade

**Complexity:** 🟢 Baixa  
**Story Points:** 2  
**Estimate:** 1-2 dias  
**Dependências:** Nenhuma

---

## Arquivos Afetados

```
app/javascript/dashboard/components/conversation/ConversationDetails.vue
app/javascript/dashboard/styles/conversation-detail.scss
```

---

## Notas Técnicas

- Usar CSS variables para tema light/dark
- Considerar usar cores distintas por sender type (cliente vs agente)
- Adicionar badge/indicador de status (pending, sent, read, error)
- Exemplo de esquema:
  - Mensagem do Cliente: fundo claro/cinza, texto escuro
  - Mensagem do Agente: fundo brandcolor-light, texto escuro
  - Status: ícone + tooltip

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] WCAG AA contrast validation
- [ ] Responsive design check (mobile 320px+)
- [ ] Dark mode testing
- [ ] CSS color variable usage

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. Open `ConversationDetails.vue` and `conversation-detail.scss`
2. Add/update color scheme:
   - Client messages: different background (gray/light)
   - Agent messages: brand color background
   - Status badges: visible icons/text
3. Ensure timestamps visible on every message
4. Test in light + dark theme
5. Mobile responsive test

**Testing:**
- Open any conversation with multiple messages
- Verify client/agent messages are visually distinct
- Check timestamps, status indicators visible
- Test dark mode
- Test mobile (320px width)

**PR Title:** `fix(conversation): improve readability with better color scheme`

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Story Template Version:** 1.0
