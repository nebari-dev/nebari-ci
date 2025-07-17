#!/bin/bash
set -e

echo "Installing CI tools for Nebari testing..."

# Update package index
sudo apt-get update

# Create runnerx user (matching CI runner environment)
sudo useradd -m -s /bin/bash runnerx
sudo usermod -aG docker runnerx

# Install essential tools from workflow analysis
sudo apt-get install -y \
    jq \
    hub \
    xvfb \
    curl \
    wget \
    unzip

# Install kubectl (latest stable)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Install kind (latest)
curl -Lo ./kind https://kind.sigs.k8s.io/dl/$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | jq -r .tag_name)/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Install k9s (latest)
K9S_LATEST=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | jq -r .tag_name)
curl -L https://github.com/derailed/k9s/releases/download/${K9S_LATEST}/k9s_Linux_amd64.tar.gz | tar xz
sudo mv k9s /usr/local/bin/

# Install Node.js 20 (version specified in workflow)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install miniconda for runnerx user (matching CI runner environment)
sudo -u runnerx wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /home/runnerx/miniconda.sh
sudo -u runnerx bash /home/runnerx/miniconda.sh -b -p /home/runnerx/miniconda3
sudo rm /home/runnerx/miniconda.sh

# Add conda to PATH for runnerx user
echo 'export PATH="/home/runnerx/miniconda3/bin:$PATH"' | sudo tee -a /home/runnerx/.bashrc

# Install pipx for Python package management
sudo apt-get install -y python3-pip python3-venv pipx

# Install Playwright system dependencies
sudo apt-get install -y \
    libatk1.0-0t64 \
    libatk-bridge2.0-0t64 \
    libatspi2.0-0t64 \
    libxcomposite1 \
    libxdamage1 \
    libasound2t64 \
    libdrm2 \
    libxss1 \
    libgbm1 \
    libnss3 \
    libxrandr2 \
    libpangocairo-1.0-0 \
    libcairo-gobject2 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0

# Set up inotify limits for kind (from workflow)
echo "fs.inotify.max_user_watches=524288" | sudo tee -a /etc/sysctl.conf
echo "fs.inotify.max_user_instances=512" | sudo tee -a /etc/sysctl.conf

# Create necessary directories
sudo mkdir -p /opt/runner
sudo chown ubuntu:ubuntu /opt/runner

echo "CI tools installation completed"