#!/bin/bash
set -euo pipefail

# VirtualBox NAT does not route IPv6. This causes Go HTTP client timeouts
# in cert-manager when it tries to reach Cloudflare API over IPv6.
# Run this script once after K3s is up, before bootstrapping ingress.

echo "=== VirtualBox Network Fix ==="

echo "Disabling IPv6..."
cat > /etc/sysctl.d/99-disable-ipv6.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/99-disable-ipv6.conf

echo "Patching CoreDNS to return NOERROR for AAAA queries..."
kubectl apply -f - <<'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns-custom
  namespace: kube-system
data:
  no-aaaa.override: |
    template IN AAAA {
      rcode NOERROR
    }
EOF
kubectl rollout restart deployment -n kube-system coredns
kubectl rollout status deployment -n kube-system coredns --timeout=2m

echo "Disabling HTTP/2 in cert-manager..."
kubectl set env deployment/cert-manager -n cert-manager GODEBUG=http2client=0
kubectl rollout status deployment/cert-manager -n cert-manager --timeout=2m

echo "=== Done ==="
