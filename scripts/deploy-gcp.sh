#!/bin/bash

# GCP Smart Deploy Script - Versão Robusta com Detecção de Recursos
# Detecta recursos existentes e configura deployment automaticamente
# Usa a mesma arquitetura do script DigitalOcean funcionando
#
# Usage: ./deploy-gcp.sh [environment] [project_id]
#   environment: production|staging (default: production)
#   project_id: GCP project ID (default: from GCP_PROJECT_ID env var)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "☁️  GCP Smart Deployment Script"
echo "==============================="
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
if ! command_exists gcloud; then
    echo -e "${RED}❌ gcloud not found. Please install Google Cloud CLI first.${NC}"
    echo "   curl https://sdk.cloud.google.com | bash"
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
    environment=${environment:-production}
fi

if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
    echo -e "${RED}❌ Invalid environment. Choose 'production' or 'staging'${NC}"
    exit 1
fi

# Get project ID from command line or environment
if [ "$2" ]; then
    PROJECT_ID="$2"
    echo -e "${BLUE}📦 Project ID: $PROJECT_ID (from argument)${NC}"
elif [[ -n "$GCP_PROJECT_ID" ]]; then
    PROJECT_ID="$GCP_PROJECT_ID"
    echo -e "${BLUE}📦 Project ID: $PROJECT_ID (from environment)${NC}"
else
    echo -e "${RED}❌ GCP Project ID required. Set GCP_PROJECT_ID or pass as argument${NC}"
    exit 1
fi

# Set environment-specific variables
if [[ "$environment" == "production" ]]; then
    INFRA_DIR="terraform/gcp"
    INFRA_DIR_FULL="$SCRIPT_DIR/../terraform/gcp"
    CLUSTER_NAME="listapro-prod-cluster"
    NETWORK_NAME="listapro-prod-vpc"
    SUBNET_NAME="listapro-prod-subnet"
    REGISTRY_NAME="listapro-prod-repo"
    DB_INSTANCE_NAME="listapro-prod-db"
    DB_NAME="listapro"
    NAMESPACE_NAME="listapro"
    REGION="us-central1"
    ZONE="us-central1-a"
    echo -e "${BLUE}🏭 Production environment selected${NC}"
else
    INFRA_DIR="terraform/gcp-staging"
    INFRA_DIR_FULL="$SCRIPT_DIR/../terraform/gcp-staging" 
    CLUSTER_NAME="listapro-stage-cluster"
    NETWORK_NAME="listapro-stage-vpc"
    SUBNET_NAME="listapro-stage-subnet"
    REGISTRY_NAME="listapro-stage-repo"
    DB_INSTANCE_NAME="listapro-stage-db"
    DB_NAME="listapro"
    NAMESPACE_NAME="listapro"
    REGION="us-central1"
    ZONE="us-central1-a"
    echo -e "${BLUE}🧪 Staging environment selected${NC}"
fi

# Check for GCP credentials
if [[ -z "$GCP_CREDENTIALS" ]]; then
    echo -e "${YELLOW}⚠️  GCP_CREDENTIALS environment variable not found${NC}"
    echo "   Will use current gcloud authentication..."
else
    echo -e "${GREEN}✅ GCP_CREDENTIALS found${NC}"
    # Set up gcloud authentication
    echo "$GCP_CREDENTIALS" | gcloud auth activate-service-account --key-file=-
fi

gcloud config set project "$PROJECT_ID"

echo ""
echo "🔍 Detecting existing GCP resources..."

# Check for existing VPC
echo -n "   📡 Checking VPC '$NETWORK_NAME'... "
if gcloud compute networks describe "$NETWORK_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_VPC=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_VPC=false
fi

# Check for existing subnet
echo -n "   🌐 Checking subnet '$SUBNET_NAME'... "
if gcloud compute networks subnets describe "$SUBNET_NAME" --region="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_SUBNET=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_SUBNET=false
fi

# Check for existing GKE cluster
echo -n "   ⚙️  Checking GKE cluster '$CLUSTER_NAME'... "
if gcloud container clusters describe "$CLUSTER_NAME" --zone="$ZONE" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_CLUSTER=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_CLUSTER=false
fi

# Check for existing Artifact Registry
echo -n "   📦 Checking Artifact Registry '$REGISTRY_NAME'... "
if gcloud artifacts repositories describe "$REGISTRY_NAME" --location="$REGION" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_REGISTRY=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_REGISTRY=false
fi

# Check for existing Cloud SQL instance
echo -n "   🗄️  Checking Cloud SQL instance '$DB_INSTANCE_NAME'... "
if gcloud sql instances describe "$DB_INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_DB=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_DB=false
fi

# Check for existing database
echo -n "   💾 Checking database '$DB_NAME'... "
if [[ "$USE_EXISTING_DB" == "true" ]] && gcloud sql databases describe "$DB_NAME" --instance="$DB_INSTANCE_NAME" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_DATABASE=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_DATABASE=false
fi

# Check for existing service account
SERVICE_ACCOUNT_EMAIL="listapro-${environment}-k8s-sa@${PROJECT_ID}.iam.gserviceaccount.com"
echo -n "   🔑 Checking service account '$SERVICE_ACCOUNT_EMAIL'... "
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" --project="$PROJECT_ID" >/dev/null 2>&1; then
    echo -e "${YELLOW}EXISTS${NC}"
    USE_EXISTING_SERVICE_ACCOUNT=true
