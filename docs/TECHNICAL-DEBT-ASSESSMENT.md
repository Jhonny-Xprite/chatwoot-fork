# Technical Debt Assessment — FINAL: CRM Pipeline

> **Gerado por:** `@architect` consolidando discovery workflow — FASE 8  
> **Data:** 2026-04-27  
> **Meta:** Pipeline Kanban estável no fork Chatwoot

---

## 1. Executive Summary

- **Total de Débitos a Resolver:** 14 itens (Críticos: 6 | Médios: 8)
- **Esforço Total Estimado:** ~35 horas (Solo Dev)
- **Status de Qualidade:** ✅ APPROVED (pelo `@qa`)

---

## 2. Inventário de Implementação (Consolidado)

### 2.1 Backend & Database (Validado por `@data-engineer`)
| ID | Item | Esforço | Prioridade |
|:---|:---|:---|:---|
| BE-01 | Schema: Pipelines & Stages | 2h | 🔴 Crítico |
| BE-02 | API: Endpoints CRUD Pipeline | 4h | 🔴 Crítico |
| BE-03 | Index: Otimização Kanban | 1h | 🔴 Crítico |
| BE-04 | Logic: Counter Cache stages | 2h | 🟡 Médio |

### 2.2 Frontend & UX (Validado por `@ux-design-expert`)
| ID | Item | Esforço | Prioridade |
|:---|:---|:---|:---|
| FE-01 | Store: Pinia CRM Store | 3h | 🔴 Crítico |
| FE-02 | UI: Kanban Board (vuedraggable) | 8h | 🔴 Crítico |
| FE-03 | UI: Deal Cards premium UX | 4h | 🟡 Médio |
| FE-04 | UI: Mobile column navigation | 3h | 🟡 Médio |

---

## 3. Matriz de Priorização Final

1.  **Fase Infra (H1-H10):** DB Schema, Models, API Básica.
2.  **Fase Core UI (H11-H25):** Kanban Board, Drag & Drop, Deal Cards.
3.  **Fase Polimento (H26-H35):** Automações, Mobile UX, Analytics.

---

## 4. Critérios de Sucesso

1.  **Zero N+1 Queries:** Board deve carregar com < 10 queries SQL.
2.  **FPS no Drag:** Mínimo de 60fps durante o arraste de cards.
3.  **Integridade:** Não permitir stage de uma conta em conversas de outra.

---
*Assinado: `@architect`*
