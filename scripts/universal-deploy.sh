#!/bin/bash

# Universal Multi-Cloud Deployment Script 
# Automatically detects existing resources and configures deployment accordingly
# Based on the proven working DigitalOcean smart-deploy.sh architecture
#
# Usage: ./universal-deploy.sh [cloud] [environment] [additional_args...]
#   cloud: digitalocean|gcp (default: interactive prompt)
#   environment: production|staging (default: interactive prompt)  
#   additional_args: cloud-specific arguments
#
# Environment Variables:
#   DO_TOKEN_PROD, DO_STAGING_TOKEN: DigitalOcean tokens
#   GCP_CREDENTIALS, GCP_PROJECT_ID: GCP credentials and project
#   SKIP_CONFIRM: Skip confirmation prompt (for CI/CD)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌐 Universal Multi-Cloud Deployment System"
echo "=========================================="
echo "🔍 Resource Detection & Smart Deployment"
echo "Adapts to existing infrastructure automatically"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to validate dependencies for each cloud
check_dependencies() {
    local cloud="$1"
    
    echo "📋 Checking dependencies for $cloud..."
    
    # Common dependencies
    if ! command_exists terraform; then
        echo -e "${RED}❌ terraform not found. Please install Terraform first.${NC}"
        exit 1
    fi
    
    # Cloud-specific dependencies
    case "$cloud" in
        "digitalocean")
            if ! command_exists doctl; then
                echo -e "${RED}❌ doctl not found. Please install DigitalOcean CLI first.${NC}"
                echo "   curl -sL https://github.com/digitalocean/doctl/releases/download/v1.100.0/doctl-1.100.0-linux-amd64.tar.gz | tar -xzv"
                exit 1
            fi
            ;;
        "gcp")
            if ! command_exists gcloud; then
                echo -e "${RED}❌ gcloud not found. Please install Google Cloud CLI first.${NC}"
                echo "   curl https://sdk.cloud.google.com | bash"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Unsupported cloud provider: $cloud${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}✅ Dependencies OK for $cloud${NC}"
}

# Function to get cloud provider choice
get_cloud_choice() {
    if [ "$1" ]; then
        echo "$1"
    else
        echo ""
        echo "☁️  Select cloud provider:"
        echo "1) DigitalOcean"
        echo "2) Google Cloud Platform (GCP)"
        echo ""
        read -p "Choose (1-2): " choice
        
        case $choice in
            1) echo "digitalocean" ;;
            2) echo "gcp" ;;
            *) 
                echo -e "${RED}❌ Invalid choice. Please select 1 or 2${NC}"
                exit 1
                ;;
        esac
    fi
}

# Function to get environment choice
get_environment_choice() {
    if [ "$1" ]; then
        echo "$1"
    else
        echo ""
        read -p "🌍 Which environment to deploy? (production/staging): " env
        echo "${env:-staging}"
    fi
}

# DigitalOcean deployment function - delegates to the proven working script
deploy_digitalocean() {
    local environment="$1"
    local terraform_action="$2"
    
    echo -e "${BLUE}🌊 Starting DigitalOcean deployment...${NC}"
    echo -e "${PURPLE}   Environment: $environment${NC}"
    echo -e "${PURPLE}   Action: $terraform_action${NC}"
    
    # Use the new smart deploy script for staging
    if [[ "$environment" == "staging" ]]; then
        if [[ ! -f "$SCRIPT_DIR/smart-deploy-do.sh" ]]; then
            echo -e "${RED}❌ DigitalOcean staging script not found at: $SCRIPT_DIR/smart-deploy-do.sh${NC}"
            exit 1
        fi
        
        # Make script executable and run
        chmod +x "$SCRIPT_DIR/smart-deploy-do.sh"
        
        echo -e "${PURPLE}🚀 Executing DigitalOcean smart deployment for staging...${NC}"
        "$SCRIPT_DIR/smart-deploy-do.sh" "$terraform_action"
        
    else
        # For production, use the proven working script
        echo -e "${PURPLE}   Using proven working smart-deploy.sh script for production${NC}"
        
        # Check if the proven working script exists
        if [[ ! -f "$SCRIPT_DIR/../backupfromoldproject/scripts/smart-deploy.sh" ]]; then
            echo -e "${RED}❌ DigitalOcean smart-deploy script not found at expected location${NC}"
            echo "   Expected: $SCRIPT_DIR/../backupfromoldproject/scripts/smart-deploy.sh"
            exit 1
        fi
        
        # Make script executable
        chmod +x "$SCRIPT_DIR/../backupfromoldproject/scripts/smart-deploy.sh"
        
        # Set environment variables for automatic execution
        export SKIP_CONFIRM=1
        
        # Required environment variables
        if [[ -z "$GITHUB_CLIENT_ID" ]]; then
            echo -e "${YELLOW}⚠️  GITHUB_CLIENT_ID not set${NC}"
        fi
        
        # Execute the proven working script
        echo -e "${PURPLE}🚀 Executing DigitalOcean smart deployment for production...${NC}"
        cd "$SCRIPT_DIR/../backupfromoldproject"
        
        ./scripts/smart-deploy.sh "$environment"
        
        cd "$SCRIPT_DIR/.."
    fi
    
    echo -e "${GREEN}✅ DigitalOcean deployment completed successfully!${NC}"
}

