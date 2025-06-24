#!/bin/bash

# Script de verificação rápida da configuração Terraform GCP
# Testa se a configuração com data sources está funcionando

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificação Rápida - Terraform GCP${NC}"
echo "=================================================="

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

echo -e "${BLUE}📋 Project ID: ${TF_VAR_project_id}${NC}"

# Inicializar Terraform se necessário
if [ ! -d ".terraform" ]; then
    echo -e "${BLUE}🔧 Inicializando Terraform...${NC}"
    terraform init
fi

# Validar configuração
echo -e "${BLUE}✅ Validando configuração Terraform...${NC}"
if terraform validate; then
    echo -e "${GREEN}✅ Configuração Terraform válida!${NC}"
else
    echo -e "${RED}❌ Erro na configuração Terraform${NC}"
    exit 1
fi

# Fazer o plan
echo ""
echo -e "${BLUE}📋 Executando terraform plan...${NC}"
if terraform plan -out=tfplan-test; then
    echo -e "${GREEN}✅ Plan executado com sucesso!${NC}"
    
    # Verificar se há recursos para criar
    PLAN_OUTPUT=$(terraform show -no-color tfplan-test)
    
    if echo "$PLAN_OUTPUT" | grep -q "No changes"; then
        echo -e "${GREEN}🎉 Perfeito! Nenhuma mudança necessária.${NC}"
        echo -e "${GREEN}Todos os recursos já existem e estão sendo referenciados corretamente.${NC}"
    elif echo "$PLAN_OUTPUT" | grep -q "Plan:"; then
        echo ""
        echo -e "${BLUE}📊 Resumo das mudanças:${NC}"
        echo "$PLAN_OUTPUT" | grep -A 5 "Plan:"
        echo ""
        echo -e "${YELLOW}💡 Há recursos para criar/modificar. Execute apply quando estiver pronto.${NC}"
    fi
    
    # Limpar arquivo de plan de teste
    rm -f tfplan-test
    
else
    echo -e "${RED}❌ Erro no terraform plan${NC}"
    echo ""
    echo -e "${YELLOW}💡 Possíveis soluções:${NC}"
    echo "1. Execute: ./scripts/smart-deploy-gcp.sh"
    echo "2. Verifique se todas as variáveis de ambiente estão definidas"
    echo "3. Verifique se você tem permissões no projeto GCP"
    
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Verificação concluída com sucesso!${NC}"
echo -e "${BLUE}💡 A configuração está funcionando corretamente.${NC}"
