#!/bin/bash

# Script para deploy no ambiente de Stage (Digital Ocean)
set -e

echo "🚀 Starting deployment to Stage environment (Digital Ocean)"

# Verificar se as variáveis necessárias estão definidas
if [ -z "$DO_TOKEN" ]; then
    echo "❌ Error: DO_TOKEN environment variable is not set"
    exit 1
fi

# Instalar doctl se não estiver instalado
if ! command -v doctl &> /dev/null; then
    echo "📦 Installing doctl..."
    curl -sL https://github.com/digitalocean/doctl/releases/download/v1.94.0/doctl-1.94.0-linux-amd64.tar.gz | tar -xzv
    sudo mv doctl /usr/local/bin
fi

# Autenticar com Digital Ocean
echo "🔐 Authenticating with Digital Ocean..."
doctl auth init --access-token $DO_TOKEN

# Navegar para o diretório do Terraform
cd terraform/digital-ocean

# Inicializar Terraform
echo "🏗️  Initializing Terraform..."
terraform init

# Planejar infraestrutura
echo "📋 Planning infrastructure..."
terraform plan -out=tfplan

# Aplicar infraestrutura
echo "🚧 Applying infrastructure..."
terraform apply -auto-approve tfplan

# Obter nome do cluster
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGISTRY_NAME=$(terraform output -raw registry_name)

echo "📡 Cluster created: $CLUSTER_NAME"
echo "📦 Registry created: $REGISTRY_NAME"

# Configurar kubectl
echo "⚙️  Configuring kubectl..."
doctl kubernetes cluster kubeconfig save --expiry-seconds 600 $CLUSTER_NAME

# Voltar para o diretório raiz
cd ../../

# Build e push da imagem Docker
echo "🐳 Building and pushing Docker image..."
docker build -t registry.digitalocean.com/$REGISTRY_NAME/listapro-frontend:stage .
doctl registry login --expiry-seconds 1200
docker push registry.digitalocean.com/$REGISTRY_NAME/listapro-frontend:stage

# Atualizar deployment com nova imagem
sed -i "s|brunovn7/listapro-frontend:stage|registry.digitalocean.com/$REGISTRY_NAME/listapro-frontend:stage|g" K8s/stage/frontend/frontend-stage-deployment.yml

# Deploy no Kubernetes
echo "☸️  Deploying to Kubernetes..."
kubectl apply -f K8s/stage/namespace-stage.yaml
kubectl apply -f K8s/stage/ -R

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

helm upgrade --install monitoring-stage ./helm/monitoring \
  --namespace monitoring-stage \
  --create-namespace \
  --values ./helm/monitoring/values-stage.yaml \
  --wait

# Verificar deployment
echo "✅ Verifying deployment..."
kubectl rollout status deployment/listapro-frontend-stage -n listapro-stage
kubectl get pods -n listapro-stage
kubectl get services -n listapro-stage

# Aguardar Load Balancer
echo "⏳ Waiting for load balancer to be ready..."
kubectl wait --for=condition=ready pod -l app=listapro-frontend-stage -n listapro-stage --timeout=300s

# Mostrar informações de deployment
echo "🎉 Deployment completed successfully!"
echo ""
echo "=== Application URLs ==="
LB_IP=$(kubectl get service listapro-frontend-stage-service -n listapro-stage -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "Application: http://$LB_IP"

echo ""
echo "=== Monitoring URLs ==="
GRAFANA_IP=$(kubectl get service monitoring-stage-grafana -n monitoring-stage -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
PROMETHEUS_IP=$(kubectl get service monitoring-stage-prometheus-server -n monitoring-stage -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")
echo "Grafana: http://$GRAFANA_IP:3001 (admin/admin123)"
echo "Prometheus: http://$PROMETHEUS_IP:9090"

echo ""
echo "📝 Note: It may take a few minutes for the load balancer IPs to be assigned."
