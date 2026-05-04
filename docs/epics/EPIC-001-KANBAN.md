# EPIC-001: Kanban & Chat Platform Refinements

**Status:** 📋 Planning  
**Priority:** 🔴 Critical  
**Created:** 2026-05-04  
**Owner:** Morgan (PM)  
**Target Release:** Sprint TBD

---

## Executive Summary

Melhorar experiência do usuário no Kanban e Chat resolvendo 7 problemas críticos de UX, funcionalidade e data integrity. Sequência por facilidade de implementação (quick wins → complexos).

**Impact:** 
- Usabilidade aumentada em ~60%
- Redução de erros de entrada de dados
- Interface mais legível e intuitiva

---

## 🎯 Objetivos

- ✅ Tornar interface legível e com contraste adequado
- ✅ Ativar funcionalidade de filtros (Z-INDEX + filtro por status)
- ✅ Implementar drag & drop intuitivo (Trello-like)
- ✅ Resolver duplicação de cards por canal
- ✅ Adicionar marcação de não-lido e destaque

---

## 📊 Scope & Sequência

### Wave 1: UX Quick Wins (5-7 dias)
- Story 1.1: Fix cores no Chat (links visíveis)
- Story 1.2: Fix scheme de cores no Conversation Detail
- Story 1.3: Add "Marcar como não lido" + Destaque

### Wave 2: Funcionalidade (3-4 dias)
- Story 2.1: Fix Z-INDEX do Filtro
- Story 2.2: Add Filtro por Status no Kanban

### Wave 3: Interação (4-5 dias)
- Story 3.1: Implementar Drag & Drop tipo Trello/ClickUp

### Wave 4: Data Integrity (5-6 dias)
- Story 4.1: Resolver Duplicação de Cards

**Total Estimado:** 17-22 dias com 1-2 devs em paralelo

---

## 📋 Stories Detalhadas

---

## **WAVE 1: UX Quick Wins**

### Story 1.1: Fix Cores no Chat (Links Visíveis)

**ID:** EPIC-001-S1.1  
**Complexity:** 🟢 Baixa  
**Estimate:** 1-2 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como usuário,
Quero que links no chat sejam legíveis e diferenciados,
Para que eu possa clicar e acessar URLs facilmente.
```

#### Descrição
Links no chat estão azuis sobre fundo azul, ficando invisíveis. Precisa de contraste adequado (WCAG AA) e diferenciação visual clara.

#### Acceptance Criteria
- [ ] Links no chat têm cor diferente de azul (ex: verde, roxo, vermelho)
- [ ] Links têm underline ou outro indicador visual
- [ ] Link é clicável e funciona corretamente
- [ ] Funciona em modo light e dark theme
- [ ] Contrast ratio >= 4.5:1 (WCAG AA compliance)
- [ ] Hover state deixa evidente que é clicável
- [ ] Testar em navegadores: Chrome, Firefox, Safari

#### Arquivos Afetados
- `app/javascript/dashboard/components/conversation/Message.vue`
- `app/javascript/dashboard/styles/conversation.scss`

#### Dependências
- Nenhuma

#### Notas Técnicas
- Considerar usar cores já definidas no design system
- Manter consistência com rest da UI
- Testar links com diferentes protocolos (http, https, ftp, mailto)

---

### Story 1.2: Fix Scheme de Cores no Conversation Detail

**ID:** EPIC-001-S1.2  
**Complexity:** 🟢 Baixa  
**Estimate:** 1-2 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como agente,
Quero que o conversation detail tenha cores legíveis,
Para que eu consiga entender a conversa rapidamente.
```

#### Descrição
Conversation detail view tem problemas de contraste - texto difícil de ler, cores confundem mensagens de entrada/saída, timestamps invisíveis.

#### Acceptance Criteria
- [ ] Mensagens do cliente têm fundo/cor diferente de mensagens do agente
- [ ] Todo texto tem contrast ratio >= 4.5:1
- [ ] Sender info (nome, avatar) é claramente identificado
- [ ] Timestamps são visíveis e legíveis
- [ ] Status de mensagem (enviada/lida/erro) é claro
- [ ] Funciona em modo light e dark theme
- [ ] Layout responsivo em mobile também está legível
- [ ] Teste com daltonismo (usar ferramentas como Coblis)

#### Arquivos Afetados
- `app/javascript/dashboard/components/conversation/ConversationDetails.vue`
- `app/javascript/dashboard/styles/conversation-detail.scss`

#### Dependências
- Nenhuma

#### Notas Técnicas
- Usar CSS variables para tema light/dark
- Considerar usar cores distintas por sender type (cliente vs agente)
- Adicionar badge/indicador de status (pending, sent, read)

