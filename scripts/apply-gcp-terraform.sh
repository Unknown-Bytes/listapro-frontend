#!/bin/bash

# Script para aplicar o Terraform no GCP lidando com recursos existentes
# Este script usa data sources para recursos que já existem

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Aplicando Terraform no GCP (com recursos existentes)...${NC}"
echo "============================================================="

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

if [ -z "$TF_VAR_gcp_credentials" ]; then
    echo -e "${YELLOW}⚠️  TF_VAR_gcp_credentials não definida. Por favor, defina:${NC}"
    echo "export TF_VAR_gcp_credentials='{\"sua\":\"chave\"}'"
    exit 1
fi

echo -e "${BLUE}📋 Verificando configuração...${NC}"
echo "Project ID: $TF_VAR_project_id"
echo ""

# Inicializar Terraform se necessário
if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}🔧 Inicializando Terraform...${NC}"
    terraform init
fi

# Fazer o plan
echo -e "${BLUE}📋 Executando terraform plan...${NC}"
if terraform plan -out=tfplan; then
    echo -e "${GREEN}✅ Plan executado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro no terraform plan${NC}"
    exit 1
fi

# Perguntar se deve aplicar
echo ""
echo -e "${YELLOW}❓ Deseja aplicar as mudanças? (y/N)${NC}"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo -e "${BLUE}🚀 Aplicando mudanças...${NC}"
    if terraform apply tfplan; then
        echo -e "${GREEN}🎉 Terraform aplicado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Erro ao aplicar terraform${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}⏸️  Aplicação cancelada pelo usuário${NC}"
fi

echo ""
echo -e "${GREEN}✅ Processo concluído!${NC}"
