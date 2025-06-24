#!/bin/bash

# Script para deploy no ambiente de Produção (GCP)
set -e

echo "🚀 Starting deployment to Production environment (GCP)"

# Verificar se as variáveis necessárias estão definidas
if [ -z "$GCP_PROJECT_ID" ]; then
    echo "❌ Error: GCP_PROJECT_ID environment variable is not set"
    exit 1
fi

if [ -z "$GCP_CREDENTIALS" ]; then
    echo "❌ Error: GCP_CREDENTIALS environment variable is not set"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    echo "❌ Error: DB_PASSWORD environment variable is not set"
    exit 1
fi

# Instalar gcloud CLI se não estiver instalado
if ! command -v gcloud &> /dev/null; then
    echo "📦 Installing Google Cloud CLI..."
    curl https://sdk.cloud.google.com | bash
    exec -l $SHELL
    gcloud init
fi

# Configurar autenticação
echo "🔐 Authenticating with Google Cloud..."
echo "$GCP_CREDENTIALS" > /tmp/gcp-key.json
gcloud auth activate-service-account --key-file=/tmp/gcp-key.json
gcloud config set project $GCP_PROJECT_ID

# Navegar para o diretório do Terraform
cd terraform/gcp

# Inicializar Terraform
echo "🏗️  Initializing Terraform..."
terraform init

# Planejar infraestrutura
echo "📋 Planning infrastructure..."
export TF_VAR_gcp_credentials="$GCP_CREDENTIALS"
export TF_VAR_project_id="$GCP_PROJECT_ID"
export TF_VAR_db_password="$DB_PASSWORD"
terraform plan -out=tfplan

# Aplicar infraestrutura
echo "🚧 Applying infrastructure..."
terraform apply -auto-approve tfplan

# Obter informações do cluster
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw region)
ARTIFACT_REGISTRY_URL=$(terraform output -raw artifact_registry_url)

echo "📡 Cluster created: $CLUSTER_NAME"
echo "📦 Artifact Registry: $ARTIFACT_REGISTRY_URL"

# Configurar kubectl
echo "⚙️  Configuring kubectl..."
gcloud container clusters get-credentials $CLUSTER_NAME --zone=${REGION}-a --project=$GCP_PROJECT_ID

# Voltar para o diretório raiz
cd ../../

# Configurar Docker para usar gcloud como credential helper
echo "🐳 Configuring Docker authentication..."
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# Build e push da imagem Docker
echo "🐳 Building and pushing Docker image..."
docker build -t ${ARTIFACT_REGISTRY_URL}/listapro-frontend:prod .
docker push ${ARTIFACT_REGISTRY_URL}/listapro-frontend:prod

# Atualizar deployment com nova imagem
sed -i "s|brunovn7/listapro-frontend:latest|${ARTIFACT_REGISTRY_URL}/listapro-frontend:prod|g" K8s/prod/frontend/frontend-prod-deployment.yml

# Deploy no Kubernetes
echo "☸️  Deploying to Kubernetes..."
kubectl apply -f K8s/prod/namespace-prod.yaml
kubectl apply -f K8s/prod/ -R

# Instalar Helm se não estiver instalado
if ! command -v helm &> /dev/null; then
    echo "📦 Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Deploy do stack de monitoramento
echo "📊 Deploying monitoring stack..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

helm upgrade --install monitoring-prod ./helm/monitoring \
  --namespace monitoring-prod \
  --create-namespace \
  --values ./helm/monitoring/values-production.yaml \
  --wait

# Verificar deployment
echo "✅ Verifying deployment..."
kubectl rollout status deployment/listapro-frontend-prod -n listapro-prod
kubectl get pods -n listapro-prod
kubectl get services -n listapro-prod

# Aguardar Load Balancer
echo "⏳ Waiting for load balancer to be ready..."
kubectl wait --for=condition=ready pod -l app=listapro-frontend-prod -n listapro-prod --timeout=300s

# Mostrar informações de deployment
echo "🎉 Deployment completed successfully!"
echo ""
echo "=== Application URLs ==="
LB_IP=$(kubectl get service listapro-frontend-prod-service -n listapro-prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "Application: http://$LB_IP"

echo ""
echo "=== Monitoring URLs ==="
GRAFANA_IP=$(kubectl get service monitoring-prod-grafana -n monitoring-prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
PROMETHEUS_IP=$(kubectl get service monitoring-prod-prometheus-server -n monitoring-prod -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "Grafana: http://$GRAFANA_IP:3001 (admin/admin123)"
echo "Prometheus: http://$PROMETHEUS_IP:9090"

# Executar verificações de saúde
echo ""
echo "🏥 Running health checks..."
sleep 60

if curl -f http://$LB_IP/api/health; then
    echo "✅ Application health check passed"
else
    echo "❌ Application health check failed"
    exit 1
fi

# Limpar credenciais temporárias
rm -f /tmp/gcp-key.json

echo ""
echo "📝 Note: It may take a few minutes for the load balancer IPs to be assigned."
