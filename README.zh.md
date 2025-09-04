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

1. 登入 Google Cloud Console 並建立一個新的Project
2. 啟用 Compute Engine API
3. 導覽至 Compute Engine > VM 執行個體，並建立一台新的虛擬機

| Instance Setting | 設定值 |
|------|--------|
| 名稱 | `gcp-wireguard-server` |
| 區域 | `us-west1` 或你想部署的地方 |
| 機型 | `e2-micro` 或你想部署的類型 |

| OS & Storage Setting | 設定值 |
|------|--------|
| Disk | `標準永久磁碟` |
| Size | `30GB` |
| Image | `Ubuntu 24.04 LTS` |

| Network Setting | 設定值 |
|------|--------|
| 允許 HTTP 流量 |☑️ |
| 允許 HTTPS 流量 | ☑️ |
| IP 轉送 | ☑️ |
| 網路標記 | 加入新tag `wireguard-server` |

4. 完成所有設定後，點擊 `Create`

## 設定 GCP 防火牆規則

1. 在 GCP Console 搜尋欄輸入firewall > 建立防火牆規則

### 允許 WireGuard 連線進入 (Ingress)

| 欄位 | 設定值 |
|------|--------|
| 名稱 | `allow-wireguard-ingress` |
| 方向 | Ingress |
| 目標 | 指定 VM 標籤 `wireguard-server` |
| 來源 IP | `0.0.0.0/0` 或你的固定 IP |
| 協定/埠 | `UDP:51820` |
| 動作 | Allow |

2. 完成所有設定後，點擊 `Create`

3. 之後在VM頁面按 `SSH` 使用瀏覽器進入GCP VM

</details>

---

<details>
<summary>建立 Azure VM</summary>

1. 登入 Azure Portal 並建立一個新的Resource Group
2. 在 Azure Portal 搜尋「虛擬機器」並點擊「建立」
3. 導覽至 Compute Engine > VM 執行個體，並建立一台新的虛擬機

| Basic | 設定值 |
|------|--------|
| Virtual machine name | `azure-wireguard-server` |
| 區域 | `(US) West US` 或你想部署的地方 |
| 機型 | `e2-micro` 或你想部署的類型 |
| Security type | `標準` |
| Image | `Ubuntu Server 24 LTS Gen2` |
| VM architecture  | `x64` |
| Size | `Standard_B2ats_v2` |
| Authentication type | `SSH public key` |

| Networking | 設定值 |
|------|--------|
| New Public IP Name | `azure-wireguard-ip` |
| Routing preference | `Microsoft network` |
| NIC network security group | `Advanced` |

| Add New Inbound Security Rule for NSG | 設定值 |
|------|--------|
| Source | `Any` |
| Source port ranges | `*` |
| Destination | `*` |
| Service | `Custom` |
| Destination port ranges | `51820` |
| Protocol | `UDP` |
| Action | `Allow` |
| Priority | `1010` |
| Name | `AllowWireGuardInbound` |

4. 完成所有設定後，點擊 `Create`

5. SSH to 你的Azure VM

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