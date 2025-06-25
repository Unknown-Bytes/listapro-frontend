# 🧹 Limpeza de Scripts - ListaPro

## ✅ Scripts Removidos (Não Utilizados pelas Pipelines)

### 📂 Scripts GCP (Não utilizados)
- ❌ `apply-gcp-terraform.sh` - Terraform para GCP (substituído por universal-deploy)
- ❌ `cleanup-gcp-resources.sh` - Limpeza de recursos GCP
- ❌ `deploy-gcp.sh` - Deploy direto GCP
- ❌ `import-gcp-resources.sh` - Import de recursos GCP
- ❌ `list-gcp-clusters.sh` - Listagem de clusters GCP
- ❌ `smart-deploy-gcp.sh` - Deploy inteligente GCP
- ❌ `test-gcp-config.sh` - Teste configuração GCP

### 📂 Scripts DigitalOcean (Não utilizados)
- ❌ `deploy-digitalocean.sh` - Deploy direto DO
- ❌ `smart-prod-deploy-do.sh` - Deploy produção DO específico

### 📂 Scripts Gerais (Não utilizados)
- ❌ `init-letsencrypt.sh` - Inicialização Let's Encrypt
- ❌ `universal-deploy-new.sh` - Versão nova do universal-deploy
- ❌ `validate-project.sh` - Validação de projeto

### 📂 Diretório Removido
- ❌ `deployment/` - Diretório completo com scripts de deploy antigos
  - ❌ `deploy-production.sh`
  - ❌ `deploy-stage.sh`

## ✅ Scripts Mantidos (Utilizados pelas Pipelines)

### 🎯 Scripts Ativos
- ✅ **`universal-deploy.sh`** - Usado em `infra-prod.yml` e `infra-staging.yml`
- ✅ **`smart-deploy-do.sh`** - Usado em `infra-prod.yml` e `infra-staging.yml`

### 🔍 Scripts Opcionais (Verificados pelas pipelines)
- 🔄 `install-simple-infrastructure-no-traefik.sh` - Verificado se existe
- 🔄 `clean-orphaned-webhooks.sh` - Verificado se existe

## 📊 Resumo da Limpeza

### Antes:
```
scripts/
├── apply-gcp-terraform.sh           ❌
├── cleanup-gcp-resources.sh         ❌
├── deploy-digitalocean.sh           ❌
├── deploy-gcp.sh                    ❌
├── import-gcp-resources.sh          ❌
├── init-letsencrypt.sh              ❌
├── list-gcp-clusters.sh             ❌
├── smart-deploy-do.sh               ✅
├── smart-deploy-gcp.sh              ❌
├── smart-prod-deploy-do.sh          ❌
├── test-gcp-config.sh               ❌
├── universal-deploy-new.sh          ❌
├── universal-deploy.sh              ✅
├── validate-project.sh              ❌
└── deployment/                      ❌
    ├── deploy-production.sh         ❌
    └── deploy-stage.sh              ❌
```

### Depois:
```
scripts/
├── smart-deploy-do.sh               ✅
└── universal-deploy.sh              ✅
```

## 🎯 Benefícios da Limpeza

- **📦 Redução de Complexidade**: Apenas 2 scripts essenciais mantidos
- **🔧 Manutenção Simplificada**: Menos arquivos para manter
- **📚 Documentação Clara**: Scripts ativos claramente identificados
- **⚡ Deploy Mais Limpo**: Estrutura focada nas pipelines atuais
- **🗂️ Organização Melhorada**: Estrutura mais enxuta e focada

## 🔗 Referências nas Pipelines

### Scripts Utilizados:
1. **`.github/workflows/infra-prod.yml`**:
   - Linha 72: `chmod +x scripts/universal-deploy.sh`
   - Linha 73: `chmod +x scripts/smart-deploy-do.sh`
   - Linha 80: `./scripts/universal-deploy.sh digitalocean production`

2. **`.github/workflows/infra-staging.yml`**:
   - Linha 72: `chmod +x scripts/universal-deploy.sh`
   - Linha 73: `chmod +x scripts/smart-deploy-do.sh`
   - Linha 80: `./scripts/universal-deploy.sh digitalocean staging`

### Scripts Opcionais Verificados:
- `install-simple-infrastructure-no-traefik.sh`
- `clean-orphaned-webhooks.sh`

---

**Data da Limpeza**: 25 de junho de 2025  
**Status**: ✅ Completa - Apenas scripts essenciais mantidos