# GCP deployment function - uses the smart scripts we created
deploy_gcp() {
    local environment="$1"
    local project_id="$2"
    
    echo -e "${BLUE}☁️  Starting GCP deployment...${NC}"
    echo -e "${PURPLE}   Using smart detection and conditional Terraform${NC}"
    
    # Set environment-specific variables
    if [[ "$environment" == "production" ]]; then
        INFRA_DIR="terraform/gcp"
        CLUSTER_NAME="listapro-prod-cluster"
        NETWORK_NAME="listapro-prod-vpc"
        SUBNET_NAME="listapro-prod-subnet"
        REGISTRY_NAME="listapro-prod-repo"
        DB_INSTANCE_NAME="listapro-prod-db"
    else
        INFRA_DIR="terraform/gcp-staging"
        CLUSTER_NAME="listapro-stage-cluster"
        NETWORK_NAME="listapro-stage-vpc"
        SUBNET_NAME="listapro-stage-subnet"
        REGISTRY_NAME="listapro-stage-repo"
        DB_INSTANCE_NAME="listapro-stage-db"
    fi
    
    # Check for GCP credentials
    if [[ -z "$GCP_CREDENTIALS" ]]; then
        echo -e "${RED}❌ GCP_CREDENTIALS environment variable not found${NC}"
        exit 1
    fi
    
    if [[ -z "$GCP_PROJECT_ID" ]]; then
        if [[ -z "$project_id" ]]; then
            echo -e "${RED}❌ GCP_PROJECT_ID environment variable or project_id argument required${NC}"
            exit 1
        else
            export GCP_PROJECT_ID="$project_id"
        fi
    fi
    
    # Use the smart GCP deployment script we created
    echo -e "${PURPLE}🔍 Running smart GCP resource detection...${NC}"
    
    if [[ -f "$SCRIPT_DIR/smart-deploy-gcp.sh" ]]; then
        chmod +x "$SCRIPT_DIR/smart-deploy-gcp.sh"
        ./smart-deploy-gcp.sh "$environment"
    else
        echo -e "${YELLOW}⚠️  Smart GCP script not found, falling back to direct Terraform...${NC}"
        
        # Navigate to infrastructure directory
        cd "$SCRIPT_DIR/../$INFRA_DIR"
        
        echo ""
        echo "🚀 Starting GCP Terraform deployment..."
        
        # Initialize Terraform
        echo "📥 Initializing Terraform..."
        terraform init
        
        # Plan deployment
        echo ""
        echo "📋 Planning deployment..."
        terraform plan \
            -var="gcp_credentials=$GCP_CREDENTIALS" \
            -var="project_id=$GCP_PROJECT_ID" \
            -var="db_password=${DB_PASSWORD:-defaultpassword123}" \
            -out=tfplan
        
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
        terraform apply -auto-approve tfplan
        
        cd "$SCRIPT_DIR/.."
    fi
    
    echo -e "${GREEN}✅ GCP deployment completed successfully!${NC}"
}

# Main execution
main() {
    # Get cloud provider choice
    cloud=$(get_cloud_choice "$1")
    echo -e "${BLUE}☁️  Cloud Provider: $cloud${NC}"
    
    # Check dependencies for selected cloud
    check_dependencies "$cloud"
    
    # Get environment choice
    environment=$(get_environment_choice "$2")
    echo -e "${BLUE}🌍 Environment: $environment${NC}"
    
    # Validate environment
    if [[ "$environment" != "production" && "$environment" != "staging" ]]; then
        echo -e "${RED}❌ Invalid environment. Choose 'production' or 'staging'${NC}"
        exit 1
    fi
    
    # Skip confirmation if running non-interactively or if SKIP_CONFIRM is set
    if [[ -t 0 && -z "$SKIP_CONFIRM" ]]; then
        echo ""
        read -p "🤔 Continue with deployment on $cloud ($environment)? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}❌ Deployment cancelled${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}✅ Auto-continuing with deployment (non-interactive mode)${NC}"
    fi
    
    # Execute cloud-specific deployment
    case "$cloud" in
        "digitalocean")
            deploy_digitalocean "$environment" "$3"
            ;;
        "gcp")
            deploy_gcp "$environment" "$3"
            ;;
        *)
            echo -e "${RED}❌ Unsupported cloud provider: $cloud${NC}"
            exit 1
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}🎉 Universal deployment completed successfully!${NC}"
    echo ""
    echo "📋 Summary:"
    echo "   Cloud Provider: $cloud"
    echo "   Environment: $environment"
    echo "   Strategy: Detect existing resources and use/create as needed"
    echo ""
    echo "📋 Next steps:"
    echo "1. Update GitHub repository secrets with real values"
    echo "2. Push code to trigger CI/CD pipeline"
    echo "3. Monitor deployment in GitHub Actions"
    echo ""
    
    # Show cloud-specific next steps
    case "$cloud" in
        "digitalocean")
            echo "🔗 DigitalOcean useful commands:"
            echo "   doctl kubernetes cluster kubeconfig save <cluster-name>"
            echo "   kubectl get pods -n formerr"
            echo "   kubectl get services -n formerr"
            ;;
        "gcp")
            echo "🔗 GCP useful commands:"
            echo "   gcloud container clusters get-credentials <cluster-name> --zone=us-central1-a"
            echo "   kubectl get pods -n listapro"
            echo "   kubectl get services -n listapro"
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
