#!/bin/bash
# Script to establish a port-forward tunnel to the database on the Kubernetes cluster
# Usage: ./dbtunnel.sh [optional namespace] [optional port]

# Default values
DEFAULT_NAMESPACE="package-glider"
DEFAULT_SERVICE="pooler-package-glider"
DEFAULT_PORT="5432"

# Parse arguments
NAMESPACE=${1:-$DEFAULT_NAMESPACE}
LOCAL_PORT=${2:-$DEFAULT_PORT}

# Colors for terminal output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check if kubectl is installed
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo "Error: kubectl is not installed"
    echo "Please install it with: brew install kubectl"
    exit 1
  fi
}

# Function to check if we have access to the cluster
check_cluster_access() {
  if ! kubectl get nodes &> /dev/null; then
    echo "Error: Cannot connect to Kubernetes cluster"
    echo "Please ensure your kubeconfig is properly set up and you have access to the cluster"
    exit 1
  fi
}

# Function to start the port-forward tunnel
start_tunnel() {
  echo -e "${GREEN}Starting database tunnel to Kubernetes cluster...${NC}"
  echo -e "Namespace: ${YELLOW}$NAMESPACE${NC}"
  echo -e "Service:   ${YELLOW}$DEFAULT_SERVICE${NC}"
  echo -e "Port:      ${YELLOW}$LOCAL_PORT:$DEFAULT_PORT${NC}"
  echo ""
  echo -e "${GREEN}Database will be accessible at localhost:$LOCAL_PORT${NC}"
  echo -e "${YELLOW}Press Ctrl+C to stop the tunnel${NC}"
  echo "-----------------------------------------------"

  # Start the port-forward
  kubectl port-forward -n $NAMESPACE svc/$DEFAULT_SERVICE $LOCAL_PORT:$DEFAULT_PORT
}

# Main program
check_kubectl
check_cluster_access
start_tunnel
