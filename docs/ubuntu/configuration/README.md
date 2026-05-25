# Install k3s and Helm

## 1. Copy setup scripts to the remote server

```bash
scp install_k3s_helm.sh user@<SERVER_LOCAL_IP>:~
scp setup-ghcr-k3s.sh user@<SERVER_LOCAL_IP>:~
```

## 2. Connect to the server

```bash
ssh user@<SERVER_LOCAL_IP>
```

## 3. Run installation scripts

```bash
# Install k3s and Helm — pass external IPs to include them in the TLS certificate
# This is required for kubectl and GitHub Actions to connect from outside
sudo bash install_k3s_helm.sh <SERVER_LOCAL_IP> <SERVER_PUBLIC_IP>

# Configure GHCR credentials for pulling private images
sudo bash setup-ghcr-k3s.sh github_login ghp_xxxxxxxxxxxxxxxxxxxxxxxx
```

## 4. Export kubeconfig for local use

```bash
# Print kubeconfig — replace 127.0.0.1 with the external IP before copying
sudo cat /etc/rancher/k3s/k3s.yaml
```

## 5. Encode kubeconfig for GitHub Actions secret (KUBECONFIG)

```bash
# Copy the base64 output and paste it into GitHub Secret KUBECONFIG
cat ~/.kube/config | base64 -w 0
```

## 6. Expand LVM volume if disk space is underallocated

```bash
# Extend logical volume to use all available free space
sudo lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv

# Resize the filesystem to match the new volume size
sudo resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv

# Verify available disk space
df -h /
```
    