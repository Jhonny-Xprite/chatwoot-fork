# Database Specialist Review — CRM Pipeline

> **Gerado por:** `@data-engineer` via `brownfield-discovery` workflow — FASE 5  
> **Data:** 2026-04-27  
> **Referência:** [CRM-PIPELINE-PLAN.md](../CRM-PIPELINE-PLAN.md)

---

## 1. Validação de Débitos Identificados

| ID | Débito | Status | Severidade | Horas | Notas |
|:---|:---|:---|:---|:---|:---|
| TD-DB-01 | Índice Composto Kanban | ✅ Validado | 🔴 Crítico | 1h | Fundamental para queries de board. |
| TD-DB-02 | FK Constraints | ✅ Validado | 🟡 Médio | 1h | Usar `nullify` para preservar histórico. |
| TD-DB-03 | Lead Status Sync | ✅ Validado | 🟡 Médio | 2h | Sync entre `contact_type` e stages. |
| TD-DB-04 | Counter Cache | ➕ Adicionado | 🟡 Médio | 2h | Evitar overhead de count no board. |

---

## 2. Recomendações Técnicas

### 2.1 Estratégia de Indexação
O índice sugerido na FASE 2 deve ser refinado para:
```sql
CREATE INDEX index_conversations_on_crm_pipeline_lookup 
ON conversations (account_id, pipeline_stage_id, last_activity_at DESC);
```
Isso otimiza tanto o filtro de colunas quanto a ordenação cronológica dos cards.

### 2.2 Integridade Referencial
Não podemos permitir que um `CrmPipelineStage` seja deletado se houver conversas ativas vinculadas a ele sem uma estratégia de migração.
- **Recomendação:** No controller de destroy, exigir um `target_stage_id` para mover as conversas antes da deleção.

### 2.3 Escalabilidade
Para contas "Enterprise-level" no fork, o uso de `conversations_count` no DB pode sofrer com race conditions em updates massivos.
- **Recomendação:** Implementar o counter cache nativo do Rails (`belongs_to :pipeline_stage, counter_cache: true`).

---

## 3. Estimativa Total (Fase DB)

- **Total de Horas Estimadas:** 6h  
- **Complexidade:** Baixa/Média  
- **Risco:** Baixo (sem quebra de retrocompatibilidade).

---

## 4. Parecer Técnico

**STATUS: APPROVED**  
O schema proposto no plano de implementação é robusto e segue as convenções do Chatwoot. Recomendo prosseguir com as migrations conforme definido.

---
*Assinado: `@data-engineer`*
