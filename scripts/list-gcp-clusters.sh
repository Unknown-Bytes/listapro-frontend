#!/bin/bash

# Script para listar clusters GCP disponíveis no projeto
# Use este script para identificar o nome correto do cluster de produção

set -e

echo "🔍 Buscando clusters GCP no projeto..."
echo "=================================="

# Verificar se gcloud está instalado
if ! command -v gcloud &> /dev/null; then
    echo "❌ gcloud CLI não encontrado. Instale o Google Cloud SDK primeiro."
    exit 1
fi

# Verificar se está autenticado
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n 1 >/dev/null; then
    echo "❌ Não está autenticado no gcloud. Execute 'gcloud auth login' primeiro."
    exit 1
fi

# Obter projeto atual
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -z "$PROJECT_ID" ]; then
    echo "❌ Projeto GCP não configurado. Execute 'gcloud config set project PROJECT_ID' primeiro."
    exit 1
fi

echo "📍 Projeto: $PROJECT_ID"
echo ""

# Listar todos os clusters em todas as regiões
echo "🚢 Clusters disponíveis:"
echo "----------------------"

CLUSTERS=$(gcloud container clusters list --format="value(name,location,status)" 2>/dev/null)

if [ -z "$CLUSTERS" ]; then
    echo "❌ Nenhum cluster encontrado no projeto $PROJECT_ID"
    echo ""
    echo "💡 Sugestões:"
    echo "1. Verifique se você está no projeto correto"
    echo "2. Execute a pipeline de infraestrutura manual primeiro"
    echo "3. Verifique se tem permissões para listar clusters"
    exit 1
fi

echo "$CLUSTERS" | while IFS=$'\t' read -r name location status; do
    echo "  📦 Nome: $name"
    echo "     📍 Localização: $location"
    echo "     🟢 Status: $status"
    echo ""
done

echo "🔧 Para usar um cluster específico, configure os secrets no GitHub:"
echo "   GKE_CLUSTER_NAME: nome-do-cluster"
echo "   GCP_PROJECT_ID: $PROJECT_ID"
echo ""
echo "📋 Comando para testar conexão com um cluster:"
echo "   gcloud container clusters get-credentials NOME_DO_CLUSTER --zone=ZONA --project=$PROJECT_ID"