---

### Story 1.3: Add "Marcar como não lido" + Destaque

**ID:** EPIC-001-S1.3  
**Complexity:** 🟡 Média  
**Estimate:** 2-3 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como agente,
Quero marcar conversas como "não lido" e destacá-las,
Para que eu possa priorizar conversas importantes.
```

#### Descrição
Adicionar funcionalidade de marcar conversa/card como não lido (inbox unread) e destacar visualmente com pin para retomar depois. Similar a Slack/Gmail.

#### Acceptance Criteria
- [ ] Botão "Marcar como não lido" (icon de bell/eye) aparece no conversation header
- [ ] Botão "Destacar" ou pin (icon star/pin) aparece no card e conversation header
- [ ] Cards não lidos têm indicador visual (badge 🔴, cor, ícone)
- [ ] Cards destacados têm ícone de pin no topo (visível)
- [ ] Estado persiste no reload da página
- [ ] Contador de "não lidos" aparece no sidebar/inbox
- [ ] Filtro "Mostrar não lidos" funciona (integrado com Story 2.2)
- [ ] Tooltip explica a ação ("Marcar como não lido", "Destacar para depois")
- [ ] Atalho de teclado opcional (ex: Cmd+Shift+U para unread)

#### Arquivos Afetados
- `app/javascript/dashboard/components/conversation/ConversationHeader.vue`
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue`
- `app/models/conversation.rb` (add columns: `is_unread`, `is_pinned`)
- `db/migrate/[timestamp]_add_unread_pinned_to_conversations.rb`
- `app/javascript/dashboard/store/modules/conversations/actions.js`

#### Dependências
- Story 2.2 (Filtro por Status) - para o filtro "Não lidos" funcionar

#### Notas Técnicas
- Usar checkbox/toggle com visual feedback imediato
- Adicionar scope no modelo: `scope :unread, -> { where(is_unread: true) }`
- Considerar `updated_at` quando marca como não lido (para sorting)
- API endpoint: `PATCH /conversations/:id/mark_unread`, `PATCH /conversations/:id/pin`

---

## **WAVE 2: Funcionalidade**

### Story 2.1: Fix Z-INDEX do Filtro

**ID:** EPIC-001-S2.1  
**Complexity:** 🟢 Baixa  
**Estimate:** 1 dia  
**Status:** 📝 Ready

#### User Story
```gherkin
Como usuário,
Quero que o filtro seja acessível e não fique escondido atrás de outros elementos,
Para que eu consiga filtrar conversas/cards eficientemente.
```

#### Descrição
Filtro tem problema de Z-INDEX - fica escondido atrás de cards, headers, outros elementos. Dropdown é inacessível e não clicável.

#### Acceptance Criteria
- [ ] Dropdown do filtro aparece acima de todos os cards (z-index adequado)
- [ ] Dropdown não é cortado nas bordas da viewport (repositioning automático)
- [ ] Clique fora do dropdown fecha ele (comportamento padrão)
- [ ] Z-index >= 50 (ou apropriado para stack context da app)
- [ ] Funciona em todas as resoluções (mobile 320px, tablet, desktop 1920px+)
- [ ] Funciona com scroll ativo (não some ao scrollar)
- [ ] Acessibilidade: navegação via Tab e Escape funciona
- [ ] Teste com DevTools (inspecionar z-index stack)

#### Arquivos Afetados
- `app/javascript/dashboard/components/crm/FilterBar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue`
- `app/javascript/dashboard/styles/filter.scss`
- Possível: `app/javascript/dashboard/styles/z-index.scss` (centralizar z-indexes)

#### Dependências
- Nenhuma

#### Notas Técnicas
- Usar `position: fixed` ou `position: absolute` com parent `position: relative`
- Considerar usar Popper.js (já usado em app?) para posicionamento inteligente
- Testar com múltiplos elementos com z-index (modals, tooltips, etc)

---

### Story 2.2: Add Filtro por Status no Kanban