else
    echo -e "${GREEN}NOT FOUND (will create)${NC}"
    USE_EXISTING_SERVICE_ACCOUNT=false
fi

echo ""
echo "📊 GCP Resource Detection Summary:"
echo "=================================="
echo -e "VPC Network:        $([ "$USE_EXISTING_VPC" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "Subnet:             $([ "$USE_EXISTING_SUBNET" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "GKE Cluster:        $([ "$USE_EXISTING_CLUSTER" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "Artifact Registry:  $([ "$USE_EXISTING_REGISTRY" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "Cloud SQL Instance: $([ "$USE_EXISTING_DB" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "Database:           $([ "$USE_EXISTING_DATABASE" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"
echo -e "Service Account:    $([ "$USE_EXISTING_SERVICE_ACCOUNT" = true ] && echo "${YELLOW}Use existing${NC}" || echo "${GREEN}Create new${NC}")"

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

# Use the smart GCP scripts if they exist
if [[ -f "$SCRIPT_DIR/smart-deploy-gcp.sh" ]]; then
    echo -e "${BLUE}🚀 Using smart GCP deployment script...${NC}"
    chmod +x "$SCRIPT_DIR/smart-deploy-gcp.sh"
    
    # Set environment variables for the smart script
    export GCP_PROJECT_ID="$PROJECT_ID"
    export SKIP_CONFIRM=1
    
    ./smart-deploy-gcp.sh "$environment"
    
    echo -e "${GREEN}✅ Smart GCP deployment completed!${NC}"
else
    echo -e "${YELLOW}⚠️  Smart GCP script not found, using direct Terraform...${NC}"
    
    # Navigate to infrastructure directory
    if [[ ! -d "$INFRA_DIR_FULL" ]]; then
        echo -e "${RED}❌ Infrastructure directory not found: $INFRA_DIR_FULL${NC}"
        echo "   Please ensure the Terraform configuration exists"
        exit 1
    fi
    
    cd "$INFRA_DIR_FULL"
    
    echo ""
    echo "🚀 Starting GCP Terraform deployment..."
    
    # Initialize Terraform
    echo "📥 Initializing Terraform..."
    terraform init
    
    # Create terraform.tfvars with detected resources
    echo "📝 Creating terraform.tfvars with detected resources..."
    
    cat > terraform.tfvars <<EOF
# GCP Configuration
gcp_credentials = "${GCP_CREDENTIALS:-""}"
project_id = "$PROJECT_ID"
region = "$REGION"
zone = "$ZONE"

# Environment
environment = "$environment"

# Resource Names
cluster_name = "$CLUSTER_NAME"
network_name = "$NETWORK_NAME"
subnet_name = "$SUBNET_NAME"
registry_name = "$REGISTRY_NAME"
db_instance_name = "$DB_INSTANCE_NAME"
db_name = "$DB_NAME"

# Database Configuration
db_password = "${DB_PASSWORD:-defaultpassword123}"

# Resource Existence Flags (auto-detected)
use_existing_vpc = $USE_EXISTING_VPC
use_existing_subnet = $USE_EXISTING_SUBNET
use_existing_cluster = $USE_EXISTING_CLUSTER
use_existing_registry = $USE_EXISTING_REGISTRY
use_existing_db_instance = $USE_EXISTING_DB
use_existing_database = $USE_EXISTING_DATABASE
use_existing_service_account = $USE_EXISTING_SERVICE_ACCOUNT
EOF
    
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
    
    # Apply changes
    echo ""
    if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
        read -p "🚀 Apply these changes? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ Deployment cancelled${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Auto-applying Terraform configuration (non-interactive mode)${NC}"
    fi
    
    echo "✨ Applying Terraform configuration..."
    terraform apply -auto-approve
    
    cd "$SCRIPT_DIR/.."
fi

# Configure kubectl
echo ""
echo "🔧 Configuring kubectl for cluster access..."
if gcloud container clusters get-credentials "$CLUSTER_NAME" --zone="$ZONE" --project="$PROJECT_ID" 2>/dev/null; then
    echo -e "${GREEN}✅ kubectl configured successfully${NC}"
else
    echo -e "${YELLOW}⚠️  Could not configure kubectl automatically${NC}"
    echo "   Run manually: gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID"
fi
    
echo ""
echo -e "${GREEN}✅ GCP deployment completed successfully!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Update GitHub repository secrets with real values"
echo "2. Push code to trigger CI/CD pipeline"
echo "3. Monitor deployment in GitHub Actions"
echo ""
echo "🔗 Useful commands:"
echo "   # Kubernetes access:"
echo "   gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID"
echo "   kubectl get pods -n $NAMESPACE_NAME"
echo "   kubectl get services -n $NAMESPACE_NAME"
echo ""
echo "   # Database access:"
echo "   gcloud sql connect $DB_INSTANCE_NAME --user=postgres --database=$DB_NAME"

if [[ "$USE_EXISTING_CLUSTER" == "false" ]]; then
    echo ""
    echo "🎉 New cluster created! Configure kubectl:"
    echo "   gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --project=$PROJECT_ID"
fi

echo ""
echo -e "${GREEN}🎉 GCP smart deployment script completed!${NC}"
