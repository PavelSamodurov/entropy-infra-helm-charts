# ResonanceLab — Talos Single-Node Cluster Setup

Prerequisites: [`talosctl`](https://github.com/siderolabs/talos/releases), `kubectl`, `helm`.

## 1. Boot the node

Boot the VM from Talos ISO. The node starts in **maintenance mode** — waiting for config over the network.

> To return to maintenance mode later: reattach the ISO in VirtualBox, set Optical first in boot order, reboot.

## 2. Run bootstrap script

```shell
./bootstrap.sh
```

The script will prompt for:
- Local node IP (e.g. `192.168.1.10`)
- Public IP (your router's external IP, used for GitHub Actions)
- GitHub username and PAT (for pulling images from GHCR)

It then:
1. Generates machine configs and applies them to the node
2. Bootstraps Kubernetes
3. Saves `~/.kube/config` and `~/.talos/config`
4. Prints the base64-encoded kubeconfig for GitHub secret `KUBECONFIG`

> **Do not re-run the script** unless the node is fully reset — each run regenerates TLS certificates and breaks access to an already configured node.

## 3. Deploy ResonanceLab

Save the printed base64 value as GitHub secret `KUBECONFIG`, then run workflows in order:

1. **`bootstrap-ingress`** — installs ingress-nginx, cert-manager, ClusterIssuers
2. **`deploy-infrastructure`** — deploys postgres, pgadmin, ollama (choose `dev` or `prod`)
3. **`deploy-reusable`** — deploys ai-gateway Helm chart
