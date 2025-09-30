# WireGuard VPN on Cloud Platform

一個簡單、安全的 WireGuard VPN，讓你可以透過 GCP or Azure VM 建立私人加密隧道，用於遠端存取或保護流量。

---

## 資源

Google Cloud:
- [Google Cloud 免費計劃](https://cloud.google.com/free/docs/free-cloud-features?hl=zh-tw#compute)

- [gcloud CLI](https://cloud.google.com/sdk/docs/install)

Azure:
- [Azure 免費帳戶](https://azure.microsoft.com/zh-tw/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-linux?view=azure-cli-latest&pivots=apt)

Terraform:
- [Install Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

網路延遲測試工具:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

動態 DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

## 建立 Azure Wireguard Server

1. 進入 Azure 目錄:

```bash
cd azure
```

2. 登入 Azure:

```bash
az login
```

3. 執行 Terraform 部署

```bash
terraform init
terraform plan
terraform apply
```

4. SSH into the server

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 400 wireguard-ssh-key
ssh -i wireguard-ssh-key ubuntu@$(terraform output -raw server_public_ipv4)
```

---

## 建立 GCP Wireguard Server

1. 進入 GCP 目錄：

```bash
cd gcp
```

2. 登入 Google Cloud：

```bash
gcloud auth application-default login
```

3. 設定專案 ID：

```bash
PROJECT_ID=wireguard-server
export TF_VAR_project_id=$PROJECT_ID
```

4. 設定帳單帳戶：

```bash
gcloud beta billing accounts list
Billing_Account_ID=<您的帳單帳戶 ID>

```
5. 進行配置

```bash
gcloud projects create $PROJECT_ID --name=$PROJECT_ID --set-as-default
gcloud beta billing projects link $PROJECT_ID --billing-account=$Billing_Account_ID
gcloud config set project $PROJECT_ID
gcloud auth application-default set-quota-project $PROJECT_ID
gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com --project=$PROJECT_ID
```

6. 執行 Terraform 部署

```bash
terraform init
terraform plan -var="project_id=${PROJECT_ID}"
terraform apply -auto-approve -var="project_id=${PROJECT_ID}"
```

7. SSH into the server

```bash
terraform output -raw ssh_private_key > wireguard-ssh-key
chmod 400 wireguard-ssh-key
ssh -i wireguard-ssh-key ubuntu@$(terraform output -raw server_public_ipv4)
```

---

## Client Ubuntu24設定

### 安裝 WireGuard

`sudo apt update && sudo apt install wireguard -y`

### 設定 WireGuard (Client:wg0.conf)

`sudo nano /etc/wireguard/wg0.conf`

把從 VM Server 複製的內容貼上

**啟動 WireGuard**

`sudo wg-quick up wg0`

**關閉 WireGuard**

`sudo wg-quick down wg0`

**Reboot the WireGuard:**

`sudo wg-quick down wg0 && sudo wg-quick up wg0`

**(可選) 設定開機自動啟動**

`sudo systemctl enable wg-quick@wg0`