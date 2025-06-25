# 🚀 Pipelines de Staging - Digital Ocean

## 📋 Visão Geral

Este documento detalha as pipelines de staging para o ambiente Digital Ocean, incluindo tanto a infraestrutura quanto o build/deploy da aplicação.

## 🏗️ Pipeline de Infraestrutura (Manual)

### Arquivo: `.github/workflows/infra-staging.yml`

**Características:**
- ✋ **Manual**: Disparada apenas via `workflow_dispatch`
- 🛡️ **Confirmação obrigatória**: Requer digitação de "CONFIRMO"
- 🔄 **Idempotente**: Detecta recursos existentes
- 🎯 **Ações suportadas**: plan, apply, destroy

**Como usar:**
1. Vá em Actions → "🏗️ Deploy Infrastructure - Staging (Digital Ocean) - MANUAL"
2. Clique em "Run workflow"
3. Digite "CONFIRMO" no campo de confirmação
4. Escolha a ação (plan/apply/destroy)

**Recursos criados:**
- Container Registry: `listapro-staging-registry`
- Kubernetes Cluster: `listapro-staging-cluster`
- Namespace: `listapro-stage`

## 🚀 Pipeline de Build & Deploy (Automática)

### Arquivo: `.github/workflows/build-stage.yml`

**Características:**
- 🔄 **Automática**: Dispara em push para branches `develop` ou `staging`
- 🧪 **Testes**: Executa testes antes do build
- 🔍 **Verificação de infraestrutura**: Confirma que a infra existe
- 📦 **Build e push**: Constrói e envia imagem para registry
- 🚢 **Deploy**: Aplica manifests Kubernetes

**Fluxo de execução:**
1. **Test**: Executa `npm test`
2. **Check Infrastructure**: Verifica se cluster existe
3. **Build & Push**: Constrói imagem Docker e faz push
4. **Deploy**: Aplica manifests K8s existentes em `K8s/stage/`

## 📁 Estrutura de Manifests Kubernetes

```
K8s/stage/
├── namespace-stage.yaml          # Namespace listapro-stage
├── frontend/
│   ├── frontend-stage-config.yml    # ConfigMap
│   ├── frontend-stage-deployment.yml # Deployment principal
│   └── frontend-stage-service.yml    # Service
├── backend/                      # Manifests do backend
└── DB/                          # Manifests do banco
```

## 🔑 Secrets Necessários

### Digital Ocean
- `DO_STAGING_TOKEN`: Token de acesso para Digital Ocean

### Aplicação (se necessário)
- `GITHUB_CLIENT_ID`: Cliente ID do GitHub OAuth
- `GITHUB_CLIENT_SECRET`: Client Secret do GitHub OAuth
- `JWT_SECRET_STAGING`: Secret para JWT em staging
- `SESSION_SECRET_STAGING`: Secret para sessões em staging

### Banco de Dados (se necessário)
- `DATABASE_URL_STAGING`: URL completa do banco
- `DB_HOST_STAGING`: Host do banco
- `DB_PORT_STAGING`: Porta do banco
- `DB_NAME_STAGING`: Nome do banco
- `DB_USER_STAGING`: Usuário do banco
- `DB_PASSWORD_STAGING`: Senha do banco

## 🛠️ Scripts de Deploy

### `scripts/smart-deploy-do.sh`
Script específico para Digital Ocean que:
- 🔍 Detecta recursos existentes
- 📦 Cria registry se não existir
- 🚢 Cria cluster K8s se não existir
- 🏷️ Configura namespace e labels
- ⚙️ Configura kubectl automaticamente

### `scripts/universal-deploy.sh`
Script universal que delega para o script específico da nuvem.

## 🔄 Fluxo de Trabalho Recomendado

### 1. Deploy inicial da infraestrutura
```bash
# Via interface GitHub Actions
1. Actions → "Deploy Infrastructure - Staging" 
2. Run workflow
3. Confirmar com "CONFIRMO"
4. Escolher "apply"
```

### 2. Deploy da aplicação
```bash
# Automático: faça push para branch develop ou staging
git push origin develop

# Ou manual via interface
1. Actions → "Build & Deploy - Staging"
2. Run workflow
3. Opcional: especificar tag da imagem
```

### 3. Verificação
```bash
# Configurar kubectl
doctl kubernetes cluster kubeconfig save listapro-staging-cluster

# Verificar pods
kubectl get pods -n listapro-stage

# Verificar serviços
kubectl get services -n listapro-stage

# Logs do frontend
kubectl logs -f deployment/listapro-frontend-stage -n listapro-stage
```

## 🔧 Comandos Úteis

### Digital Ocean CLI
```bash
# Listar clusters
doctl kubernetes cluster list

# Listar registries
doctl registry list

# Configurar kubectl
doctl kubernetes cluster kubeconfig save listapro-staging-cluster

# Login no registry
doctl registry login
```

### Kubernetes
```bash
# Status do cluster
kubectl cluster-info

# Pods do staging
kubectl get pods -n listapro-stage

# Serviços do staging
kubectl get services -n listapro-stage

# Logs em tempo real
kubectl logs -f deployment/listapro-frontend-stage -n listapro-stage

# Descrever pod com problemas
kubectl describe pod <pod-name> -n listapro-stage
```

### Troubleshooting
```bash
# Verificar status do cluster
doctl kubernetes cluster get listapro-staging-cluster

# Reconfigurar kubectl se necessário
doctl kubernetes cluster kubeconfig save listapro-staging-cluster --expiry-seconds 3600

# Verificar imagens no registry
doctl registry repository list-tags listapro-staging-registry/listapro-frontend
```

## 🚨 Solução de Problemas

### Pipeline de infraestrutura falha
1. Verificar se `DO_STAGING_TOKEN` está configurado nos secrets
2. Verificar se o token tem permissões para criar clusters e registries
3. Verificar se a região especificada está disponível

### Pipeline de build falha
1. Verificar se a infraestrutura foi criada primeiro
2. Verificar logs de build do Docker
3. Verificar se o registry está acessível

### Deploy falha
1. Verificar se kubectl está configurado corretamente
2. Verificar se os manifests K8s estão corretos
3. Verificar recursos do cluster (CPU, memória)

## 📊 Monitoramento

### Métricas importantes
- Status dos pods: `kubectl get pods -n listapro-stage`
- Uso de recursos: `kubectl top pods -n listapro-stage`
- Events: `kubectl get events -n listapro-stage`

### Logs
- Application logs: `kubectl logs deployment/listapro-frontend-stage -n listapro-stage`
- Ingress logs: Verificar configuração de ingress se aplicável

## 🔗 Links Úteis

- [Digital Ocean Kubernetes Documentation](https://docs.digitalocean.com/products/kubernetes/)
- [doctl CLI Reference](https://docs.digitalocean.com/reference/doctl/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

---

📝 **Nota**: Este documento se refere especificamente ao ambiente de staging. Para produção, consulte a documentação das pipelines de produção.
