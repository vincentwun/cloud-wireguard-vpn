## WireGuard VPN on GCP

Deploy a WireGuard VPN server on Google Cloud Platform using Terraform and cloud-init.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- GCP project with billing enabled

## Authenticate and Configure

1. Login:
```bash
gcloud auth login --update-adc
```
2. Set your project:
```bash
gcloud beta billing accounts list
```
```bash
Billing_Account_ID=<your billing account ID>
```
```bash
PROJECT_ID=wireguard-vpn-2025
gcloud projects create $PROJECT_ID --name=$PROJECT_ID --set-as-default
gcloud beta billing projects link $PROJECT_ID --billing-account=$Billing_Account_ID
gcloud config set project $PROJECT_ID
gcloud auth application-default set-quota-project $PROJECT_ID
gcloud services enable compute.googleapis.com --project=$PROJECT_ID
```

## Deploy Infrastructure

1. Initialize:
```bash
terraform init
```
2. Plan and apply:
```bash
terraform plan -out=tfplan
terraform apply tfplan
```

## Client Configuration
Client configs are generated under `client-configs/` post-deployment.

Follow these steps on the client machine (Ubuntu) to use a generated client config.

1. Install WireGuard on your client:

```bash
sudo apt update && sudo apt install wireguard -y
```

2. Secure your config:

```bash
# replace the path below with the actual generated file
sudo mkdir -p /etc/wireguard
sudo cp /path/to/cloud-wireguard-vpn/azure/client-configs/client01.conf /etc/wireguard/wg0.conf
sudo chmod 600 /etc/wireguard/wg0.conf
```

3. Enable and start VPN:

```bash
sudo wg-quick up wg0
sudo systemctl enable wg-quick@wg0
```

4. Verify connection:

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

## Optional: SSH into VM

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 600 wireguard-ssh-key
ssh -i wireguard-ssh-key ubuntu@$(terraform output -raw server_public_ipv4)
```

## Cleanup

```bash
terraform destroy
```