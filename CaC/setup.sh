
#!/bin/bash

set -e

echo "Installing Ansible..."

sudo apt-get update
sudo apt-get install -y ansible python3 openssh-client

echo "Installing Docker Collection..."

ansible-galaxy collection install community.docker

echo "Checking Ansible version..."

ansible --version

echo "CaC setup completed successfully!"
