# Story 4.1: Resolver Duplicação de Cards

**ID:** EPIC-001-S4.1  
**Epic:** [EPIC-001-KANBAN](../epics/EPIC-001-KANBAN.md)  
**Wave:** 4 - Data Integrity  
**Status:** 📝 Ready for Dev  
**Priority:** 🔴 Critical  

---

## User Story

```gherkin
Como usuário,
Quero que um lead apareça uma única vez no Kanban,
Para que eu não fique confuso vendo múltiplos cards do mesmo contato.
```

---

## Descrição

Quando mesmo lead/contato entra por canais diferentes (WhatsApp, Email, SMS), sistema cria 2+ cards/conversations. Precisa de deduplicação inteligente: detectar duplicatas, consolidar historicamente, prevenir futuro.

---

## Acceptance Criteria

- [ ] Sistema detecta quando um contato é o mesmo em canais diferentes (por: email, phone, ID externo)
- [ ] Cria apenas 1 card/conversation por contato, não por canal
- [ ] Todas as conversas (chats) do contato aparecem em 1 card (tabs ou dropdown "Histórico")
- [ ] Histórico consolidado mostra todas as mensagens em ordem cronológica (todos os canais)
- [ ] Ao responder, usuário escolhe qual canal usar para resposta
- [ ] Se contatos foram duplicados no passado, script de migração consolida
- [ ] No futuro, duplicação de contato é impossível (validação única)
- [ ] UI mostra "Este contato tem X conversas ativas"
- [ ] Contatos consolidados: sem perda de dados, apenas merge
- [ ] Auditoria: log de merges para referência futura

---

## Estimativa & Complexidade

**Complexity:** 🔴 Alta  
**Story Points:** 21  
**Estimate:** 5-6 dias  
**Dependências:** Nenhuma (mas fazer por ÚLTIMO para estabilidade)

---

## Arquivos Afetados

```
app/models/contact.rb
app/services/contact_deduplication_service.rb (novo)
app/jobs/dedup_contacts_job.rb (novo)
db/migrate/[timestamp]_add_merged_contact_id_to_contacts.rb
db/migrate/[timestamp]_add_unique_constraint_contact_by_channel.rb
app/javascript/dashboard/store/modules/contacts/actions.js
app/javascript/dashboard/components/crm/ContactPipelineCard.vue
app/controllers/api/v1/accounts/contacts_controller.rb (add merge endpoint)
```

---

## Database Schema

**New columns:**
```sql
ALTER TABLE contacts ADD COLUMN merged_to_id BIGINT REFERENCES contacts(id);
ALTER TABLE contacts ADD COLUMN is_merged BOOLEAN DEFAULT false;
ALTER TABLE contacts ADD COLUMN merge_reason VARCHAR(255);
ALTER TABLE contacts ADD COLUMN merged_at TIMESTAMP;
ALTER TABLE contacts ADD COLUMN merged_by_id BIGINT REFERENCES users(id);

-- Unique constraint: account + phone/email + channel
ALTER TABLE contacts 
  ADD CONSTRAINT unique_contact_per_channel 
  UNIQUE (account_id, phone_number, identifier);
  -- Where: is_merged = false (ignore merged contacts)
```

---

## Service: ContactDeduplicationService

**Core method:**
```ruby
# app/services/contact_deduplication_service.rb
class ContactDeduplicationService
  # Merge duplicate_contact into primary_contact
  def self.merge(primary_contact, duplicate_contact, reason = "system_merge")
    transaction do
      # 1. Move all conversations from duplicate to primary
      duplicate_contact.conversations.update_all(
        contact_id: primary_contact.id
      )
      
      # 2. Consolidate messages
      consolidate_messages(primary_contact, duplicate_contact)
      
      # 3. Mark duplicate as merged
      duplicate_contact.update!(
        merged_to_id: primary_contact.id,
        is_merged: true,
        merge_reason: reason,
        merged_at: Time.current
      )
      
      # 4. Audit log
      log_merge(primary_contact, duplicate_contact, reason)
    end
  end
  
  private
  
  def self.consolidate_messages(primary, duplicate)
    # Merge messages from duplicate conversations
    # Keep original timestamps for sorting
  end
  
  def self.log_merge(primary, duplicate, reason)
    # Log for audit trail
  end
end
```

---

## Job: Dedup Contacts Job

