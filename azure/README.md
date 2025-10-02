# WireGuard on Azure

This folder has Terraform to create an Azure VM running WireGuard and generate client configs.

## Login

```bash
az login
```

## Build VM Server

```bash
terraform init
terraform plan
terraform apply
```

## Client (Ubuntu) setup

Follow these steps on the client machine (Ubuntu) to use a generated client config.

1. Install WireGuard:

```bash
sudo apt update && sudo apt install wireguard -y
```

2. Copy the generated client file to the WireGuard config location and set permissions:

```bash
# replace the path below with the actual generated file
sudo mkdir -p /etc/wireguard
sudo cp /path/to/cloud-wireguard-vpn/azure/client-configs/client01.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

3. Start WireGuard and enable at boot:

```bash
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

4. Check wg0 status:

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

## (Optional) SSH To Server

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 600 wireguard-ssh-key
ssh -i wireguard-ssh-key azureuser@$(terraform output -raw public_ip_address)
```

## Clean up

```bash
terraform destroy
```