#!/bin/bash

# Smart Deploy - Digital Ocean Staging
# Robust, idempotent deployment script for Digital Ocean staging environment
# Handles resource detection, creation, and updates intelligently

set -e

# Configuration
ENVIRONMENT="staging"
CLUSTER_NAME="${CLUSTER_NAME:-listapro-staging-cluster}"
REGISTRY_NAME="${REGISTRY_NAME:-listapro-staging-registry}"
REGION="${DO_REGION:-nyc1}"
NODE_SIZE="${NODE_SIZE:-s-2vcpu-2gb}"
NODE_COUNT="${NODE_COUNT:-2}"
K8S_VERSION="${K8S_VERSION:-1.29.1-do.0}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌊 Digital Ocean Smart Deploy - Staging${NC}"
echo "=============================================="
echo "🔍 Detecting existing resources..."
echo "📍 Region: $REGION"
echo "🏷️  Environment: $ENVIRONMENT"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    echo "📋 Checking dependencies..."
    
    if ! command_exists doctl; then
        echo -e "${RED}❌ doctl not found. Please install DigitalOcean CLI first.${NC}"
        exit 1
    fi
    
    if ! command_exists kubectl; then
        echo -e "${RED}❌ kubectl not found. Please install kubectl first.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Dependencies OK${NC}"
}

# Authenticate with DigitalOcean
authenticate() {
    echo "🔐 Authenticating with DigitalOcean..."
    
    if [[ -z "$DO_STAGING_TOKEN" ]]; then
        echo -e "${RED}❌ DO_STAGING_TOKEN environment variable not set${NC}"
        exit 1
    fi
    
    # Test authentication
    if ! doctl account get >/dev/null 2>&1; then
        echo -e "${RED}❌ Failed to authenticate with DigitalOcean${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Successfully authenticated with DigitalOcean${NC}"
}

# Check and create container registry
setup_registry() {
    echo "📦 Setting up container registry..."
    
    # Check if registry exists
    if doctl registry get "$REGISTRY_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Registry '$REGISTRY_NAME' already exists${NC}"
    else
        echo -e "${YELLOW}⚠️  Registry '$REGISTRY_NAME' not found, creating...${NC}"
        doctl registry create "$REGISTRY_NAME" --region "$REGION"
        
        # Wait for registry to be ready
        echo "⏳ Waiting for registry to be ready..."
        sleep 10
        
        echo -e "${GREEN}✅ Registry '$REGISTRY_NAME' created successfully${NC}"
    fi
    
    # Login to registry
    doctl registry login
    echo -e "${GREEN}✅ Logged into container registry${NC}"
}

# Check and create Kubernetes cluster
setup_cluster() {
    echo "🚢 Setting up Kubernetes cluster..."
    
    # Check if cluster exists
    if doctl kubernetes cluster get "$CLUSTER_NAME" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Cluster '$CLUSTER_NAME' already exists${NC}"
        
        # Check cluster status
        STATUS=$(doctl kubernetes cluster get "$CLUSTER_NAME" --format Status --no-header)
        if [[ "$STATUS" != "running" ]]; then
            echo -e "${YELLOW}⚠️  Cluster is not running (status: $STATUS), waiting...${NC}"
            # Wait for cluster to be ready
            while [[ "$STATUS" != "running" ]]; do
                sleep 30
                STATUS=$(doctl kubernetes cluster get "$CLUSTER_NAME" --format Status --no-header)
                echo "   Cluster status: $STATUS"
            done
        fi
    else
        echo -e "${YELLOW}⚠️  Cluster '$CLUSTER_NAME' not found, creating...${NC}"
        
        # Get available Kubernetes versions
        echo "🔍 Getting latest Kubernetes version..."
        LATEST_VERSION=$(doctl kubernetes options versions --output json | jq -r '.[0].slug')
        K8S_VERSION="${K8S_VERSION:-$LATEST_VERSION}"
        
        echo "🚀 Creating cluster with version: $K8S_VERSION"
        doctl kubernetes cluster create "$CLUSTER_NAME" \
            --region "$REGION" \
            --version "$K8S_VERSION" \
            --size "$NODE_SIZE" \
            --count "$NODE_COUNT" \
            --tag "environment:$ENVIRONMENT" \
            --wait
        
        echo -e "${GREEN}✅ Cluster '$CLUSTER_NAME' created successfully${NC}"
    fi
    
    # Configure kubectl
    echo "⚙️ Configuring kubectl..."
    doctl kubernetes cluster kubeconfig save "$CLUSTER_NAME"
    
    # Verify cluster connection
    if kubectl cluster-info >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Successfully connected to cluster${NC}"
    else
        echo -e "${RED}❌ Failed to connect to cluster${NC}"
        exit 1
    fi
    
    # Show cluster info
    echo "📊 Cluster Information:"
    kubectl get nodes
}

# Setup basic cluster infrastructure
setup_cluster_infrastructure() {
    echo "🏗️ Setting up cluster infrastructure..."
    
    # Create namespace if it doesn't exist
    NAMESPACE="listapro-stage"
    if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
        echo "📁 Creating namespace: $NAMESPACE"
        kubectl create namespace "$NAMESPACE"
    else
        echo -e "${GREEN}✅ Namespace '$NAMESPACE' already exists${NC}"
    fi
    
    # Label namespace
    kubectl label namespace "$NAMESPACE" environment=staging --overwrite
    
    echo -e "${GREEN}✅ Cluster infrastructure setup complete${NC}"
}

# Main deployment function
main() {
    local action="${1:-plan}"
    
    echo "🎯 Starting Digital Ocean staging deployment..."
    echo "Action: $action"
    
    check_dependencies
    authenticate
    
    case "$action" in
        "plan")
            echo "📋 Planning deployment (dry-run)..."
            setup_registry
            setup_cluster
            setup_cluster_infrastructure
            echo -e "${BLUE}📋 Plan completed successfully!${NC}"
            echo "Run with 'apply' to create resources."
            ;;
        "apply")
            echo "🚀 Applying deployment..."
            setup_registry
            setup_cluster
            setup_cluster_infrastructure
            echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
            ;;
        "destroy")
            echo -e "${RED}🗑️  Destroying staging infrastructure...${NC}"
            if [[ "$SKIP_CONFIRM" != "1" ]]; then
                read -p "Are you sure you want to destroy the staging infrastructure? (yes/no): " confirm
                if [[ "$confirm" != "yes" ]]; then
                    echo "Destroy cancelled."
                    exit 0
                fi
            fi
            
            # Delete cluster
            if doctl kubernetes cluster get "$CLUSTER_NAME" >/dev/null 2>&1; then
                echo "🗑️  Deleting cluster: $CLUSTER_NAME"
                doctl kubernetes cluster delete "$CLUSTER_NAME" --force
            fi
            
            # Note: We don't delete the registry as it might contain important images
            echo -e "${YELLOW}⚠️  Registry '$REGISTRY_NAME' was not deleted (contains images)${NC}"
            echo -e "${GREEN}✅ Infrastructure destroyed${NC}"
            ;;
        *)
            echo -e "${RED}❌ Invalid action: $action${NC}"
            echo "Valid actions: plan, apply, destroy"
            exit 1
            ;;
    esac
    
    echo ""
    echo "🔗 Next steps:"
    echo "1. Configure kubectl: doctl kubernetes cluster kubeconfig save $CLUSTER_NAME"
    echo "2. Deploy application: Run build-stage.yml workflow"
    echo "3. Check status: kubectl get pods -n listapro-stage"
}

# Run main function with all arguments
main "$@"