**Runs weekly to find and merge duplicates:**
```ruby
# app/jobs/dedup_contacts_job.rb
class DedupContactsJob < ApplicationJob
  queue_as :low
  
  def perform
    # Find potential duplicates by:
    # - Same phone + different email
    # - Same email + different phone
    # - Similarity score on name (70%+)
    
    Contact.where(is_merged: false).find_each do |contact|
      duplicates = find_duplicates(contact)
      duplicates.each do |dup|
        ContactDeduplicationService.merge(contact, dup, "auto_dedup")
      end
    end
  end
end
```

---

## API Changes

**New endpoint:**
```
POST /api/v1/accounts/:account_id/contacts/:id/merge_with/:duplicate_id
Body: { reason: "manual" }
Response: { success: true, primary_contact: {...} }
```

**Update contact creation:**
- Check for existing contact by phone + email
- If found, don't create new (return existing)

---

## Frontend Changes

**In `ContactPipelineCard.vue`:**
```javascript
// Show multiple conversations in single card
<div v-if="contact.conversations.length > 1" class="badge">
  {{ contact.conversations.length }} chats
</div>

// Dropdown/tabs showing all conversations
<select v-model="selectedConversation">
  <option v-for="conv in contact.conversations" :value="conv.id">
    {{ conv.channel }} - {{ formatDate(conv.created_at) }}
  </option>
</select>
```

---

## Notas Técnicas

- **Matching Algorithm:**
  - Exact match: phone + email
  - Similarity: Levenshtein distance on name (70%+ = match)
  - Manual merge: admin interface (optional for this story)

- **Data Integrity:**
  - Keep history: mark merged, don't delete
  - Audit trail: who merged, when, reason
  - Reversible: could add "unmerge" in future

- **Performance:**
  - Run dedup job weekly (off-peak)
  - Batch processing for large merges
  - Index on `merged_to_id` and `is_merged`

- **Edge Cases:**
  - Merging already-merged contacts → follow chain
  - Circular references → validate before merge
  - Conversations with replies → maintain order

---

## CodeRabbit Integration

**Quality Checks:**
- [ ] Migration reversibility (add down migration)
- [ ] Service transaction safety (rollback on error)
- [ ] Unique constraint enforcement
- [ ] Audit logging completeness
- [ ] FK integrity (no orphaned records)
- [ ] Data loss prevention (validate before delete)

**Self-Healing:** Light mode enabled (max 2 iterations)

---

## Developer Handoff

**Phase 1: Database & Model**
1. Create migration: add `merged_to_id`, `is_merged`, `merge_reason`, `merged_at`, `merged_by_id`
2. Create migration: add unique constraint on (account_id, phone_number)
3. Update `Contact` model:
   ```ruby
   belongs_to :merged_to, class_name: 'Contact', optional: true
   has_many :merged_contacts, class_name: 'Contact', foreign_key: 'merged_to_id'
   scope :unmerged, -> { where(is_merged: false) }
   ```

**Phase 2: Service & Job**
1. Create `ContactDeduplicationService`
2. Create `DedupContactsJob` (weekly schedule)
3. Create audit log table or use existing

**Phase 3: API**
1. Add POST endpoint: `/contacts/:id/merge_with/:duplicate_id`
2. Update contact creation to check for duplicates
3. Add validation to prevent duplicate creation

**Phase 4: Frontend**
1. Update `ContactPipelineCard.vue`:
   - Show multiple conversations in dropdown
   - Show "X chats" badge if multiple
2. Update store: handle merged contact data
3. Update conversation selection: allow choosing which channel to reply on

**Testing:**
- Create 2 contacts with same phone → system blocks duplicate
- Manually merge contacts via API → verify conversations consolidated
- View merged contact → see all conversations in dropdown
- Reload page → merged state persists
- Run dedup job → finds and merges similar contacts
- No data loss: all messages visible

**PR Title:** `feat(contacts): implement contact deduplication and consolidation`

---

## Rollout Strategy

1. **Phase 1:** Deploy migrations + service (no impact, no UI yet)
2. **Phase 2:** Enable auto-dedup job (weekly, low-impact)
3. **Phase 3:** Deploy API endpoints
4. **Phase 4:** Deploy UI changes (show consolidation)
5. **Monitor:** Watch for errors, audit log for merges

---

**Created:** 2026-05-04  
**Assigned To:** @dev (Dex)  
**Blocks:** None  
**Blocked By:** None (but do LAST for stability)  
**Story Template Version:** 1.0
