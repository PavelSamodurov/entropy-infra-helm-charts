#!/bin/bash
set -euo pipefail

echo "=== Automated K3s + Helm Installation Script ==="
echo "Target: Clean Ubuntu/Debian server"
echo "============================================"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Error: This script must be run as root or with sudo"
  exit 1
fi

# Prevent interactive prompts during package installation
export DEBIAN_FRONTEND=noninteractive

echo "🔄 Updating system packages (non-interactive)..."
apt-get update -qq
apt-get upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"

echo "📦 Installing dependencies..."
apt-get install -y curl net-tools

echo "🐳 Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--disable traefik" sh -

echo "⏳ Waiting for K3s cluster to become ready (this may take 30-90 seconds)..."
sleep 20

for i in {1..40}; do
  if k3s kubectl get nodes 2>/dev/null | grep -q " Ready"; then
    echo "✅ K3s is up and running!"
    break
  fi
  if [ $i -eq 40 ]; then
    echo "⚠️  Warning: K3s did not become ready in time. Check logs with 'journalctl -u k3s'"
  fi
  echo "   Still waiting... ($i/40)"
  sleep 10
done

# Setup kubeconfig for the root user
echo "🔧 Configuring kubeconfig..."
mkdir -p ~/.kube
cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
chmod 600 ~/.kube/config

# Make kubectl and KUBECONFIG available in future sessions
echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc
echo "alias k='kubectl'" >> ~/.bashrc
echo "alias kgp='kubectl get pods -A'" >> ~/.bashrc

# Install latest Helm
echo "⛵ Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh

# Final status
echo ""
echo "=== ✅ INSTALLATION COMPLETED SUCCESSFULLY ==="
echo "K3s version:    $(k3s --version | head -n1 2>/dev/null || echo 'not found')"
echo "Helm version:   $(helm version --short 2>/dev/null || echo 'not found')"
echo ""
echo "Quick check commands:"
echo "   source ~/.bashrc"
echo "   k get nodes"
echo "   k get pods -A"
echo "   helm version"
echo ""
echo "🎉 Your K3s cluster with Helm is ready to use!"
echo "   Traefik has been disabled. ServiceLB is enabled for LoadBalancer support."