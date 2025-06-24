#!/bin/bash

# Script para importar recursos existentes no GCP para o estado do Terraform
# Este script deve ser executado apenas uma vez quando os recursos já existem

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Importando recursos existentes do GCP para o Terraform...${NC}"
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

echo -e "${YELLOW}📋 Tentando importar recursos existentes...${NC}"

# Função para tentar importar um recurso
import_resource() {
    local terraform_resource=$1
    local gcp_resource=$2
    local resource_name=$3
    
    echo -e "${BLUE}Importando ${resource_name}...${NC}"
    
    if terraform import "$terraform_resource" "$gcp_resource" 2>/dev/null; then
        echo -e "${GREEN}✅ ${resource_name} importado com sucesso${NC}"
    else
        echo -e "${YELLOW}⚠️  ${resource_name} não foi importado (pode não existir ou já estar no estado)${NC}"
    fi
}

# Tentar importar Service Account
import_resource \
    "google_service_account.kubernetes" \
    "projects/${PROJECT_ID}/serviceAccounts/listapro-prod-k8s-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
    "Service Account Kubernetes"

# Tentar importar IP Global
import_resource \
    "google_compute_global_address.listapro_prod_ip" \
    "projects/${PROJECT_ID}/global/addresses/listapro-prod-ip" \
    "IP Global"

# Tentar importar VPC
import_resource \
    "google_compute_network.listapro_prod_vpc" \
    "projects/${PROJECT_ID}/global/networks/listapro-prod-vpc" \
    "VPC Network"

# Tentar importar Artifact Registry
import_resource \
    "google_artifact_registry_repository.listapro_prod_repo" \
    "projects/${PROJECT_ID}/locations/us-central1/repositories/listapro-prod-repo" \
    "Artifact Registry"

# Tentar importar Cloud SQL
import_resource \
    "google_sql_database_instance.listapro_prod_db" \
    "projects/${PROJECT_ID}/instances/listapro-prod-db" \
    "Cloud SQL Instance"

# Tentar importar Subnet
import_resource \
    "google_compute_subnetwork.listapro_prod_subnet" \
    "projects/${PROJECT_ID}/regions/us-central1/subnetworks/listapro-prod-subnet" \
    "Subnet"

# Tentar importar Database
import_resource \
    "google_sql_database.listapro_prod_database" \
    "projects/${PROJECT_ID}/instances/listapro-prod-db/databases/listapro" \
    "Database"

# Tentar importar Firewall
import_resource \
    "google_compute_firewall.listapro_prod_firewall" \
    "projects/${PROJECT_ID}/global/firewalls/listapro-prod-firewall" \
    "Firewall Rules"

echo ""
echo -e "${GREEN}🎉 Processo de importação concluído!${NC}"
echo -e "${BLUE}💡 Agora você pode executar 'terraform plan' para ver as mudanças pendentes.${NC}"
echo ""
echo -e "${YELLOW}Próximos passos:${NC}"
echo "1. terraform plan"
echo "2. terraform apply"
echo ""
