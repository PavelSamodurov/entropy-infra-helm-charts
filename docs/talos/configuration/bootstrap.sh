#!/bin/bash
set -euo pipefail

echo "=== ResonanceLab Talos Bootstrap ==="
echo

read -rp "Local node IP:    " NODE_IP
read -rp "Public IP:        " PUBLIC_IP
read -rp "GitHub username:  " GITHUB_USERNAME
read -rp "GitHub PAT:       " GITHUB_PAT
echo

export NODE_IP PUBLIC_IP GITHUB_USERNAME GITHUB_PAT

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$SCRIPT_DIR/_out"
mkdir -p "$OUT"

echo
echo "--- Step 1: Generating machine configs ---"
envsubst < "$SCRIPT_DIR/patch-controlplane.yaml" > "$OUT/patch-controlplane-filled.yaml"
talosctl gen config resonancelab "https://$NODE_IP:6443" \
  --config-patch-control-plane "@$OUT/patch-controlplane-filled.yaml" \
  --output-dir "$OUT" \
  --force
rm "$OUT/patch-controlplane-filled.yaml"
echo "✅ Configs generated in _out/"

echo
echo "--- Step 2: Applying config (node must be in maintenance mode) ---"
talosctl apply-config --insecure --nodes "$NODE_IP" --file "$OUT/controlplane.yaml"
echo "✅ Config applied, waiting for node to come back..."
for i in $(seq 1 30); do
  if talosctl version --nodes "$NODE_IP" --endpoints "$NODE_IP" --talosconfig "$OUT/talosconfig" &>/dev/null; then
    echo "✅ Node is back online"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "❌ Node did not come back in time. Check VirtualBox console."
    exit 1
  fi
  echo "   Waiting... ($i/30)"
  sleep 10
done

echo
echo "--- Step 3: Bootstrapping Kubernetes ---"
talosctl bootstrap --nodes "$NODE_IP" --endpoints "$NODE_IP" --talosconfig "$OUT/talosconfig"
echo "Waiting for cluster to come up..."
talosctl health --nodes "$NODE_IP" --endpoints "$NODE_IP" --talosconfig "$OUT/talosconfig"

echo
echo "--- Step 4: Saving kubeconfig and talosconfig ---"
mkdir -p ~/.kube ~/.talos
talosctl kubeconfig --nodes "$NODE_IP" --endpoints "$NODE_IP" \
  --talosconfig "$OUT/talosconfig" --force --merge=false ~/.kube/config
cp "$OUT/talosconfig" ~/.talos/config
echo "✅ ~/.kube/config and ~/.talos/config saved"

echo
echo "--- Step 5: GitHub Actions kubeconfig ---"
talosctl kubeconfig --nodes "$NODE_IP" --endpoints "$NODE_IP" \
  --force --merge=false --force-context-name resonancelab /tmp/kubeconfig-gh
sed -i '' "s|https://$NODE_IP:6443|https://$PUBLIC_IP:6443|" /tmp/kubeconfig-gh
echo
echo "GitHub secret KUBECONFIG (base64):"
echo "------------------------------------"
cat /tmp/kubeconfig-gh | base64 -w 0
echo
echo "------------------------------------"
echo "Copy the value above into GitHub → Settings → Secrets → KUBECONFIG"

echo
kubectl get nodes
echo
echo "=== ✅ Bootstrap complete. Run GitHub Actions workflows to deploy ResonanceLab ==="
