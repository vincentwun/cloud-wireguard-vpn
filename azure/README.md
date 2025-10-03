# WireGuard VPN on Azure

Deploy a WireGuard VPN server on Microsoft Azure using Terraform and cloud-init automation.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)
- Azure subscription

## Authentication and Setup

1. Login to Azure:
```bash
az login
```
2. (Optional) Select subscription:
```bash
az account set --subscription YOUR_SUBSCRIPTION_ID
```

## Deploy Infrastructure

1. Initialize Terraform:
```bash
terraform init
```
2. Review and apply:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Client Configuration
Client configuration files are output to the `client-configs/` directory after deployment.

1. Install WireGuard on the client:

```bash
sudo apt update && sudo apt install wireguard -y
```

2. Secure and install the client config:

```bash
# replace the path below with the actual generated file
sudo mkdir -p /etc/wireguard
sudo cp /path/to/cloud-wireguard-vpn/azure/client-configs/client01.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

3. Enable and start WireGuard:

```bash
sudo systemctl enable wg-quick@wg0
sudo wg-quick up wg0
```

4. Verify the connection:

```bash
sudo wg show wg0
```

5. Stop or reboot tunnel:

```bash
# Stop
sudo wg-quick down wg0
```

```bash
# Reboot
sudo wg-quick down wg0 && sudo wg-quick up wg0
```

## Optional: SSH into the VM

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key.pem
chmod 600 wireguard-ssh-key.pem
ssh -i wireguard-ssh-key.pem azureuser@$(terraform output -raw public_ip_address)
```

## Cleanup

```bash
terraform destroy
```  