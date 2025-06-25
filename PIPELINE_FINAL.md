# 🎯 Estrutura Final de Pipelines - ListaPro

## 📋 4 Pipelines Separadas por Ambiente

### 🏗️ **Infraestrutura (Manuais)**

#### 1. `infra-production.yml` 
- **Quando:** Manual via GitHub Actions
- **O que:** Deploy infraestrutura production (Terraform)
- **Controles:** Cloud (GCP/DigitalOcean) + Action (plan/apply/destroy)
- **Environment:** production

#### 2. `infra-staging.yml`
- **Quando:** Manual via GitHub Actions  
- **O que:** Deploy infraestrutura staging (Terraform)
- **Controles:** Cloud (GCP/DigitalOcean) + Action (plan/apply/destroy)
- **Environment:** staging

### ⚙️ **Kubernetes (Automáticas)**

#### 3. `k8s-production.yml`
- **Quando:** Push para `main/master` ou manual
- **O que:** Build + Push + Deploy production
- **Controles:** Cloud (GCP/DigitalOcean/both) + Image tag
- **Environment:** production

#### 4. `k8s-staging.yml`
- **Quando:** Push para `develop/staging` ou manual
- **O que:** Build + Push + Deploy staging
- **Controles:** Cloud (GCP/DigitalOcean/both) + Image tag  
- **Environment:** staging

## 🔄 Fluxo de Trabalho

### 📚 **Estrutura de Branches:**
```
main/master     → Production (automático)
develop/staging → Staging (automático)
```

### 🚀 **Setup Inicial (Uma vez):**

1. **Deploy Infraestrutura Production:**
   - GitHub Actions → `🏗️ Infrastructure - Production` → Run workflow
   - Cloud: `gcp` → Action: `plan` → Depois `apply`

2. **Deploy Infraestrutura Staging:**
   - GitHub Actions → `🏗️ Infrastructure - Staging` → Run workflow
   - Cloud: `gcp` → Action: `plan` → Depois `apply`

### 💻 **Desenvolvimento Diário:**

```bash
# Para Production
git checkout main
git add .
git commit -m "feat: nova feature"
git push origin main
# → k8s-production.yml executa automaticamente

# Para Staging
git checkout develop
git add .
git commit -m "feat: teste nova feature"
git push origin develop  
# → k8s-staging.yml executa automaticamente
```

### 🎛️ **Deploy Manual Específico:**

```bash
# GitHub Actions → ⚙️ Kubernetes - Production/Staging → Run workflow
# Escolher: Cloud + Image tag específico
```

## 📁 Estrutura de Arquivos

```
.github/workflows/
├── infra-production.yml        # 🏗️ Manual (Terraform Prod)
├── infra-staging.yml           # 🏗️ Manual (Terraform Staging)
├── k8s-production.yml          # ⚙️ Auto (K8s Prod)
└── k8s-staging.yml             # ⚙️ Auto (K8s Staging)

K8s/
├── prod/                       # Manifests Production
└── stage/                      # Manifests Staging

scripts/
├── universal-deploy.sh         # Script universal infra
├── smart-deploy-gcp.sh         # GCP específico
└── smart-deploy-do.sh          # DigitalOcean específico
```

## 🎯 **Triggers Automáticos**

| Pipeline | Branch | Paths | Execução |
|----------|--------|-------|----------|
| `k8s-production.yml` | `main`, `master` | `app/**`, `components/**`, `K8s/prod/**` | Automática |
| `k8s-staging.yml` | `develop`, `staging` | `app/**`, `components/**`, `K8s/stage/**` | Automática |
| `infra-production.yml` | - | - | Manual |
| `infra-staging.yml` | - | - | Manual |

## 🔐 **Secrets Necessários**

### **GCP (Ambos Ambientes):**
- `GCP_CREDENTIALS` - Service account JSON
- `GCP_PROJECT_ID` - Project ID
- `DB_PASSWORD` - Database production
- `DB_PASSWORD_STAGING` - Database staging

### **DigitalOcean Production:**
- `DO_TOKEN_PROD` - API token production
- `GITHUB_CLIENT_ID` - OAuth app
- `GITHUB_CLIENT_SECRET` - OAuth secret
- `JWT_SECRET` - JWT secret
- `SESSION_SECRET` - Session secret
- `DATABASE_URL` - Database URL
- `DB_HOST` - Database host
- `DB_USER` - Database user
- `DB_PASSWORD` - Database password

### **DigitalOcean Staging:**
- `DO_STAGING_TOKEN` - API token staging
- `JWT_SECRET_STAGING` - JWT staging
- `SESSION_SECRET_STAGING` - Session staging
- `DATABASE_URL_STAGING` - Database URL staging
- `DB_HOST_STAGING` - Database host staging
- `DB_USER_STAGING` - Database user staging
- `DB_PASSWORD_STAGING` - Database password staging

## ✅ **Vantagens da Estrutura**

1. **🎯 Separação clara:** Infra vs App, Prod vs Staging
2. **🛡️ Segurança:** Infraestrutura manual, apps automáticos
3. **⚡ Eficiência:** Cada pipeline focada em seu ambiente
4. **🔄 Flexibilidade:** Deploy manual quando necessário
5. **🌐 Multi-cloud:** GCP + DigitalOcean suportados
6. **📈 Escalabilidade:** Estrutura preparada para crescimento

## 🎉 **Resultado Final**

✅ **4 pipelines essenciais** (2 infra + 2 k8s)
✅ **Separação por ambiente** (production + staging) 
✅ **Infraestrutura manual** (sem recriação acidental)
✅ **Deploy automático** (push → build → deploy)
✅ **Multi-cloud** (GCP + DigitalOcean)
✅ **Flexibilidade total** (manual quando necessário)
