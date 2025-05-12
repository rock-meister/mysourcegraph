#!/bin/bash
set -euo pipefail

# Configuration
RESOURCE_GROUP="mysourcegraph-rg"
LOCATION="southcentralus"
INSTANCE_NAME="mysourcegraph-vm"
VM_SIZE="Standard_D8as_v5"  # 8 vCPUs, 32 GB memory (burstable)

# Detect username (will use the same as local user)
AZURE_USERNAME=$(whoami)
echo "🔑 Using username: $AZURE_USERNAME"

# Function to check if a resource exists
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    az $resource_type show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null
}

echo "🚀 Allocating Azure resources for Sourcegraph..."

# Create resource group if it doesn't exist
echo "📦 Setting up resource group..."
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# Create the VM instance
echo "🖥️  Creating Spot VM instance..."
if ! resource_exists "vm" "$INSTANCE_NAME"; then
    # Create VM
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$INSTANCE_NAME" \
        --image Ubuntu2204 \
        --size "$VM_SIZE" \
        --admin-username "$AZURE_USERNAME" \
        --generate-ssh-keys

    # Wait for VM to be ready
    echo "⏳ Waiting for VM to be ready..."
    sleep 30
fi

# Install git and clone the repository on the VM
echo "📦 Installing git and cloning repository on VM..."
REPO_URL="https://github.com/rock-meister/mysourcegraph.git"
DEPLOY_DIR="mysourcegraph"
az vm run-command invoke \
    --resource-group "$RESOURCE_GROUP" \
    --name "$INSTANCE_NAME" \
    --command-id RunShellScript \
    --scripts "sudo apt-get update && sudo apt-get install -y git && rm -rf $DEPLOY_DIR && git clone $REPO_URL $DEPLOY_DIR"

echo "✅ Resource allocation complete!"
echo ""
# Get the dynamic IP address
PUBLIC_IP=$(az vm show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$INSTANCE_NAME" \
    --show-details \
    --query "publicIps" -o tsv)
echo "🌐 Public IP: $PUBLIC_IP"
echo ""
echo "You can now:"
echo "1. SSH into the VM:        ssh $AZURE_USERNAME@$PUBLIC_IP"
echo "2. Run stages manually:    cd ~/sanchaya-sourcegraph && ./01_docker_install.sh"
echo "   or"
echo "3. Use the wrapper:        cd ~/sanchaya-sourcegraph && ./deploy.sh"
