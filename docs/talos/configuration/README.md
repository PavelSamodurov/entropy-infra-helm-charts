# ResonanceLab — Talos Single-Node Cluster Setup

Prerequisites: [`talosctl`](https://github.com/siderolabs/talos/releases), `kubectl`, `helm`.

## 1. Boot the node

Download the Talos ISO from https://github.com/siderolabs/talos/releases and boot the target machine from it.
The node will be in maintenance mode, reachable at `<NODE_IP>`.

## 2. Generate machine configs

Fill in real values for `GITHUB_USERNAME` and `GITHUB_PAT` in `patch-controlplane.yaml`, then:

```shell
talosctl gen config resonancelab https://<NODE_IP>:6443 \
  --config-patch-control-plane @patch-controlplane.yaml \
  --output-dir _out
```

This produces `_out/controlplane.yaml`, `_out/talosconfig`. Do not commit these files.

## 3. Apply config and bootstrap

```shell
talosctl apply-config --insecure --nodes <NODE_IP> --file _out/controlplane.yaml

talosctl bootstrap \
  --nodes <NODE_IP> \
  --endpoints <NODE_IP> \
  --talosconfig _out/talosconfig
```

Wait ~2 minutes for the cluster to come up:

```shell
talosctl health --nodes <NODE_IP> --endpoints <NODE_IP> --talosconfig _out/talosconfig
```

## 4. Get kubeconfig

```shell
talosctl kubeconfig \
  --nodes <NODE_IP> \
  --endpoints <NODE_IP> \
  --talosconfig _out/talosconfig
```

This merges the cluster into `~/.kube/config`. For GitHub Actions — encode and save as secret `KUBECONFIG`:

```shell
cat ~/.kube/config | base64 -w 0
```

## 5. Deploy ResonanceLab

Run GitHub Actions workflows in order:

1. **`bootstrap-ingress`** — installs ingress-nginx, cert-manager, ClusterIssuers
2. **`deploy-infrastructure`** — deploys postgres, pgadmin, ollama (choose `dev` or `prod`)
3. **`deploy-reusable`** — deploys ai-gateway Helm chart
