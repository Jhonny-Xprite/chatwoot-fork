# Guia de Debugging - Importação de Contatos

## Problema Corrigido

O erro HTTP 422 estava relacionado à formatação incorreta de números de telefone. A validação do Contact model exige um formato específico: `+[1-9]\d{1,14}` (máximo 15 dígitos após +).

## Correções Implementadas

### 1. Formatação de Telefone Melhorada
A função `format_phone_number` em `app/services/data_import/contact_manager.rb` agora:
- Valida estritamente contra a regex da validação do Contact model
- Suporta múltiplos formatos brasileiros:
  - `11987654321` → `+5511987654321`
  - `(11) 98765-4321` → `+5511987654321`
  - `011 98765-4321` → `+5511987654321`
  - `+55 11 98765-4321` → `+5511987654321`
  - `5511987654321` → `+5511987654321`
- Rejeita números inválidos (retorna `nil`)

### 2. Logging Detalhado
Foi adicionado logging detalhado em dois pontos:

#### Em `ContactManager.build_contact`:
Mostra qual contato falhou na validação e por quê:
```ruby
error_details = {
  errors: contact.errors.full_messages,
  email: contact.email,
  phone_number: contact.phone_number,
  name: contact.name,
  contact_type: contact.contact_type
}
Rails.logger.error "[Import] Validation Failed: #{error_details.inspect}"
```

#### Em `DataImportJob.import_contacts`:
Mostra exatamente qual dado está sendo enviado ao banco:
```ruby
[DataImport] Contact 1: email="joao@example.com", phone="+5511987654321", name="João Silva"
```

### 3. Proteção Contra Valores Nulos
- Telefones com formatação inválida agora são ignorados (não incluídos na importação)
- Contatos sem email, telefone ou identificador válidos recebem um nome padrão: `Contact {timestamp}`

## Como Testar

### Arquivo CSV de Teste
Um arquivo de teste foi criado em `test_import.csv`:

```csv
Name,Email,Phone
João Silva,joao@example.com,11987654321
Maria Santos,maria@example.com,(11) 98765-4322
Pedro Costa,pedro@example.com,+5511987654323
Ana Oliveira,ana@example.com,011987654324
Carlos Mendes,carlos@example.com,5511987654325
```

Todos os números desta tabela serão convertidos para o formato correto.

### Passos para Testar

1. **Inicie o servidor:**
   ```bash
   npm run dev
   ```

2. **Acesse o Chatwoot em seu navegador:**
   - URL padrão: `http://localhost:3000`

3. **Vá para Contacts > Import:**
   - Carregue o arquivo `test_import.csv`
   - Mapeie as colunas:
     - CSV Header "Name" → Contact Field "name"
     - CSV Header "Email" → Contact Field "email"
     - CSV Header "Phone" → Contact Field "phone_number"

4. **Monitore os logs do Rails:**
   ```bash
   tail -f log/development.log | grep "\[DataImport\]"
   ```

   Você verá algo como:
   ```
   [DataImport] Processing 5 contacts...
   [DataImport] Contact 1: email="joao@example.com", phone="+5511987654321", name="João Silva"
   [DataImport] Contact 2: email="maria@example.com", phone="+5511987654322", name="Maria Santos"
   ...
   [DataImport] Completed - Inserted: 5, Updated: 0, Failed: 0
   ```

5. **Verifique os Contatos:**
   - Vá para Contacts
   - Procure pelos contatos importados
   - Verifique se os telefones estão no formato `+55...`

## Se Ainda Houver Erros

Se você ainda ver erro 422 após essas correções, procure nos logs por:

```bash
grep "Validation Failed" log/development.log
```

A mensagem de erro mostrará exatamente qual validação está falhando, por exemplo:
- `["Email can't be blank"]` - Coluna de email vazia
- `["Phone number is invalid"]` - Número de telefone em formato inválido
- `["Name can't be blank"]` - Nome vazio e sem fallback

## Validações do Contact Model

Estas são as validações que podem causar erros:

| Campo | Validação | Mensagem de Erro |
|-------|-----------|-----------------|
| `account_id` | Obrigatório | "can't be blank" |
| `email` | Opcional, mas se presente deve ser válido | "is invalid" |
| `email` | Único por conta | "has already been taken" |
| `phone_number` | Opcional, mas se presente deve estar em `+[1-9]\d{1,14}` | "is invalid" |
| `phone_number` | Único por conta | "has already been taken" |
| `identifier` | Opcional, mas se presente deve ser único | "has already been taken" |
| `name` | Não validado explicitamente, mas fallback garante que nunca fica vazio | — |

## Mudanças Técnicas

### Arquivos Modificados

1. **app/services/data_import/contact_manager.rb**
   - `normalize_mapping()` - Normaliza chaves e valores do mapeamento
   - `build_contact()` - Adicionado logging detalhado e remoção de valores nil
   - `transform_row()` - Protege contra telefones inválidos
   - `format_phone_number()` - REESCRITO com validação estrita

2. **app/jobs/data_import_job.rb**
   - `import_contacts()` - Adicionado logging detalhado de cada contato

3. **app/controllers/api/v1/accounts/contacts_controller.rb**
   - Validação de mapeamento não-vazio

4. **app/javascript/dashboard/components-next/Contacts/ContactsForm/ContactImportMapper.vue**
   - Expandido dicionário AUTO_MAPPING_DICTIONARY com centenas de variações de nomes de coluna
   - Suporte para `LeadFirstName`, `LeadLastName`, e múltiplas variações
   - Suporte para formatos com espaços, sem espaços, com underscores
   - Suporte para português e inglês
   - Exemplo de mapeamentos automáticos agora suportados:
     - `LeadFirstName` → `first_name`
     - `LeadLastName` → `last_name`
     - `LeadEmail` → `email`
     - `LeadPhone` → `phone_number`
     - `lead first name` → `first_name` (com espaço)
     - `Lead Email Address` → `email`
     - `Telefone_Celular` → `phone_number`

## Próximas Etapas

Se tudo funcionar:
1. Os contatos devem aparecer no Contacts UI
2. Os telefones devem estar no formato `+55...`
3. Você pode verificar os detalhes de um contato para confirmar

Se ainda houver problemas:
1. Compartilhe o trecho relevante do `log/development.log` (especialmente linhas com `[DataImport]` ou `[Import]`)
2. Verifique se o arquivo CSV está em UTF-8 (não ANSI ou outro encoding)
3. Verifique se as colunas do CSV estão mapeadas corretamente no UI de importação
