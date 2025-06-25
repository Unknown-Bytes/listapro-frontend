#!/bin/bash

# Universal Multi-Cloud Deployment Script 
# Delegates to specific cloud deployment scripts
#
# Usage: ./universal-deploy.sh [cloud] [environment] [action]
#   cloud: digitalocean|gcp (default: interactive prompt)
#   environment: production|staging (default: interactive prompt)  
#   action: plan|apply|destroy (default: apply)
#
# This script delegates to:
#   - smart-deploy-do.sh for DigitalOcean deployments
#   - smart-deploy-gcp.sh for GCP deployments

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌐 Universal Multi-Cloud Deployment System"
echo "=========================================="
echo "🔍 Delegates to specialized cloud scripts"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Get cloud choice from command line or prompt
if [ "$1" ]; then
    cloud="$1"
    echo -e "${BLUE}☁️ Cloud: $cloud (from argument)${NC}"
else
    echo ""
    echo "☁️ Select cloud provider:"
    echo "1) DigitalOcean"
    echo "2) Google Cloud Platform (GCP)"
    read -p "Choose (1-2): " choice
    
    case $choice in
        1) cloud="digitalocean" ;;
        2) cloud="gcp" ;;
        *) echo -e "${RED}❌ Invalid choice${NC}"; exit 1 ;;
    esac
fi

if [[ "$cloud" != "digitalocean" && "$cloud" != "gcp" ]]; then
    echo -e "${RED}❌ Invalid cloud. Choose 'digitalocean' or 'gcp'${NC}"
    exit 1
fi

# Get environment choice from command line or prompt
if [ "$2" ]; then
    environment="$2"
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

# Get action choice from command line or prompt
if [ "$3" ]; then
    action="$3"
    echo -e "${BLUE}🎯 Action: $action (from argument)${NC}"
else
    action="apply"
    echo -e "${BLUE}🎯 Action: $action (default)${NC}"
fi

echo ""
echo "📋 Deployment Configuration:"
echo "============================"
echo -e "Cloud:       ${PURPLE}$cloud${NC}"
echo -e "Environment: ${PURPLE}$environment${NC}"
echo -e "Action:      ${PURPLE}$action${NC}"
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

echo ""
echo "🚀 Delegating to specialized deployment script..."

# Delegate to specific cloud script
case $cloud in
    "digitalocean")
        echo -e "${BLUE}🌊 Delegating to DigitalOcean deployment script...${NC}"
        
        # Check if script exists
        if [ ! -f "$SCRIPT_DIR/smart-deploy-do.sh" ]; then
            echo -e "${RED}❌ DigitalOcean deployment script not found: $SCRIPT_DIR/smart-deploy-do.sh${NC}"
            exit 1
        fi
        
        # Make executable and run
        chmod +x "$SCRIPT_DIR/smart-deploy-do.sh"
        export ACTION="$action"
        "$SCRIPT_DIR/smart-deploy-do.sh" "$environment" "${@:4}"
        ;;
        
    "gcp")
        echo -e "${BLUE}☁️ Delegating to GCP deployment script...${NC}"
        
        # Check if script exists
        if [ ! -f "$SCRIPT_DIR/smart-deploy-gcp.sh" ]; then
            echo -e "${RED}❌ GCP deployment script not found: $SCRIPT_DIR/smart-deploy-gcp.sh${NC}"
            exit 1
        fi
        
        # Make executable and run
        chmod +x "$SCRIPT_DIR/smart-deploy-gcp.sh"
        export ACTION="$action"
        "$SCRIPT_DIR/smart-deploy-gcp.sh" "$environment" "${@:4}"
        ;;
        
    *)
        echo -e "${RED}❌ Unsupported cloud: $cloud${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Universal deployment completed!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Check the specific cloud script output above"
echo "2. Run application deployment if infrastructure was successful"
echo "3. Monitor the deployment in the respective cloud console"
