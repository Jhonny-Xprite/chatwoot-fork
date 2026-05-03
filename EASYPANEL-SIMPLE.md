# 🚀 Instalação Simples no EasyPanel (SEM Schema)

Se "Create from Schema" está dando erro, use **docker-compose.yml** diretamente!

---

## ✅ Solução Simples em 3 Passos

### **PASSO 1: No EasyPanel Dashboard**

```
Applications → New Application
```

### **PASSO 2: Selecione "Docker Compose"**

```
Source Type:
  ○ Git
  ○ Upload
  ○ Docker Compose ← CLIQUE AQUI
```

### **PASSO 3: Cole o docker-compose.easypanel.yml**

**Abra arquivo:** `docker-compose.easypanel.yml` (na raiz do repo)

**Copie TUDO** e **cole** no campo de Docker Compose no EasyPanel.

---

## 🎯 O Arquivo docker-compose.easypanel.yml Já Tem:

✅ PostgreSQL configurado  
✅ Redis configurado  
✅ Chatwoot App pronto  
✅ Sidekiq pronto  
✅ Variáveis de ambiente  
✅ Volumes para persistência  
✅ Health checks  

Você só precisa definir os valores reais de:

- `SECRET_KEY_BASE`
- `FRONTEND_URL`
- `POSTGRES_PASSWORD`

O restante já possui defaults seguros para subir o ambiente.

---

## 📝 Deploy

1. Cole o arquivo
2. Clique "Validate" (opcional)
3. Clique "Deploy" ou "Create"
4. **Aguarde 5-10 minutos**

---

## 🌐 Acesso

Depois de pronto:

```
http://seu-dominio:3000
```

Ou se EasyPanel configurou proxy:

```
https://seu-dominio.com
```

---

## ✨ Vantagens desta Abordagem

- ✅ Sem erros de schema/React
- ✅ Tudo configurado no docker-compose
- ✅ Pode editar depois se precisar
- ✅ Funciona em qualquer servidor Docker

---

**Cole o arquivo e era!** 🎉
