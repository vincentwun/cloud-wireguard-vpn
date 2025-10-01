# WireGuard VPN on Cloud Platform

A simple and secure WireGuard VPN that lets you build a private encrypted tunnel with a GCP or Azure VM for remote access or traffic protection.

---

## Resources

Google Cloud:
- [Google Cloud Free Tier](https://cloud.google.com/free/docs/free-cloud-features?hl=en#compute)

- [gcloud CLI](https://cloud.google.com/sdk/docs/install)

Azure:
- [Azure Free Account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)

Terraform:
- [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

Network latency test:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

Dynamic DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

## Provision an Azure WireGuard Server

1. Change into the Azure directory:

```bash
cd azure
```

2. Sign in to Azure:

```bash
az login
```

3. Run the Terraform deployment:

```bash
terraform init
terraform plan
terraform apply
```

4. SSH into the server:

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 400 wireguard-ssh-key
ssh -i wireguard-ssh-key ubuntu@$(terraform output -raw server_public_ipv4)
```

---

## Provision a GCP WireGuard Server

1. Change into the GCP directory:

```bash
cd gcp
```

2. Sign in to Google Cloud:

```bash
gcloud auth application-default login
```

3. Set the project ID:

```bash
PROJECT_ID=wireguard-server
export TF_VAR_project_id=$PROJECT_ID
```

4. Configure billing:

```bash
gcloud beta billing accounts list
Billing_Account_ID=<your billing account ID>

```
5. Prepare the project:

```bash
gcloud projects create $PROJECT_ID --name=$PROJECT_ID --set-as-default
gcloud beta billing projects link $PROJECT_ID --billing-account=$Billing_Account_ID
gcloud config set project $PROJECT_ID
gcloud auth application-default set-quota-project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com --project=$PROJECT_ID
```

6. Run the Terraform deployment:

```bash
terraform init
terraform plan -var="project_id=${PROJECT_ID}"
terraform apply -var="project_id=${PROJECT_ID}"
```

7. SSH into the server:

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 400 wireguard-ssh-key
ssh -i wireguard-ssh-key ubuntu@$(terraform output -raw server_public_ipv4)
```

---

## Client Ubuntu 24 Setup

1. Install WireGuard

```bash
sudo apt update && sudo apt install wireguard -y
```

2. Configure WireGuard (`wg0.conf`)

```bash
sudo nano /etc/wireguard/wg0.conf
```

Paste the configuration copied from the VM server.

3. Start WireGuard**

```bash
sudo wg-quick up wg0
```

4. Other command

```bash
# Stop WireGuard
sudo wg-quick down wg0`

# Reboot WireGuard
sudo wg-quick down wg0 && sudo wg-quick up wg0

# (Optional) Enable WireGuard at boot
sudo systemctl enable wg-quick@wg0
```