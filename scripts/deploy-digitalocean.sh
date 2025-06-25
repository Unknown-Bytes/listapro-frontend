#!/bin/bash

# DigitalOcean Smart Deploy Script - Versão Adaptada do Projeto Funcionando
# Detecta recursos existentes e configura deployment automaticamente
# Baseado no smart-deploy.sh que está 100% funcional
#
# Usage: ./deploy-digitalocean.sh [environment] [registry_name]
#   environment: production|staging (default: staging)
#   registry_name: nome do registry (default: auto-detect ou listapro-registry)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌊 DigitalOcean Smart Deployment Script"
echo "======================================="
echo "🔍 Resource Detection & Smart Deployment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
echo "📋 Checking dependencies..."
if ! command_exists doctl; then
    echo -e "${RED}❌ doctl not found. Please install DigitalOcean CLI first.${NC}"
    echo "   curl -sL https://github.com/digitalocean/doctl/releases/download/v1.100.0/doctl-1.100.0-linux-amd64.tar.gz | tar -xzv"
    exit 1
fi

if ! command_exists terraform; then
    echo -e "${RED}❌ terraform not found. Please install Terraform first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Dependencies OK${NC}"

# Get environment choice from command line or prompt
if [ "$1" ]; then
    environment="$1"
    echo -e "${BLUE}🌍 Environment: $environment (from argument)${NC}"
else
    echo ""
    read -p "🌍 Which environment to deploy? (production/staging): " environment
    environment=${environment:-staging}
fi

if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
    echo -e "${RED}❌ Invalid environment. Choose 'production' or 'staging'${NC}"
    exit 1
fi

# Get registry name from command line or use default
if [ "$2" ]; then
    REGISTRY_NAME_ARG="$2"
    echo -e "${BLUE}📦 Registry: $REGISTRY_NAME_ARG (from argument)${NC}"
else
    REGISTRY_NAME_ARG=""
fi

# Set environment-specific variables
if [[ "$environment" == "production" ]]; then
    INFRA_DIR="terraform/digitalocean-production"
    INFRA_DIR_FULL="$SCRIPT_DIR/../terraform/digitalocean-production"
    VPC_NAME="listapro-production-vpc"
    CLUSTER_NAME="listapro-production-cluster"
    LB_NAME="listapro-production-lb"
    TOKEN_VAR="DO_TOKEN_PROD"
    NAMESPACE_NAME="listapro"
    echo -e "${BLUE}🏭 Production environment selected${NC}"
else
    INFRA_DIR="terraform/digitalocean-staging" 
    INFRA_DIR_FULL="$SCRIPT_DIR/../terraform/digitalocean-staging"
    VPC_NAME="listapro-staging-vpc"
    CLUSTER_NAME="listapro-staging-cluster"
    LB_NAME="listapro-staging-lb"
    TOKEN_VAR="DIGITALOCEAN_TOKEN"
    NAMESPACE_NAME="listapro"
    echo -e "${BLUE}🧪 Staging environment selected${NC}"
fi

# Check for DigitalOcean token
if [[ -z "${!TOKEN_VAR}" ]]; then
    if [[ -z "$DO_TOKEN" ]]; then
        echo -e "${RED}❌ DigitalOcean token not found in environment variable ${TOKEN_VAR} or DO_TOKEN${NC}"
        echo "   Please set one of these environment variables before running the script."
        exit 1
    else
        export ${TOKEN_VAR}="$DO_TOKEN"
        export DIGITALOCEAN_TOKEN="$DO_TOKEN"
    fi
else
    export DIGITALOCEAN_TOKEN="${!TOKEN_VAR}"
fi

echo ""
echo "🔍 Detecting existing resources..."

# Check for existing VPC
echo -n "   📡 Checking VPC '$VPC_NAME'... "
if doctl vpcs list --format Name --no-header | grep -q "^${VPC_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_VPC=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_VPC=false
fi

# Check for existing Kubernetes cluster
echo -n "   ⚙️  Checking Kubernetes cluster '$CLUSTER_NAME'... "
if doctl kubernetes cluster list --format Name --no-header | grep -q "^${CLUSTER_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_CLUSTER=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_CLUSTER=false
fi

