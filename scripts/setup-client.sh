#!/bin/bash
# Admiral Bash's Adventure - Client Bootstrap Script
# Detects OS and installs the required tools for the student VM.

set -e

echo "🌊 Ahoy! Preparing your vessel for Admiral Bash's DevOps Intensive..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    OS_LIKE=$ID_LIKE
else
    echo "Unknown OS. Please install dependencies manually."
    exit 1
fi

echo "Detected OS: $OS"

# Install System Dependencies & Fish Shell
echo "🐟 Installing System Dependencies and Fish Shell..."
if [[ "$OS" == "ubuntu" || "$OS" == "debian" || "$OS_LIKE" == *"debian"* ]]; then
    sudo apt-get update
    sudo apt-get install -y curl wget git unzip fish
elif [[ "$OS" == "fedora" || "$OS" == "rhel" || "$OS" == "centos" || "$OS_LIKE" == *"fedora"* || "$OS_LIKE" == *"rhel"* ]]; then
    sudo dnf install -y curl wget git unzip fish || sudo yum install -y curl wget git unzip fish
elif [[ "$OS" == "opensuse-tumbleweed" || "$OS" == "opensuse-leap" || "$OS_LIKE" == *"suse"* ]]; then
    sudo zypper install -y curl wget git unzip fish
else
    echo "⚠️ Packager manager not automatically supported. Please install curl, wget, git, unzip, and fish manually."
fi

# Install Starship (From Day 1 Mission Docs)
echo "🚀 Installing Starship Prompt..."
if ! command -v starship &> /dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
else
    echo "Starship already installed."
fi

# Configure Starship in Fish
mkdir -p ~/.config/fish
if ! grep -q "starship init fish | source" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'starship init fish | source' >> ~/.config/fish/config.fish
fi

# Add Fish aliases for kubectl (instructor requirement)
if ! grep -q "alias k=" ~/.config/fish/config.fish 2>/dev/null; then
    echo 'alias k="kubectl"' >> ~/.config/fish/config.fish
fi

# Install Kubectl
echo "⛵ Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "kubectl already installed."
fi

# Install Helm
echo "📦 Installing Helm..."
if ! command -v helm &> /dev/null; then
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm get_helm.sh
else
    echo "Helm already installed."
fi

# Install K9s
echo "🐕 Installing K9s..."
if ! command -v k9s &> /dev/null; then
    K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    curl -Lo k9s.tar.gz "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
    tar -xzf k9s.tar.gz k9s
    sudo install -o root -g root -m 0755 k9s /usr/local/bin/k9s
    rm k9s.tar.gz k9s
else
    echo "K9s already installed."
fi

# Install D2
echo "🗺️ Installing D2..."
if ! command -v d2 &> /dev/null; then
    curl -fsSL https://d2lang.com/install.sh | sh -s --
else
    echo "D2 already installed."
fi

echo "⚓ Setup Complete! The shipyard is ready."
echo "Type 'fish' to drop into your newly configured shell and start the adventure!"
