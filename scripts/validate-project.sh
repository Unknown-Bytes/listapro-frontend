#!/bin/bash

# Script para validar se todos os critérios de avaliação foram atendidos
set -e

echo "🔍 Validando critérios de avaliação do projeto..."
echo "================================================"

# Função para verificar se um arquivo existe
check_file() {
    if [ -f "$1" ]; then
        echo "✅ $1 - Existe"
        return 0
    else
        echo "❌ $1 - Não encontrado"
        return 1
    fi
}

# Função para verificar se um diretório existe
check_dir() {
    if [ -d "$1" ]; then
        echo "✅ $1 - Diretório existe"
        return 0
    else
        echo "❌ $1 - Diretório não encontrado"
        return 1
    fi
}

# Função para verificar conteúdo em arquivo
check_content() {
    if grep -q "$2" "$1" 2>/dev/null; then
        echo "✅ $1 contém '$2'"
        return 0
    else
        echo "❌ $1 não contém '$2'"
        return 1
    fi
}

echo ""
echo "📋 CRITÉRIO 1: ATIVIDADES SEMANAIS"
echo "=================================="

echo ""
echo "1.1 Semanal 1 - Infraestrutura Terraform:"
check_dir "terraform"
check_dir "terraform/digital-ocean"
check_dir "terraform/gcp"
check_file "terraform/digital-ocean/main.tf"
check_file "terraform/digital-ocean/variables.tf"
check_file "terraform/digital-ocean/outputs.tf"
check_file "terraform/gcp/main.tf"
check_file "terraform/gcp/variables.tf"
check_file "terraform/gcp/outputs.tf"

echo ""
echo "1.2 Semanal 2 - Pipelines CI/CD:"
check_dir ".github/workflows"
check_file ".github/workflows/deploy-stage.yml"
check_file ".github/workflows/deploy-production.yml"
check_content ".github/workflows/deploy-stage.yml" "Digital Ocean"
check_content ".github/workflows/deploy-production.yml" "GCP"

echo ""
echo "1.3 Semanal 3 - Monitoramento com Helm:"
check_dir "helm"
check_dir "helm/monitoring"
check_file "helm/monitoring/Chart.yaml"
check_file "helm/monitoring/values.yaml"
check_file "helm/monitoring/values-stage.yaml"
check_file "helm/monitoring/values-production.yaml"
check_content "helm/monitoring/Chart.yaml" "prometheus"
check_content "helm/monitoring/Chart.yaml" "grafana"

echo ""
echo "📋 CRITÉRIO 2: AUTOMAÇÃO"
echo "========================"

echo ""
echo "2.1 Pipeline de criação ambiente de homologação:"
check_content ".github/workflows/deploy-stage.yml" "terraform-plan"
check_content ".github/workflows/deploy-stage.yml" "terraform-apply"
check_content ".github/workflows/deploy-stage.yml" "build-and-push"
check_content ".github/workflows/deploy-stage.yml" "deploy"

echo ""
echo "2.2 Pipeline de atualização ambiente de produção:"
check_content ".github/workflows/deploy-production.yml" "terraform-plan"
check_content ".github/workflows/deploy-production.yml" "terraform-apply"
check_content ".github/workflows/deploy-production.yml" "build-and-push"
check_content ".github/workflows/deploy-production.yml" "deploy"

echo ""
echo "📋 CRITÉRIO 3: DEPLOY NA NUVEM"
echo "=============================="

echo ""
echo "3.1 Diagrama da infraestrutura:"
check_file "DOCS.md"
check_content "DOCS.md" "ARQUITETURA MULTINUVEM"
check_content "DOCS.md" "DIGITAL OCEAN"
check_content "DOCS.md" "GOOGLE CLOUD"

echo ""
echo "3.2 & 3.3 Ambientes configurados:"
check_dir "K8s/prod"
check_dir "K8s/stage"
check_file "K8s/prod/namespace-prod.yaml"
check_file "K8s/stage/namespace-stage.yaml"
check_file "K8s/prod/frontend/frontend-prod-deployment.yml"
check_file "K8s/stage/frontend/frontend-stage-deployment.yml"

echo ""
echo "3.4 Observabilidade configurada:"
check_content "helm/monitoring/values.yaml" "prometheus"
check_content "helm/monitoring/values.yaml" "grafana"
check_content "K8s/prod/frontend/frontend-prod-deployment.yml" "prometheus.io/scrape"
check_content "K8s/stage/frontend/frontend-stage-deployment.yml" "prometheus.io/scrape"

echo ""
echo "3.5 Testes de observabilidade:"
check_file "app/api/health/route.ts"
check_file "app/api/ready/route.ts"
check_file "app/api/metrics/route.ts"

echo ""
echo "3.6 CRUD de teste:"
check_file "app/page.tsx"
check_file "app/Home.tsx"
check_file "components/TaskList.tsx"

echo ""
echo "📋 VERIFICAÇÕES ADICIONAIS"
echo "=========================="

echo ""
echo "Infraestrutura como Código:"
check_content "terraform/digital-ocean/main.tf" "digitalocean_kubernetes_cluster"
check_content "terraform/gcp/main.tf" "google_container_cluster"
check_content "terraform/digital-ocean/main.tf" "digitalocean_database_cluster"
check_content "terraform/gcp/main.tf" "google_sql_database_instance"

echo ""
echo "Configuração Docker:"
check_file "Dockerfile"
check_content "Dockerfile" "nginx"

echo ""
echo "Scripts de Deployment:"
check_file "scripts/deployment/deploy-stage.sh"
check_file "scripts/deployment/deploy-production.sh"

echo ""
echo "Documentação:"
check_file ".env.example"
check_content ".env.example" "DO_TOKEN"
check_content ".env.example" "GCP_CREDENTIALS"

echo ""
echo "================================================"
echo "🎯 RESUMO DA VALIDAÇÃO"
echo "================================================"

# Contar arquivos críticos
critical_files=(
    "terraform/digital-ocean/main.tf"
    "terraform/gcp/main.tf"
    ".github/workflows/deploy-stage.yml"
    ".github/workflows/deploy-production.yml"
    "helm/monitoring/Chart.yaml"
    "app/api/health/route.ts"
    "app/api/metrics/route.ts"
    "DOCS.md"
)

missing_files=0
total_files=${#critical_files[@]}

for file in "${critical_files[@]}"; do
    if [ ! -f "$file" ]; then
        ((missing_files++))
    fi
done

present_files=$((total_files - missing_files))

echo "📊 Arquivos críticos: $present_files/$total_files presentes"

if [ $missing_files -eq 0 ]; then
    echo "✅ TODOS OS CRITÉRIOS FORAM ATENDIDOS!"
    echo ""
    echo "🚀 PRÓXIMOS PASSOS:"
    echo "1. Configure as variáveis de ambiente (.env.example)"
    echo "2. Crie as contas nas nuvens (Digital Ocean + GCP)"
    echo "3. Configure os secrets no GitHub"
    echo "4. Faça push para as branches develop/stage e main"
    echo "5. Monitore os deploys via GitHub Actions"
    echo ""
    echo "📖 Consulte DOCS.md para instruções detalhadas"
    exit 0
else
    echo "⚠️  Faltam $missing_files arquivos críticos"
    echo "Verifique os itens marcados com ❌ acima"
    exit 1
fi
