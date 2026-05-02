# QA Review — CRM Pipeline Assessment

> **Gerado por:** `@qa` via `brownfield-discovery` workflow — FASE 7  
> **Data:** 2026-04-27  
> **Gate Status:** ✅ APPROVED

---

## 1. Riscos Identificados

| Risco | Área | Impacto | Mitigação Sugerida |
|:---|:---|:---|:---|
| Data Leakage | Backend | 🔴 Crítico | Scope de Pundit em `CrmPipeline` e `CrmPipelineStage`. |
| UX Lag | Frontend | 🟡 Médio | Debounce em updates de drag & drop. |
| DB Bloat | Database | 🟡 Médio | Limitar número de deals por stage na query inicial. |
| Regressão API | Backend | 🔴 Crítico | Garantir que `conversations_controller` ignore `pipeline_stage_id` se nulo. |

---

## 2. Dependências Validadas
A ordem de implementação proposta (Backend -> Frontend) está correta. 
⚠️ **Atenção:** O frontend não deve ser iniciado sem que os endpoints de `PATCH conversations` estejam validados.

---

## 3. Plano de Testes Requerido

### 3.1 Testes de Fumaça (Backend)
- Criar Pipeline -> Criar Stage -> Vincular Conversa.
- Tentar mover conversa para stage de outra conta (Deve falhar).

### 3.2 Testes de UI (Frontend)
- Drag & Drop de card entre colunas.
- Verificar se o count no header da coluna atualiza em tempo real (via ActionCable/Websockets se possível, ou refetch).

---

## 4. Parecer Final

**GATE STATUS: APPROVED**  
O assessment está completo e os riscos estão mapeados. O projeto pode seguir para a consolidação final e início do desenvolvimento.

---
*Assinado: `@qa`*
