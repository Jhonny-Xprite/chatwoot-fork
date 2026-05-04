# Story 1.1: Fix Cores no Chat (Links Visíveis)

**ID:** EPIC-001-S1.1  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 1 - UX Quick Wins  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como usuário,
Quero que links no chat sejam legíveis e diferenciados,
Para que eu possa clicar e acessar URLs facilmente.
```

---

## Descrição

Links no chat estão azuis sobre fundo azul, ficando invisíveis. Precisa de contraste adequado (WCAG AA) e diferenciação visual clara para serem acessíveis.

---

## Acceptance Criteria

- [ ] Links no chat têm cor diferente de azul (ex: verde, roxo, vermelho)
- [ ] Links têm underline ou outro indicador visual
- [ ] Link é clicável e funciona corretamente
- [ ] Funciona em modo light e dark theme
- [ ] Contrast ratio >= 4.5:1 (WCAG AA compliance)
- [ ] Hover state deixa evidente que é clicável
- [ ] Testar em navegadores: Chrome, Firefox, Safari

---

## Estimativa & Complexidade

**Complexity:** 🟢 Baixa  
**Story Points:** 2  
**Estimate:** 1-2 dias  
**Dependências:** Nenhuma

---

## Arquivos Afetados

```
app/javascript/dashboard/components/conversation/Message.vue
app/javascript/dashboard/styles/conversation.scss
```

---

## Notas Técnicas

- Considerar usar cores já definidas no design system (design tokens)
- Manter consistência com resto da UI
- Testar links com diferentes protocolos: `http://`, `https://`, `ftp://`, `mailto:`
- Usar CSS variables para tema light/dark

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Contrast ratio validation (WCAG)
- [ ] CSS specificity check
- [ ] No hardcoded colors (use variables)
- [ ] Hover/Focus states defined

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**What to change:**
1. Find `.Message` component and link styling
2. Change link color from blue to contrasting color (e.g., `#10b981` green or `#a855f7` purple)
3. Add underline or other visual indicator
4. Ensure hover state is visible
5. Update both light and dark theme variables

**Testing:**
- Open conversation with links
- Verify links are visible and clickable
- Test in light + dark mode
- Check contrast with accessibility tools

**PR Title:** `fix(chat): improve link visibility in messages`

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Story Template Version:** 1.0
