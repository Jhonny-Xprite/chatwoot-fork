# 🚀 GitHub Actions: Auto Build & Push Docker Image

O GitHub Actions vai **automaticamente** fazer build e push da sua imagem Docker para DockerHub sempre que você fazer commit!

---

## ⚙️ Setup (Uma vez só)

### **PASSO 1: Vá ao GitHub**

```
https://github.com/Jhonny-Xprite/chatwoot-fork
```

### **PASSO 2: Settings → Secrets and Variables → Actions**

```
Settings
  → Secrets and variables
  → Actions
  → New repository secret
```

### **PASSO 3: Adicione 2 Secrets**

#### **Secret 1: DOCKER_USERNAME**

```
Name: DOCKER_USERNAME
Value: jhonnyxprite (seu username do DockerHub)

→ Click "Add secret"
```

#### **Secret 2: DOCKER_PASSWORD**

```
Name: DOCKER_PASSWORD
Value: seu_password_do_dockerhub (ou access token)

→ Click "Add secret"
```

---

## 🎯 Como Usar

### **Sempre que você faz commit:**

```bash
git add .
git commit -m "feat: sua mensagem"
git push origin feat/crm-advanced-filters-automation
```

**O GitHub Actions automaticamente:**

1. ✅ Detecta o push
2. ✅ Faz o build da imagem
3. ✅ Faz login no DockerHub
4. ✅ Faz push para `jhonnyxprite/chatwoot-crm:latest`
5. ✅ Completa em ~5 minutos

---

## 📊 Como Verificar

### **No GitHub:**

```
Repository
  → Actions
  → Docker build-push workflow
  → Vê a execução em tempo real
```

### **No DockerHub:**

```
https://hub.docker.com/r/jhonnyxprite/chatwoot-crm
```

Você vai ver a imagem lá com tag `latest` atualizada!

---

## ✅ Depois que Configurar

1. **Faça um commit qualquer** (mesmo que pequeno)
2. **Aguarde ~5 minutos**
3. **Vá ao Actions → vê se passou** ✅
4. **Vá ao DockerHub → vê a imagem atualizada** ✅
5. **Agora sim, deploy no EasyPanel!** 🎉

---

## 🆘 Se Desse Erro

Se a build falhar:

1. Vá em `Actions` → clique no workflow que falhou
2. Clique em "Build and push Docker image"
3. Vê o erro na seção "Build and push"
4. Corrija o Dockerfile
5. Faz commit de novo

---

## 💡 O Que O Workflow Faz

Toda vez que você faz push para `feat/crm-advanced-filters-automation`, `main` ou `develop`, o workflow:

- ✅ Faz pull do código
- ✅ Setup Docker Buildx
- ✅ Login no DockerHub com suas credenciais
- ✅ Build a imagem a partir do Dockerfile
- ✅ Push para DockerHub com tags:
  - `jhonnyxprite/chatwoot-crm:latest` (sempre atualizado)
  - `jhonnyxprite/chatwoot-crm:<commit-sha>` (histórico)

---

**Agora você não precisa fazer build e push manualmente!** 🚀