# Check for existing load balancer
echo -n "   ⚖️  Checking load balancer '$LB_NAME'... "
if doctl compute load-balancer list --format Name --no-header | grep -q "^${LB_NAME}$"; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_LB=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_LB=false
fi

# Check for existing container registry
echo -n "   📦 Checking container registry... "
if doctl registry get >/dev/null 2>&1; then
    EXISTING_REGISTRY_NAME=$(doctl registry get --format Name --no-header)
    echo -e "${YELLOW}EXISTS ($EXISTING_REGISTRY_NAME)${NC}"
    USE_EXISTING_REGISTRY=true
    # Use the existing registry name unless overridden by command line
    if [[ -z "$REGISTRY_NAME_ARG" ]]; then
        REGISTRY_NAME="$EXISTING_REGISTRY_NAME"
    else
        REGISTRY_NAME="$REGISTRY_NAME_ARG"
    fi
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_REGISTRY=false
    # Use provided registry name or default
    REGISTRY_NAME=${REGISTRY_NAME_ARG:-"listapro-registry"}
fi

# Check for existing Kubernetes namespace (if cluster is accessible)
echo -n "   📁 Checking namespace '$NAMESPACE_NAME'... "
if doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" >/dev/null 2>&1 && kubectl get namespace "$NAMESPACE_NAME" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_NAMESPACE=true
    
    # Check for existing secrets in the namespace
    echo -n "   🔐 Checking database secret... "
    if kubectl get secret listapro-db-secret -n "$NAMESPACE_NAME" >/dev/null 2>&1; then
        echo -e "${YELLOW}EXISTS${NC}"
        USE_EXISTING_DB_SECRET=true
    else
        echo -e "${GREEN}NOT FOUND (will create)${NC}"
        USE_EXISTING_DB_SECRET=false
    fi
    
    echo -n "   🐳 Checking registry secret... "
    if kubectl get secret listapro-registry-secret -n "$NAMESPACE_NAME" >/dev/null 2>&1; then
        echo -e "${YELLOW}EXISTS${NC}"
        USE_EXISTING_REGISTRY_SECRET=true
    else
        echo -e "${GREEN}NOT FOUND (will create)${NC}"
        USE_EXISTING_REGISTRY_SECRET=false
    fi
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_NAMESPACE=false
    USE_EXISTING_DB_SECRET=false
    USE_EXISTING_REGISTRY_SECRET=false
fi

echo ""
echo "📊 Resource Detection Summary:"
echo "=============================="
if [ "$USE_EXISTING_VPC" = true ]; then
    echo -e "VPC:                ${YELLOW}Use existing${NC}"
else
    echo -e "VPC:                ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_CLUSTER" = true ]; then
    echo -e "Kubernetes Cluster: ${YELLOW}Use existing${NC}"
else
    echo -e "Kubernetes Cluster: ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_LB" = true ]; then
    echo -e "Load Balancer:      ${YELLOW}Use existing${NC}"
else
    echo -e "Load Balancer:      ${GREEN}Create new${NC}"
fi

if [ "$USE_EXISTING_REGISTRY" = true ]; then
    echo -e "Container Registry: ${YELLOW}Use existing ($REGISTRY_NAME)${NC}"
else
    echo -e "Container Registry: ${GREEN}Create new ($REGISTRY_NAME)${NC}"
fi

if [ "$USE_EXISTING_NAMESPACE" = true ]; then
    echo -e "Kubernetes Namespace: ${YELLOW}Use existing ($NAMESPACE_NAME)${NC}"
else
    echo -e "Kubernetes Namespace: ${GREEN}Create new ($NAMESPACE_NAME)${NC}"
fi

echo ""
# Skip confirmation if running non-interactively or if SKIP_CONFIRM is set
if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
    read -p "🤔 Continue with this configuration? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Auto-continuing with configuration (non-interactive mode)${NC}"
fi

# Check if infrastructure directory exists
if [[ ! -d "$INFRA_DIR_FULL" ]]; then
    echo -e "${YELLOW}⚠️  Infrastructure directory not found: $INFRA_DIR_FULL${NC}"
    echo "   Creating directory structure..."
    mkdir -p "$INFRA_DIR_FULL"
    
    # Create basic Terraform files for DigitalOcean
    echo "📝 Creating basic DigitalOcean Terraform configuration..."
    
    cat > "$INFRA_DIR_FULL/main.tf" <<EOF
