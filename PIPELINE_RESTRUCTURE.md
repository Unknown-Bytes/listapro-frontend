# 🚀 Nova Estrutura de Pipelines - ListaPro

## 📋 Resumo da Reestruturação

A estrutura foi reorganizada para separar **infraestrutura** e **aplicação**, seguindo o modelo funcional do Digital Ocean como referência.

## 🏗️ Pipelines de Infraestrutura (Manuais)

### ✅ Características:
- **Execução manual** via `workflow_dispatch`
- **Não reconstroem** clusters existentes
- **Detectam recursos** existentes automaticamente
- **Idempotentes** - podem ser executadas múltiplas vezes
- **Suportam ações**: plan, apply, destroy

### 📁 Arquivos:
```
.github/workflows/
├── infra-gcp-production-manual.yml     # GCP Produção (Manual)
├── infra-gcp-staging-manual.yml        # GCP Staging (Manual)
├── infra-do-production-manual.yml      # Digital Ocean Produção (Manual)
└── infra-do-staging-manual.yml         # Digital Ocean Staging (Manual)
```

## 🚀 Pipelines de Aplicação (Automáticas)

### ✅ Características:
- **Execução automática** em push para main/master
- **Deploy apenas da aplicação** (não toca infraestrutura)
- **Build e push** de imagens Docker
- **Deploy no Kubernetes** existente
- **Verificação** de deployment

### 📁 Arquivos:
```
.github/workflows/
├── app-gcp-production.yml              # Deploy App GCP Produção
├── app-gcp-staging.yml                 # Deploy App GCP Staging  
├── app-do-production.yml               # Deploy App Digital Ocean Produção
└── app-do-staging.yml                  # Deploy App Digital Ocean Staging
```

## 🛠️ Scripts Inteligentes

### 🌐 Universal Deploy
```bash
./scripts/universal-deploy.sh [cloud] [environment] [action]

# Exemplos:
./scripts/universal-deploy.sh gcp production plan
./scripts/universal-deploy.sh digitalocean staging apply
```

### ☁️ Scripts Específicos por Cloud

#### GCP:
```bash
./scripts/smart-deploy-gcp.sh [environment] [action]
./scripts/import-gcp-resources.sh
./scripts/cleanup-gcp-resources.sh
./scripts/test-gcp-config.sh
./scripts/apply-gcp-terraform.sh
```

#### Digital Ocean:
```bash
./scripts/smart-deploy-do.sh [environment] [registry_name]
```

## 🎯 Fluxo de Trabalho Recomendado

### 1. 🏗️ Deploy de Infraestrutura (Primeira vez)

1. **Executar pipeline manual** de infraestrutura:
   - Ir para GitHub Actions
   - Selecionar pipeline de infraestrutura (ex: `infra-gcp-production-manual.yml`)
   - Clicar em "Run workflow"
   - Escolher ação: `plan` primeiro, depois `apply`

2. **Ou usar script local**:
   ```bash
   ./scripts/universal-deploy.sh gcp production plan
   ./scripts/universal-deploy.sh gcp production apply
   ```

### 2. 🚀 Deploy de Aplicação (Automático)

1. **Push código** para main/master
2. **Pipeline automática** será executada
3. **Aplicação é atualizada** sem tocar na infraestrutura

## 🔧 Correções Implementadas

### ✅ Problemas Resolvidos:
1. **Separação infra/app** - Evita reconstrução desnecessária de clusters
2. **Detecção automática** - Scripts verificam recursos existentes
3. **Pipelines manuais** - Infraestrutura controlada manualmente
4. **Plugin GKE** - Instalação automática do `gke-gcloud-auth-plugin`
5. **Nomes únicos** - Recursos com nomes que evitam conflitos
6. **Quota otimizada** - Configurações menores para economizar recursos

### ⚠️ Importante:
- **Infraestrutura**: Use pipelines manuais ou scripts locais
- **Aplicação**: Push para main/master faz deploy automático
- **Primeira vez**: Execute infra primeiro, depois app
- **Secrets**: Configure todos os secrets necessários no GitHub

## 📚 Documentação Adicional

- `DOCS.md` - Documentação completa
- `SCRIPTS_GUIDE.md` - Guia detalhado dos scripts
- `TROUBLESHOOTING.md` - Solução de problemas

## 🎉 Resultado

✅ **4 pipelines separadas** (2 infra manuais + 2 app automáticas por cloud)
✅ **Automação completa** com detecção de recursos
✅ **Documentação atualizada** 
✅ **Escopo original mantido** - Não quebra a entrega
✅ **Baseado no modelo funcional** do Digital Ocean
