#!/bin/bash

# Script para remover recursos conflitantes do GCP (CUIDADO - USE APENAS SE NECESSÁRIO)
# Este script remove recursos existentes que estão causando conflito

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}⚠️  SCRIPT DE LIMPEZA DO GCP - USE COM CUIDADO!${NC}"
echo -e "${RED}Este script remove recursos existentes no GCP${NC}"
echo "=================================================================="

# Verificar se as variáveis necessárias estão definidas
if [ -z "$TF_VAR_project_id" ]; then
    echo -e "${YELLOW}⚠️  TF_VAR_project_id não definida. Por favor, defina:${NC}"
    echo "export TF_VAR_project_id=seu-project-id"
    exit 1
fi

PROJECT_ID=$TF_VAR_project_id

echo -e "${YELLOW}Project ID: ${PROJECT_ID}${NC}"
echo ""

# Confirmar três vezes
echo -e "${RED}ATENÇÃO: Esta operação é IRREVERSÍVEL!${NC}"
echo -e "${RED}Você irá DELETAR recursos do projeto: ${PROJECT_ID}${NC}"
echo ""
echo -e "${YELLOW}Digite 'DELETE' para confirmar:${NC}"
read -r confirm1

if [ "$confirm1" != "DELETE" ]; then
    echo -e "${GREEN}Operação cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Tem certeza? Digite 'YES' para confirmar:${NC}"
read -r confirm2

if [ "$confirm2" != "YES" ]; then
    echo -e "${GREEN}Operação cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Última chance. Digite o PROJECT_ID '${PROJECT_ID}' para confirmar:${NC}"
read -r confirm3

if [ "$confirm3" != "$PROJECT_ID" ]; then
    echo -e "${GREEN}Operação cancelada.${NC}"
    exit 0
fi

echo ""
echo -e "${RED}🗑️  Iniciando remoção de recursos...${NC}"

# Função para remover recurso com tratamento de erro
remove_resource() {
    local command=$1
    local resource_name=$2
    
    echo -e "${BLUE}Removendo ${resource_name}...${NC}"
    
    if eval "$command" 2>/dev/null; then
        echo -e "${GREEN}✅ ${resource_name} removido${NC}"
    else
        echo -e "${YELLOW}⚠️  ${resource_name} não foi removido (pode não existir)${NC}"
    fi
}

# Remover recursos em ordem de dependência (bottom-up)

# 1. Cloud SQL Instance (demora mais)
remove_resource \
    "gcloud sql instances delete listapro-prod-db --project=$PROJECT_ID --quiet" \
    "Cloud SQL Instance"

# 2. Artifact Registry
remove_resource \
    "gcloud artifacts repositories delete listapro-prod-repo --location=us-central1 --project=$PROJECT_ID --quiet" \
    "Artifact Registry"

# 3. Service Account
remove_resource \
    "gcloud iam service-accounts delete listapro-prod-k8s-sa@${PROJECT_ID}.iam.gserviceaccount.com --project=$PROJECT_ID --quiet" \
    "Service Account"

# 4. IP Global
remove_resource \
    "gcloud compute addresses delete listapro-prod-ip --global --project=$PROJECT_ID --quiet" \
    "IP Global"

# 5. VPC Network (por último, pois outros recursos podem depender dele)
remove_resource \
    "gcloud compute networks delete listapro-prod-vpc --project=$PROJECT_ID --quiet" \
    "VPC Network"

echo ""
echo -e "${GREEN}🎉 Remoção concluída!${NC}"
echo -e "${BLUE}💡 Agora você pode executar o Terraform normalmente${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. cd terraform/gcp"
echo "2. terraform plan"
echo "3. terraform apply"