terraform {
  required_version = ">= 1.0"
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = var.do_token
}

# VPC
resource "digitalocean_vpc" "listapro_vpc" {
  count    = var.use_existing_vpc ? 0 : 1
  name     = var.vpc_name
  region   = var.region
  ip_range = "10.1.0.0/16"
}

# Data source for existing VPC
data "digitalocean_vpc" "existing_vpc" {
  count = var.use_existing_vpc ? 1 : 0
  name  = var.vpc_name
}

locals {
  vpc_id = var.use_existing_vpc ? data.digitalocean_vpc.existing_vpc[0].id : digitalocean_vpc.listapro_vpc[0].id
}

# Kubernetes cluster
resource "digitalocean_kubernetes_cluster" "listapro_cluster" {
  count    = var.use_existing_cluster ? 0 : 1
  name     = var.cluster_name
  region   = var.region
  version  = var.k8s_version
  vpc_uuid = local.vpc_id

  node_pool {
    name       = "worker-pool"
    size       = var.node_size
    node_count = var.node_count
    tags       = [var.environment, "listapro", "worker"]
  }

  tags = [var.environment, "listapro", "k8s"]
}

# Container registry
resource "digitalocean_container_registry" "listapro_registry" {
  count                  = var.create_registry ? 1 : 0
  name                   = var.registry_name
  subscription_tier_slug = "basic"
}

# Load balancer
resource "digitalocean_loadbalancer" "listapro_lb" {
  count    = var.use_existing_loadbalancer ? 0 : 1
  name     = var.loadbalancer_name
  region   = var.region
  vpc_uuid = local.vpc_id

  forwarding_rule {
    entry_protocol  = "http"
    entry_port      = 80
    target_protocol = "http"
    target_port     = 80
  }

  forwarding_rule {
    entry_protocol  = "https"
    entry_port      = 443
    target_protocol = "https"
    target_port     = 443
    tls_passthrough = true
  }

  healthcheck {
    protocol                 = "http"
    port                     = 80
    path                     = "/health"
    check_interval_seconds   = 10
    response_timeout_seconds = 5
    healthy_threshold        = 3
    unhealthy_threshold      = 3
  }
}
EOF

    cat > "$INFRA_DIR_FULL/variables.tf" <<EOF
variable "do_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc1"
}

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.33.1-do.0"
}

variable "node_count" {
  description = "Number of nodes in the cluster"
  type        = number
  default     = 2
}

variable "node_size" {
  description = "Size of the nodes"
  type        = string
  default     = "s-2vcpu-2gb"
}

variable "environment" {
  description = "Environment name"
  type        = string
}

# Resource names
variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "cluster_name" {
  description = "Kubernetes cluster name"
  type        = string
}

variable "loadbalancer_name" {
  description = "Load balancer name"
  type        = string
}

variable "registry_name" {
  description = "Container registry name"
  type        = string
}

variable "namespace_name" {
  description = "Kubernetes namespace name"
  type        = string
  default     = "listapro"
}

# Resource existence flags
variable "use_existing_vpc" {
  description = "Use existing VPC"
  type        = bool
  default     = false
}

variable "use_existing_cluster" {
  description = "Use existing cluster"
  type        = bool
  default     = false
}

variable "use_existing_loadbalancer" {
  description = "Use existing load balancer"
  type        = bool
  default     = false
}

variable "use_existing_namespace" {
  description = "Use existing namespace"
  type        = bool
  default     = false
}

variable "use_existing_db_secret" {
  description = "Use existing database secret"
  type        = bool
  default     = false
}

variable "use_existing_registry_secret" {
  description = "Use existing registry secret"
  type        = bool
  default     = false
}

variable "create_registry" {
  description = "Create new registry"
  type        = bool
  default     = true
}
EOF

    cat > "$INFRA_DIR_FULL/outputs.tf" <<EOF
output "cluster_name" {
  description = "Name of the Kubernetes cluster"
  value       = var.use_existing_cluster ? var.cluster_name : digitalocean_kubernetes_cluster.listapro_cluster[0].name
}

