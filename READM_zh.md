# WireGuard VPN on Cloud Platform

一個簡單、安全的 WireGuard VPN，讓你可以透過 GCP or Azure VM 建立私人加密隧道，用於遠端存取或保護流量。

---

## 資源

Google Cloud 帳戶:
- [Google Cloud 免費計劃](https://cloud.google.com/free/docs/free-cloud-features?hl=zh-tw#compute)

Azure 帳戶:
- [Azure 免費帳戶](https://azure.microsoft.com/zh-tw/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

網路延遲測試工具:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

動態 DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

<details>
<summary>建立 GCP VM</summary>

1. 登入 Google Cloud Console 並建立一個新的Project <YOUR_PROJECT_NAME>
2. 開啟 GCP Cloud Shell

```
PROJECT=<YOUR_PROJECT_NAME>

# 啟用 Compute Engine API
gcloud services enable compute.googleapis.com

# 建立一台新的虛擬機
gcloud compute instances create gcp-wireguard-server \
    --project=$PROJECT \
    --zone=us-west1-a \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --can-ip-forward \
    --provisioning-model=STANDARD \
    --tags=wireguard-server,http-server,https-server

# 設定 GCP 防火牆規則
gcloud compute --project=$PROJECT firewall-rules create allow-wireguard-ingress --description=allow-wireguard-ingress --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=udp:51820 --source-ranges=0.0.0.0/0 --target-tags=wireguard-server
```

3. 之後在VM頁面按 `SSH` 使用瀏覽器進入GCP VM

</details>

---

<details>
<summary>建立 Azure VM</summary>

1. 登入 Azure Portal
2. 在 Azure Portal 打開 Cloud Shell

```
# 建立資源群組
az group create \
  --name azure-wireguard-rg1 \
  --location westus

# 建立網路安全群組
az network nsg create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-nsg \
  --location westus

# 新增 WireGuard 入站安全規則
az network nsg rule create \
  --resource-group azure-wireguard-rg1 \
  --nsg-name azure-wireguard-nsg \
  --name AllowWireGuardInbound \
  --priority 1010 \
  --protocol Udp \
  --access Allow \
  --direction Inbound \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 51820

# 建立虛擬機器
az vm create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-server \
  --location westus \
  --image Canonical:UbuntuServer:24_04-lts-gen2:latest \
  --size Standard_B2ats_v2 \
  --authentication-type ssh \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --nsg-name az group create \
  --name azure-wireguard-rg1 \
  --location westus

# 建立網路安全群組
az network nsg create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-nsg \
  --location westus

# 新增 WireGuard 入站安全規則
az network nsg rule create \
  --resource-group azure-wireguard-rg1 \
  --nsg-name azure-wireguard-nsg \
  --name AllowWireGuardInbound \
  --priority 1010 \
  --protocol Udp \
  --access Allow \
  --direction Inbound \
  --source-address-prefixes '*' \
  --source-port-ranges '*' \
  --destination-address-prefixes '*' \
  --destination-port-ranges 51820

# 建立虛擬機器
az vm create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-server \
  --image Canonical:ubuntu-24_04-lts:server:latest \
  --admin-username azureuser \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --nsg azure-wireguard-nsg
```

3. SSH to 你的Azure VM

找到 azure-wireguard-server VM 頁面 > Connect > More ways to connect > Connect via Azure CLI > Check access > Connect

</details>

---

<details>
<summary>VM 伺服器設定</summary>

### 安裝 WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### 啟用 IP Forwarding

`sudo nano /etc/sysctl.conf`

**取消註解**

找到`#net.ipv4.ip_forward=1`, 修改成`net.ipv4.ip_forward=1`

儲存檔案後，執行以下指令立即套用設定：

`sudo sysctl -p`

### 產生 WireGuard 密鑰

```
mkdir wg_server wg_client
umask 077

wg genkey | tee wg_server/server_privatekey | wg pubkey > wg_server/server_publickey
wg genkey | tee wg_client/client_privatekey | wg pubkey > wg_client/client_publickey

SERVER_PRIVATE_KEY=$(cat wg_server/server_privatekey)
SERVER_PUBLIC_KEY=$(cat wg_server/server_publickey)
CLIENT_PRIVATE_KEY=$(cat wg_client/client_privatekey)
CLIENT_PUBLIC_KEY=$(cat wg_client/client_publickey)
SERVER_IP=$(curl ip.me)
```

**產生WireGuard Server設定檔**

GCP VM 通常使用 ens4 網路介面, 可以 運行 `ip a` command 進一步確認

GCP VM:

```
echo "
[Interface]
# Your Server Private Key
PrivateKey = $SERVER_PRIVATE_KEY
MTU = 1460
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ens4 -j MASQUERADE

# --- Client Peer ---
[Peer]
# Your Client Public Key
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.11/32
"  | sudo tee /etc/wireguard/wg0.conf > /dev/null
```

---

Azure VM 通常使用 eth0 網路介面, 可以 運行 `ip a` command 進一步確認

Azure VM:

```
echo "
[Interface]
# Your Server Private Key
PrivateKey = $SERVER_PRIVATE_KEY
MTU = 1460
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# --- Client Peer ---
[Peer]
# Your Client Public Key
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.11/32
"  | sudo tee /etc/wireguard/wg0.conf > /dev/null
```

**啟動 WireGuard**

`sudo wg-quick up wg0`

**開機自動啟動 WireGuard**

`sudo systemctl enable wg-quick@wg0`

**在VM Server輸入以下內容後, 會輸出新的output自動完成 [Interface] 及 [Peer]的資料**

```
echo "
[Interface]
# Your Client Private Key
PrivateKey = $CLIENT_PRIVATE_KEY
MTU = 1460
Address = 10.0.0.11/24
DNS = 1.1.1.1, 1.0.0.1
SaveConfig = true

# --- Server Peer ---
[Peer]
# Your Server Public Key
PublicKey = $SERVER_PUBLIC_KEY
# Your Server IP or DDNS
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
"
```

**複製新的輸出內容, 貼上在你的Client PC /etc/wireguard/wg0.conf 當中**

</details>

---

<details>
<summary>Client Ubuntu24設定</summary>

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

</details>