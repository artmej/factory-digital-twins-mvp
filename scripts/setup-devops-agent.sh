#!/bin/bash
# Azure DevOps Self-Hosted Agent Setup Script
# This script automatically configures ACI as Azure DevOps agent

set -e

echo "🚀 Azure DevOps Agent Auto-Setup"

# Install required packages
apt-get update -y
apt-get install -y curl wget jq git unzip

# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Download Azure DevOps Agent
AGENT_VERSION="3.232.3"
cd /tmp
wget https://vstsagentpackage.azureedge.net/agent/${AGENT_VERSION}/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz

# Create agent directory
mkdir -p /home/azp/agent
cd /home/azp/agent
tar zxvf /tmp/vsts-agent-linux-x64-${AGENT_VERSION}.tar.gz

# Set permissions
chmod +x config.sh
chmod +x run.sh

echo "✅ Azure DevOps Agent downloaded and ready"
echo "🔧 Manual configuration required:"
echo "1. Get PAT from: https://dev.azure.com/arturomej/_usersSettings/tokens"
echo "2. Run: ./config.sh --unattended --url https://dev.azure.com/arturomej --auth pat --token YOUR_PAT --pool factory-agents"
echo "3. Run: ./run.sh"

# Keep container running
tail -f /dev/null