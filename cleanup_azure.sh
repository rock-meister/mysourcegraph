#!/bin/bash
set -euo pipefail

# Configuration - must match the values in 00_allocate_azure.sh
RESOURCE_GROUP="mysourcegraph-rg"
INSTANCE_NAME="mysourcegraph-vm"

echo "🧹 Starting cleanup of Azure resources..."

# Check if Azure CLI is logged in
if ! az account show &>/dev/null; then
    echo "❌ Error: You are not logged into Azure CLI. Please run 'az login' first."
    exit 1
fi

# Function to check if a resource exists
resource_exists() {
    local resource_type=$1
    local resource_name=$2
    az $resource_type show --name "$resource_name" --resource-group "$RESOURCE_GROUP" &>/dev/null
}

# Check if resource group exists
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "⚠️ Resource group $RESOURCE_GROUP does not exist. Nothing to clean up."
    exit 0
fi

echo "🛑 Stopping VM if running..."
if resource_exists "vm" "$INSTANCE_NAME"; then
    az vm stop --resource-group "$RESOURCE_GROUP" --name "$INSTANCE_NAME" --no-wait
fi

echo "⚠️ WARNING: This will delete ALL resources in the resource group '$RESOURCE_GROUP'"
echo "This includes:"
echo "  - Virtual Machine"
echo "  - Data Disks"
echo "  - Network Interfaces"
echo "  - Public IPs"
echo "  - Virtual Networks"
echo "  - Network Security Groups"
echo "You have 10 seconds to press Ctrl+C to cancel..."
sleep 10

echo "🗑️ Deleting resource group $RESOURCE_GROUP..."
az group delete --name "$RESOURCE_GROUP" --yes --no-wait

echo "✅ Cleanup initiated!"
echo "Note: Resource group deletion happens in the background and may take a few minutes to complete."
echo "You can check the status with: az group show --name \"$RESOURCE_GROUP\""
