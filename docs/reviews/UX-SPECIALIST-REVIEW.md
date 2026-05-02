# UX Specialist Review — CRM Pipeline

> **Gerado por:** `@ux-design-expert` via `brownfield-discovery` workflow — FASE 6  
> **Data:** 2026-04-27  
> **Referência:** [FRONTEND-SPEC.md](../frontend/FRONTEND-SPEC.md)

---

## 1. Validação de Débitos e Features UI

| ID | Feature | Status | Severidade | Horas | Impacto UX |
|:---|:---|:---|:---|:---|:---|
| TD-FE-02 | Kanban Board View | ✅ Validado | 🔴 Crítico | 8h | Core do CRM. |
| TD-FE-03 | Deal Cards | ✅ Validado | 🔴 Crítico | 4h | Visibilidade imediata. |
| UX-FE-01 | Drag & Drop Feedback | ➕ Adicionado | 🟡 Médio | 2h | Feedback tátil essencial. |
| UX-FE-02 | Mobile Column View | ➕ Adicionado | 🟡 Médio | 3h | Navegação em telas pequenas. |

---

## 2. Recomendações de Design (UI/UX)

### 2.1 Micro-interações
Para o Kanban parecer premium:
- **Drop Zone:** Realçar a coluna de destino com um border tracejado e background sutil quando um card estiver sobre ela.
- **Drag Shadow:** O card sendo arrastado deve ter um shadow maior (`shadow-2xl`) e uma leve rotação (`rotate-2`) para parecer que foi "levantado".

### 2.2 Densidade de Informação (DealCard)
O card deve exibir:
1. **Nome do Contato** (Bold)
2. **Última Mensagem** (Truncated - 1 linha)
3. **Assignee Avatar** (Canto inferior direito)
4. **Labels** (Pequenos badges)
5. **Valor do Deal** (Se presente, destaque em verde)

### 2.3 Responsividade
No Mobile (< 768px), não devemos tentar mostrar todas as colunas. 
- **Sugestão:** Usar um horizontal scroll snapping ou uma View de coluna única com um seletor de stage no topo.

---

## 3. Estimativa Total (Fase Frontend)

- **Total de Horas Estimadas:** 17h  
- **Complexidade:** Média (foco em Drag & Drop e State Management).

---

## 4. Parecer Técnico

**STATUS: APPROVED**  
A especificação frontend está alinhada com os padrões `components-next` do Chatwoot. O plano é exequível sem dependências externas adicionais.

---
*Assinado: `@ux-design-expert`*