**ID:** EPIC-001-S2.2  
**Complexity:** 🟡 Média  
**Estimate:** 2-3 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como agente,
Quero filtrar leads na pipeline por status específico (estágio),
Para que eu veja apenas o que me interessa no momento.
```

#### Descrição
Adicionar dropdown de filtro por status/stage no Kanban FilterBar. Usuário pode filtrar para ver apenas cards de um estágio específico ou "Todos os estágios".

#### Acceptance Criteria
- [ ] Dropdown "Filtrar por Status" ou "Estágio" aparece no FilterBar
- [ ] Lista todos os stages da pipeline ativa
- [ ] "Todos os estágios" é a opção padrão (sem filtro)
- [ ] Seleção filtra cards em tempo real (sem reload)
- [ ] Filtro persiste na URL (queryParam `?status=stage-id`)
- [ ] Pode combinar com outros filtros (assignee, labels, lead score, não lidos)
- [ ] Mostra contagem de cards por status (ex: "Novo (15)")
- [ ] Z-INDEX funciona corretamente (Story 2.1)
- [ ] Mobile: dropdown colapsível para economizar espaço
- [ ] Tooltip: "Filtrar por estágio atual" / "Mostrar todos"

#### Arquivos Afetados
- `app/javascript/dashboard/components/crm/FilterBar.vue`
- `app/javascript/dashboard/routes/dashboard/crm/Pipelines.vue`
- `app/javascript/dashboard/store/crm/pipeline.js` (add filter: `stageFilter`)
- `app/javascript/dashboard/store/mutation-types.js`

#### Dependências
- Story 2.1 (Z-INDEX fix) - para dropdown ser acessível
- Story 1.3 (não lido/pinned) - para integração com filtro "Não lidos"

#### Notas Técnicas
- Mutation: `SET_STAGE_FILTER`
- Getter: `getAppliedFilters` deve incluir `stageFilter`
- Watch: `stageFilter` change deve triggar `refreshAllStages()`
- API request deve incluir `?stage_id=X` quando filtrado

---

## **WAVE 3: Interação**

### Story 3.1: Implementar Drag & Drop tipo Trello/ClickUp

**ID:** EPIC-001-S3.1  
**Complexity:** 🔴 Alta  
**Estimate:** 4-5 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como agente,
Quero arrastar cards entre estágios como no Trello/ClickUp,
Para que eu mude status de forma intuitiva, visual e sem clicks múltiplos.
```

#### Descrição
Melhorar drag & drop do Kanban. Hoje card não segue o mouse quando arrastado. Esperado: card levanta visualmente, segue cursor, feedback claro, soltar realoca para novo estágio com animação.

#### Acceptance Criteria
- [ ] Card levanta quando clicado e mantido (mousedown + 200ms)
- [ ] Card segue o cursor do mouse enquanto arrasta (até mouseup)
- [ ] Card tem sombra/elevação visual indicando que está sendo arrastado
- [ ] Quando mouse cruza coluna destino, coluna fica destacada (border/sombra)
- [ ] Linha visual mostra posição onde card será inserido
- [ ] Ao soltar (mouseup), card se realoca para novo estágio
- [ ] Animação suave (200-300ms) ao realocar card
- [ ] Funciona com muitos cards (100+) sem lag notável
- [ ] Funciona em mobile/tablet (touch events: touchstart, touchmove, touchend)
- [ ] Estado persiste no backend (POST /conversations/:id/move_to_stage)
- [ ] Drag abortado se mouse sai da janela (volta para posição original)
- [ ] Undo não necessário (operação é atômica)
- [ ] Acessibilidade: teclado pode reordenar (opcional, ex: Ctrl+Arrow)

