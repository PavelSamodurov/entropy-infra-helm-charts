# ResonanceLab — Talos Single-Node Cluster Setup

Prerequisites: [`talosctl`](https://github.com/siderolabs/talos/releases), `kubectl`, `helm`.

```shell
export NODE_IP=<local-ip>     # e.g. 192.168.1.10
export PUBLIC_IP=<public-ip>  # e.g. your router's external IP
```

---

## 1. Boot the node

Boot the VM from Talos ISO. The node starts in **maintenance mode** — waiting for config over the network.

> To return to maintenance mode later: reattach the ISO in VirtualBox, set Optical first in boot order, reboot.

## 2. Generate machine configs

> **Do this ONCE.** Every `gen config` run generates new TLS certificates.
> If you run it again after applying, `_out/talosconfig` will no longer match the node and you lose access.

Fill in `GITHUB_USERNAME`, `GITHUB_PAT`, and `PUBLIC_IP` in `patch-controlplane.yaml`, then run from this directory:

```shell
talosctl gen config resonancelab https://$NODE_IP:6443 \
  --config-patch-control-plane @patch-controlplane.yaml \
  --output-dir _out
```

Keep `_out/` safe — do not commit, do not regenerate.

## 3. Apply config

Node must be in maintenance mode (step 1). Run from this directory:

```shell
talosctl apply-config --insecure --nodes $NODE_IP --file _out/controlplane.yaml
```

The node reboots and configures itself (~1 min).

## 4. Bootstrap Kubernetes

Run **once** after apply:

```shell
talosctl bootstrap --nodes $NODE_IP --endpoints $NODE_IP --talosconfig _out/talosconfig
```

Wait for the cluster to come up:

```shell
talosctl health --nodes $NODE_IP --endpoints $NODE_IP --talosconfig _out/talosconfig
```

## 5. Get kubeconfig

```shell
mkdir -p ~/.kube ~/.talos
talosctl kubeconfig --nodes $NODE_IP --endpoints $NODE_IP --talosconfig _out/talosconfig --force --merge=false ~/.kube/config
cp _out/talosconfig ~/.talos/config
kubectl get nodes
```

For GitHub Actions — kubeconfig must point to the public IP. Generate a separate copy:

```shell
talosctl kubeconfig --nodes $NODE_IP --endpoints $NODE_IP \
  --force --merge=false --force-context-name resonancelab /tmp/kubeconfig-gh
sed -i '' "s|https://$NODE_IP:6443|https://$PUBLIC_IP:6443|" /tmp/kubeconfig-gh
cat /tmp/kubeconfig-gh | base64 -w 0
```

Save the output as GitHub secret `KUBECONFIG`.

## 6. Deploy ResonanceLab

Run GitHub Actions workflows in order:

1. **`bootstrap-ingress`** — installs ingress-nginx, cert-manager, ClusterIssuers
2. **`deploy-infrastructure`** — deploys postgres, pgadmin, ollama (choose `dev` or `prod`)
3. **`deploy-reusable`** — deploys ai-gateway Helm chart
