# 🔍 Diagnóstico da Infraestrutura GCP

## Problema Identificado

A pipeline de produção está falhando porque não consegue encontrar o cluster GCP. Isso pode acontecer por alguns motivos:

1. **Nome do cluster**: O cluster foi criado com um nome diferente do esperado
2. **Zona/Região**: O cluster está em uma zona diferente 
3. **Projeto**: O cluster está em um projeto GCP diferente
4. **Permissões**: As credenciais não têm acesso ao cluster

## 🚀 Solução Rápida

### Opção 1: Descobrir o nome do cluster manualmente

Execute este comando no seu terminal local (com gcloud configurado):

```bash
# Listar todos os clusters no projeto
gcloud container clusters list

# Ou usar nosso script
./scripts/list-gcp-clusters.sh
```

### Opção 2: Configurar o secret correto

Depois de descobrir o nome do cluster, configure o secret no GitHub:

1. Vá em Settings → Secrets and variables → Actions
2. Adicione/edite o secret: `GKE_CLUSTER_NAME` com o nome correto do cluster

### Opção 3: Testar via GitHub Actions

Criei uma versão melhorada da pipeline que tenta encontrar automaticamente o cluster procurando por nomes comuns:

- `GKE_CLUSTER_NAME` (se configurado)
- `prod-cluster` 
- `listapro-prod-cluster`
- `listapro-production`
- `production-cluster`

E procura nas zonas:
- `us-central1-a`
- `us-central1-b` 
- `us-central1-c`
- `us-central1`

## 🔧 Próximos Passos

1. **Execute o script de diagnóstico**:
   ```bash
   ./scripts/list-gcp-clusters.sh
   ```

2. **Identifique o nome correto do cluster** na saída

3. **Configure o secret** `GKE_CLUSTER_NAME` no GitHub com o nome correto

4. **Teste a pipeline** fazendo um push para `main` ou executando manualmente

## 📋 Informações Necessárias

Para resolver definitivamente, preciso saber:

- ✅ **Nome exato do cluster** (ex: `my-production-cluster`)
- ✅ **Zona onde está** (ex: `us-central1-a`) 
- ✅ **Projeto GCP** (ex: `my-project-123456`)

## 🛠️ Script de Diagnóstico Completo

Se preferir, pode executar este comando diretamente:

```bash
echo "🔍 Diagnóstico GCP:"
echo "Projeto atual: $(gcloud config get-value project)"
echo "Conta ativa: $(gcloud auth list --filter=status:ACTIVE --format='value(account)')"
echo ""
echo "📦 Clusters disponíveis:"
gcloud container clusters list --format="table(name,location,status,currentMasterVersion)"
```

## ⚡ Teste Manual da Conexão

Depois de identificar o cluster, teste a conexão:

```bash
# Substitua CLUSTER_NAME e ZONA pelos valores corretos
gcloud container clusters get-credentials CLUSTER_NAME --zone=ZONA --project=PROJECT_ID

# Teste se funcionou
kubectl get nodes
kubectl get namespaces
```

---

Assim que souber o nome correto do cluster, posso ajustar a configuração para que funcione perfeitamente! 🚀
