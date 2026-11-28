#!/bin/bash

set -euo pipefail

echo "=== Control Node Setup ==="

# Install required packages
sudo apt-get update
sudo apt-get install -y curl gnupg openssh-client

# Install Terraform
if command -v terraform >/dev/null 2>&1; then
    echo "Terraform is already installed."
else
    echo "Installing Terraform..."

    curl -fsSL https://apt.releases.hashicorp.com/gpg | \
        sudo gpg --batch --yes --dearmor \
        -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(. /etc/os-release && echo "$VERSION_CODENAME") main" | \
        sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt-get update
    sudo apt-get install -y terraform
fi

# Generate SSH Key
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ ! -f "$HOME/.ssh/gcp_key" ]; then
    echo "Generating SSH Key..."

    ssh-keygen -t ed25519 \
        -f "$HOME/.ssh/gcp_key" \
        -N ""
else
    echo "SSH Key already exists."
fi

# Restore public key if missing
if [ ! -f "$HOME/.ssh/gcp_key.pub" ]; then
    ssh-keygen -y -f "$HOME/.ssh/gcp_key" \
        > "$HOME/.ssh/gcp_key.pub"
fi

# Verify installation
echo "=== Verification ==="

terraform version

ls -l "$HOME/.ssh/gcp_key"*

echo "=== EC2 Public IP ==="
curl -4fsS https://checkip.amazonaws.com

echo "=== Setup Completed Successfully ==="