#### Arquivos Afetados
- `app/javascript/dashboard/components/crm/PipelineBoard.vue`
- `app/javascript/dashboard/components/crm/PipelineColumn.vue`
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue`
- `app/javascript/dashboard/api/crm/pipeline.js` (add `moveConversation` method)
- `app/controllers/api/v1/accounts/crm/conversations_controller.rb` (add `move_to_stage` action)
- `app/javascript/dashboard/styles/kanban-drag-drop.scss`

#### Dependências
- Nenhuma (mas Story 3.1 deve ser iniciado DEPOIS de Wave 1 + 2)

#### Notas Técnicas
- Usar `vuedraggable` (já instalado) OU implementar com drag events nativos
- No backend: validar que conversa existe, stage existe, user tem permissão
- Atualizar `conversation.pipeline_stage_id` no DB
- Adicionar index: `conversations.pipeline_stage_id` para query performance
- Considerar rate-limiting: máx 1 move por conversa a cada 1s
- Testar com Firefox (tem comportamento diferente de Chrome)

#### Performance Notes
- 100+ cards: usar virtual scrolling se necessário
- Debounce de dragover para evitar reflows excessivos
- useCallback/useMemo para funções dentro de loop

---

## **WAVE 4: Data Integrity**

### Story 4.1: Resolver Duplicação de Cards

**ID:** EPIC-001-S4.1  
**Complexity:** 🔴 Alta  
**Estimate:** 5-6 dias  
**Status:** 📝 Ready

#### User Story
```gherkin
Como usuário,
Quero que um lead apareça uma única vez no Kanban,
Para que eu não fique confuso vendo múltiplos cards do mesmo contato.
```

#### Descrição
Quando mesmo lead/contato entra por canais diferentes (WhatsApp, Email, SMS), sistema cria 2+ cards/conversations. Precisa de deduplicação inteligente: detectar duplicatas, consolidar historicamente, prevenir futuro.

#### Acceptance Criteria
- [ ] Sistema detecta quando um contato é o mesmo em canais diferentes (por: email, phone, ID externo)
- [ ] Cria apenas 1 card/conversation por contato, não por canal
- [ ] Todas as conversas (chats) do contato aparecem em 1 card (tabs ou dropdown "Histórico")
- [ ] Histórico consolidado mostra todas as mensagens em ordem cronológica (todos os canais)
- [ ] Ao responder, usuário escolhe qual canal usar para resposta
- [ ] Se contatos foram duplicados no passado, script de migração consolida
- [ ] No futuro, duplicação de contato é impossível (validação)
- [ ] UI mostra "Este contato tem X conversas ativas"
- [ ] Contatos consolidados: sem perda de dados, apenas merge

#### Arquivos Afetados
- `app/models/contact.rb` (add deduplication logic, scopes)
- `app/services/contact_deduplication_service.rb` (novo - core logic)
- `app/jobs/dedup_contacts_job.rb` (novo - background job para cleanup)
- `db/migrate/[timestamp]_add_merged_contact_id_to_contacts.rb`
- `db/migrate/[timestamp]_add_unique_constraint_contact_by_channel.rb`
- `app/javascript/dashboard/store/modules/contacts/actions.js`
- `app/javascript/dashboard/components/crm/ContactPipelineCard.vue` (mostrar múltiplas conversas)

#### Dependências
- Nenhuma (mas deve ser feito ÚLTIMO para estabilidade)

#### Notas Técnicas
- Criar service: `ContactDeduplicationService.merge(primary_contact, duplicate_contact)`
  - Move todas as conversas do duplicate para primary
  - Atualiza contact_id em messages
  - Marca duplicate como merged_to: primary.id
  - Não deleta duplicate (auditoria)

- Unique constraint: `unique_index_on_contacts(account_id, identifier_channel)` onde `identifier_channel` = `"#{phone}_whatsapp"` ou `"#{email}_email"`

- Background job para cleanup:
  - Roda 1x por semana
  - Encontra contacts com `is_unread = false` E `updated_at < 30 days ago`
  - Agrupa por: phone + email + name similarity
  - Se score > 0.95, chama `merge()`

- API: novo endpoint `POST /contacts/:id/merge_with/:duplicate_id`

#### Testing
- Unit: ContactDeduplicationService com vários cenários
- Integration: criar 2 contatos, mergeá-los, validar dados
- Regression: verificar que conversas não-relacionadas não são merged

---

## 📈 Success Metrics

| Métrica | Target | Como Medir |
|---------|--------|-----------|
| Usabilidade | +60% | Survey + session recording |
| Legibilidade | 100% WCAG AA | Automated + manual testing |
| Drag & drop smooth | 60 FPS | Lighthouse + browser profiler |
| Duplicação zero | 0% | Data audit monthly |
| Filtro acessível | 100% | User testing |

---

## 🗓️ Timeline

```
Week 1: Wave 1 (Stories 1.1, 1.2, 1.3)  [5-7 dias]
Week 2: Wave 2 (Stories 2.1, 2.2)       [3-4 dias]
Week 2-3: Wave 3 (Story 3.1)            [4-5 dias]
Week 3-4: Wave 4 (Story 4.1)            [5-6 dias]

Total: 3-4 semanas com 1-2 devs
```

---

## 🔗 Related Documents

- [Chatwoot CRM Architecture](../architecture/crm-architecture.md)
- [Component Library](../guides/components.md)
- [Testing Strategy](../testing/testing-strategy.md)

---

## 📝 Notes

- Todos os stories devem incluir testes (unit + integration)
- PR reviews com @architect antes de merge de Wave 3 + 4
- Deploy: 1 story por PR, não combinar waves
- Monitoring: erro rate, performance metrics após cada wave

---

## ✅ Approval & Sign-off

- [ ] PM Approved (Morgan)
- [ ] Tech Lead Approved (@architect)
- [ ] Product Owner Sign-off (@po)
- [ ] Ready to Execute (click link abaixo)

---

**Last Updated:** 2026-05-04  
**Version:** 1.0  
**Document ID:** EPIC-001-KANBAN-v1.0