output "registry_endpoint" {
  description = "Container registry endpoint"
  value       = var.create_registry ? digitalocean_container_registry.listapro_registry[0].endpoint : null
}

output "vpc_id" {
  description = "VPC ID"
  value       = local.vpc_id
}

output "loadbalancer_ip" {
  description = "Load balancer IP"
  value       = var.use_existing_loadbalancer ? null : digitalocean_loadbalancer.listapro_lb[0].ip
}
EOF

    echo -e "${GREEN}✅ Basic Terraform configuration created${NC}"
fi

# Navigate to infrastructure directory
cd "$INFRA_DIR_FULL"

echo ""
echo "🚀 Starting smart Terraform deployment..."

# Initialize Terraform
echo "📥 Initializing Terraform..."
terraform init

# Create auto-generated terraform.tfvars file
echo "📝 Creating terraform.tfvars with detected resources..."

cat > terraform.tfvars <<EOF
# DigitalOcean Configuration
do_token = "${!TOKEN_VAR}"
region = "nyc1"

# Kubernetes Configuration
k8s_version = "1.33.1-do.0"
node_count = $([[ "$environment" == "production" ]] && echo "3" || echo "2")
node_size = "$([[ "$environment" == "production" ]] && echo "s-4vcpu-8gb" || echo "s-2vcpu-2gb")"
environment = "$environment"

# Resource Names
vpc_name = "$VPC_NAME"
cluster_name = "$CLUSTER_NAME"
loadbalancer_name = "$LB_NAME"
registry_name = "$REGISTRY_NAME"
namespace_name = "$NAMESPACE_NAME"

# Resource Existence Flags (auto-detected)
use_existing_vpc = $USE_EXISTING_VPC
use_existing_cluster = $USE_EXISTING_CLUSTER
use_existing_loadbalancer = $USE_EXISTING_LB
use_existing_namespace = $USE_EXISTING_NAMESPACE
use_existing_db_secret = $USE_EXISTING_DB_SECRET
use_existing_registry_secret = $USE_EXISTING_REGISTRY_SECRET
create_registry = $([[ "$USE_EXISTING_REGISTRY" == "true" ]] && echo "false" || echo "true")
EOF

echo ""
echo "⚠️  terraform.tfvars created with auto-detected settings"

# Plan deployment
echo ""
echo "📋 Planning deployment..."
if ! terraform plan -detailed-exitcode; then
    PLAN_EXIT_CODE=$?
    if [ $PLAN_EXIT_CODE -eq 1 ]; then
        echo -e "${RED}❌ Terraform plan failed${NC}"
        exit 1
    elif [ $PLAN_EXIT_CODE -eq 2 ]; then
        echo -e "${YELLOW}⚠️  Changes detected in plan${NC}"
    fi
fi

# Apply changes (skip confirmation in non-interactive mode)
echo ""
if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
    read -p "🚀 Apply these changes? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}❌ Deployment cancelled${NC}"
        exit 1
    fi
    
    echo "✨ Applying Terraform configuration..."
    terraform apply -auto-approve
else
    echo -e "${GREEN}✨ Auto-applying Terraform configuration (non-interactive mode)${NC}"
    terraform apply -auto-approve
fi

# Configure kubectl
echo ""
echo "🔧 Configuring kubectl for cluster access..."
if doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME" 2>/dev/null; then
    echo -e "${GREEN}✅ kubectl configured successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Could not configure kubectl automatically${NC}"
    echo "   Run manually: doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
fi

cd "$SCRIPT_DIR/.."
    
echo ""
echo -e "${GREEN}✅ DigitalOcean deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Update GitHub repository secrets with real values"
echo "2. Push code to trigger CI/CD pipeline"  
echo "3. Monitor deployment in GitHub Actions"
echo ""
echo "🔗 Useful commands:"
echo "   # Kubernetes access:"
echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
echo "   kubectl get pods -n $NAMESPACE_NAME"
echo "   kubectl get services -n $NAMESPACE_NAME"

if [[ "$USE_EXISTING_CLUSTER" == "false" ]]; then
    echo ""
    echo "🎉 New cluster created! Configure kubectl:"
    echo "   doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
fi

echo ""
echo -e "${GREEN}🎉 DigitalOcean smart deployment script completed!${NC}"
