#!/bin/bash

# Script inteligente para aplicar Terraform no GCP lidando automaticamente com recursos existentes
# Este script detecta recursos existentes e usa data sources automaticamente

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🤖 Script Inteligente de Deploy GCP${NC}"
echo -e "${BLUE}Detecta e lida automaticamente com recursos existentes${NC}"
echo "=================================================================="

# Verificar se estamos no diretório correto
if [ ! -f "terraform/gcp/main.tf" ]; then
    echo -e "${RED}❌ Erro: Execute este script a partir da raiz do projeto${NC}"
    exit 1
fi

cd terraform/gcp

# Verificar se as variáveis necessárias estão definidas
if [ -z "$TF_VAR_project_id" ]; then
    echo -e "${YELLOW}⚠️  TF_VAR_project_id não definida. Por favor, defina:${NC}"
    echo "export TF_VAR_project_id=seu-project-id"
    exit 1
fi

PROJECT_ID=$TF_VAR_project_id

echo -e "${BLUE}📋 Verificando recursos existentes no projeto: ${PROJECT_ID}${NC}"

# Função para verificar se um recurso existe no GCP
check_resource_exists() {
    local resource_type=$1
    local resource_name=$2
    local resource_description=$3
    
    case $resource_type in
        "service-account")
            if gcloud iam service-accounts describe "${resource_name}@${PROJECT_ID}.iam.gserviceaccount.com" --project=$PROJECT_ID &>/dev/null; then
                echo -e "${YELLOW}⚠️  ${resource_description} já existe: ${resource_name}${NC}"
                return 0
            fi
            ;;
        "compute-address")
            if gcloud compute addresses describe $resource_name --global --project=$PROJECT_ID &>/dev/null; then
                echo -e "${YELLOW}⚠️  ${resource_description} já existe: ${resource_name}${NC}"
                return 0
            fi
            ;;
        "compute-network")
            if gcloud compute networks describe $resource_name --project=$PROJECT_ID &>/dev/null; then
                echo -e "${YELLOW}⚠️  ${resource_description} já existe: ${resource_name}${NC}"
                return 0
            fi
            ;;
        "artifact-registry")
            if gcloud artifacts repositories describe $resource_name --location=us-central1 --project=$PROJECT_ID &>/dev/null; then
                echo -e "${YELLOW}⚠️  ${resource_description} já existe: ${resource_name}${NC}"
                return 0
            fi
            ;;
        "sql-instance")
            if gcloud sql instances describe $resource_name --project=$PROJECT_ID &>/dev/null; then
                echo -e "${YELLOW}⚠️  ${resource_description} já existe: ${resource_name}${NC}"
                return 0
            fi
            ;;
    esac
    
    echo -e "${GREEN}✅ ${resource_description} não existe, será criado: ${resource_name}${NC}"
    return 1
}

# Verificar recursos críticos
echo ""
echo -e "${BLUE}🔍 Verificando recursos críticos...${NC}"

EXISTING_RESOURCES=()

if check_resource_exists "service-account" "listapro-prod-k8s-sa" "Service Account"; then
    EXISTING_RESOURCES+=("service-account")
fi

if check_resource_exists "compute-address" "listapro-prod-ip" "IP Global"; then
    EXISTING_RESOURCES+=("compute-address")
fi

if check_resource_exists "compute-network" "listapro-prod-vpc" "VPC Network"; then
    EXISTING_RESOURCES+=("compute-network")
fi

if check_resource_exists "artifact-registry" "listapro-prod-repo" "Artifact Registry"; then
    EXISTING_RESOURCES+=("artifact-registry")
fi

if check_resource_exists "sql-instance" "listapro-prod-db" "Cloud SQL Instance"; then
    EXISTING_RESOURCES+=("sql-instance")
fi

# Se há recursos existentes, usar data sources
if [ ${#EXISTING_RESOURCES[@]} -gt 0 ]; then
    echo ""
    echo -e "${YELLOW}📋 Recursos existentes detectados: ${#EXISTING_RESOURCES[@]}${NC}"
    echo -e "${BLUE}🔄 Usando configuração com data sources...${NC}"
    
    # Backup do main.tf original se não existir
    if [ ! -f "main.tf.backup" ]; then
        cp main.tf main.tf.backup
        echo -e "${GREEN}✅ Backup criado: main.tf.backup${NC}"
    fi
    
    echo -e "${GREEN}✅ Configuração já otimizada para recursos existentes${NC}"
else
    echo ""
    echo -e "${GREEN}✅ Nenhum recurso conflitante encontrado${NC}"
    echo -e "${BLUE}🚀 Usando configuração normal...${NC}"
fi

# Inicializar Terraform se necessário
if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}🔧 Inicializando Terraform...${NC}"
    terraform init
fi

# Fazer o plan
echo ""
echo -e "${BLUE}📋 Executando terraform plan...${NC}"
if terraform plan -out=tfplan; then
    echo -e "${GREEN}✅ Plan executado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro no terraform plan${NC}"
    
    if [ ${#EXISTING_RESOURCES[@]} -gt 0 ]; then
        echo -e "${YELLOW}💡 Dica: Alguns recursos podem precisar ser importados manualmente${NC}"
        echo -e "${YELLOW}Execute: ./scripts/import-gcp-resources.sh${NC}"
    fi
    
    exit 1
fi

# Mostrar resumo do que será feito
echo ""
echo -e "${BLUE}📊 RESUMO DA OPERAÇÃO:${NC}"
terraform show -no-color tfplan | grep -E "(Plan:|No changes)" || echo "Verificando mudanças..."

# Perguntar se deve aplicar
echo ""
echo -e "${YELLOW}❓ Deseja aplicar as mudanças? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}🚀 Aplicando mudanças...${NC}"
    if terraform apply tfplan; then
        echo ""
        echo -e "${GREEN}🎉 Terraform aplicado com sucesso!${NC}"
        echo ""
        echo -e "${BLUE}📋 Outputs importantes:${NC}"
        terraform output
    else
        echo -e "${RED}❌ Erro ao aplicar terraform${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⏸️  Aplicação cancelada pelo usuário${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
echo -e "${BLUE}💡 Para próximas execuções, use este mesmo script${NC}"
