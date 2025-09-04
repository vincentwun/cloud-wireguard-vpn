# WireGuard VPN on Cloud Platform

一個簡單、安全的 WireGuard VPN，讓你可以透過 Azure VM 建立私人加密隧道，用於遠端存取或保護流量。

---

## 你可能會用到的資源

Azure 帳戶:
- [Azure 免費帳戶](https://azure.microsoft.com/zh-tw/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

網路延遲測試工具:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

動態 DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

## 建立 Azure VM

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

---

## VM 伺服器設定

### 安裝 WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### 啟用 IP Forwarding

`sudo nano /etc/sysctl.conf`

**取消註解 net.ipv4.ip_forward=1**

net.ipv4.ip_forward=1

儲存檔案後，執行以下指令立即套用設定：
`sudo sysctl -p`

---

### 產生 WireGuard 密鑰

****
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


**複製以下輸出內容, 貼上在你的Client PC /etc/wireguard/wg0.conf**

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

---

# Client Ubuntu24設定

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

---