# Pipelines de CI/CD - ListaPro

## 🔄 4 Pipelines Implementadas

Conforme solicitado na entrega, o projeto possui **4 pipelines distintas**:

### 1. **infra-stage.yml** - Infraestrutura Stage (Digital Ocean)
- **Trigger**: Push em `develop/stage` com mudanças em `terraform/digital-ocean/`, `K8s/stage/` ou `helm/`
- **Função**: Criar/atualizar infraestrutura no Digital Ocean
- **Inclui**: Terraform, Kubernetes cluster, PostgreSQL, monitoramento

### 2. **app-stage.yml** - Aplicação Stage (Digital Ocean)
- **Trigger**: Push em `develop/stage` com mudanças no código da aplicação
- **Função**: Build e deploy apenas da aplicação
- **Inclui**: Docker build, push para registry, kubectl apply

### 3. **infra-production.yml** - Infraestrutura Production (GCP)
- **Trigger**: Push em `main/master` com mudanças em `terraform/gcp/`, `K8s/prod/` ou `helm/`
- **Função**: Criar/atualizar infraestrutura no GCP
- **Inclui**: Terraform, GKE, Cloud SQL, monitoramento

### 4. **app-production.yml** - Aplicação Production (GCP)
- **Trigger**: Push em `main/master` com mudanças no código da aplicação
- **Função**: Build e deploy apenas da aplicação
- **Inclui**: Docker build, push para Artifact Registry, kubectl apply

---

## 🎯 Estratégia de Deploy

### Primeira Vez (Infraestrutura + Aplicação)
1. Execute `infra-stage.yml` ou `infra-production.yml`
2. Execute `app-stage.yml` ou `app-production.yml`

### Updates de Código (Apenas Aplicação)
- Apenas `app-stage.yml` ou `app-production.yml` são executadas
- **Muito mais rápido** (2-5 min vs 15-20 min)
- Reutiliza infraestrutura existente

### Updates de Infraestrutura
- Apenas `infra-stage.yml` ou `infra-production.yml` são executadas
- Aplica mudanças na infraestrutura sem rebuildar aplicação

---

## 📂 Triggers por Caminho

### Infraestrutura
```yaml
paths:
  - 'terraform/**'
  - 'K8s/**'
  - 'helm/**'
```

### Aplicação
```yaml
paths:
  - 'app/**'
  - 'components/**'
  - 'lib/**'
  - 'Dockerfile'
  - 'package.json'
```

---

## 🚀 Como Usar

### Para Deploy de Infraestrutura:
```bash
# Stage
git add terraform/digital-ocean/
git commit -m "Update stage infrastructure"
git push origin develop

# Production
git add terraform/gcp/
git commit -m "Update production infrastructure"
git push origin main
```

### Para Deploy de Aplicação:
```bash
# Stage
git add app/ components/
git commit -m "Update frontend features"
git push origin develop

# Production
git add app/ components/
git commit -m "Update frontend features"
git push origin main
```

---

## ✅ Benefícios

1. **Separação de Responsabilidades**: Infraestrutura vs Aplicação
2. **Deploy Rápido**: Updates de código não recriam infraestrutura
3. **Segurança**: Ambientes separados para infra e app
4. **Eficiência**: Apenas o que mudou é deployado
5. **Compliance**: Atende aos 4 pipelines requisitados

---

**Total: 4 pipelines distintas conforme solicitado na entrega!** 🎉
