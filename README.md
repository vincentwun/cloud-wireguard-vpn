# WireGuard VPN on Cloud Platform

A simple and secure WireGuard VPN to create a private encrypted tunnel via a GCP or Azure VM for remote access or protecting traffic.

---

## Resources

Google Cloud Account:
- [Google Cloud Free Tier](https://cloud.google.com/free/docs/free-cloud-features?hl=en#compute)

Azure Account:
- [Azure Free Account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

Network Latency Test Tool:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

Dynamic DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

<details>
<summary>Create a GCP VM</summary>

1. Log in to the Google Cloud Console and create a new Project
2. Enable the Compute Engine API
3. Navigate to Compute Engine > VM instances, and create a new virtual machine

| Instance Setting | Value |
|------|--------|
| Name | `gcp-wireguard-server` |
| Region | `us-west1` or your desired location |
| Machine type | `e2-micro` or your desired type |

| OS & Storage Setting | Value |
|------|--------|
| Disk | `Standard persistent disk` |
| Size | `30GB` |
| Image | `Ubuntu 24.04 LTS` |

| Network Setting | Value |
|------|--------|
| Allow HTTP traffic |☑️ |
| Allow HTTPS traffic | ☑️ |
| IP forwarding | ☑️ |
| Network tags | Add new tag `wireguard-server` |

4. After completing all settings, click `Create`

## Set up GCP Firewall Rules

1. In the GCP Console search bar, type firewall > Create firewall rule

### Allow WireGuard connections (Ingress)

| Field | Value |
|------|--------|
| Name | `allow-wireguard-ingress` |
| Direction of traffic | Ingress |
| Target tags | Specified target tags `wireguard-server` |
| Source IP ranges | `0.0.0.0/0` or your static IP |
| Protocols and ports | `UDP:51820` |
| Action | Allow |

2. After completing all settings, click `Create`

3. On the VM page, click `SSH` to access the GCP VM via your browser

</details>

---

<details>
<summary>Create an Azure VM</summary>

1. Log in to the Azure Portal and create a new Resource Group
2. In the Azure Portal, search for "Virtual machines" and click "Create"
3. Navigate to Compute Engine > VM instances, and create a new virtual machine

| Basic | Value |
|------|--------|
| Virtual machine name | `azure-wireguard-server` |
| Region | `(US) West US` or your desired location |
| Machine type | `e2-micro` or your desired type |
| Security type | `Standard` |
| Image | `Ubuntu Server 24 LTS Gen2` |
| VM architecture  | `x64` |
| Size | `Standard_B2ats_v2` |
| Authentication type | `SSH public key` |

| Networking | Value |
|------|--------|
| New Public IP Name | `azure-wireguard-ip` |
| Routing preference | `Microsoft network` |
| NIC network security group | `Advanced` |

| Add New Inbound Security Rule for NSG | Value |
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

4. After completing all settings, click `Create`

5. SSH to your Azure VM

Find the azure-wireguard-server VM page > Connect > More ways to connect > Connect via Azure CLI > Check access > Connect

</details>

---

<details>
<summary>VM Server Setup</summary>

### Install WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### Enable IP Forwarding

`sudo nano /etc/sysctl.conf`

**Uncomment**

Find `#net.ipv4.ip_forward=1`, change it to `net.ipv4.ip_forward=1`

After saving the file, run the following command to apply the settings immediately:

`sudo sysctl -p`

### Generate WireGuard Keys

```

mkdir wg\_server wg\_client
umask 077

wg genkey | tee wg\_server/server\_privatekey | wg pubkey \> wg\_server/server\_publickey
wg genkey | tee wg\_client/client\_privatekey | wg pubkey \> wg\_client/client\_publickey

SERVER\_PRIVATE\_KEY=$(cat wg\_server/server\_privatekey)
SERVER\_PUBLIC\_KEY=$(cat wg\_server/server\_publickey)
CLIENT\_PRIVATE\_KEY=$(cat wg\_client/client\_privatekey)
CLIENT\_PUBLIC\_KEY=$(cat wg\_client/client\_publickey)
SERVER\_IP=$(curl ip.me)

```

**Generate WireGuard Server Configuration File**

GCP VMs typically use the `ens4` network interface; you can run the `ip a` command to confirm.

GCP VM:

```

echo "
[Interface]

# Your Server Private Key

PrivateKey = $SERVER\_PRIVATE\_KEY
MTU = 1460
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o ens4 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens4 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o ens4 -j MASQUERADE

# \--- Client Peer ---

[Peer]

# Your Client Public Key

PublicKey = $CLIENT\_PUBLIC\_KEY
AllowedIPs = 10.0.0.11/32
" | sudo tee /etc/wireguard/wg0.conf \> /dev/null

```

---

Azure VMs typically use the `eth0` network interface; you can run the `ip a` command to confirm.

Azure VM:

```

echo "
[Interface]

# Your Server Private Key

PrivateKey = $SERVER\_PRIVATE\_KEY
MTU = 1460
Address = 10.0.0.1/24
ListenPort = 51820
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE; ip6tables -A FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE; ip6tables -D FORWARD -i wg0 -j ACCEPT; ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# \--- Client Peer ---

[Peer]

# Your Client Public Key

PublicKey = $CLIENT\_PUBLIC\_KEY
AllowedIPs = 10.0.0.11/32
" | sudo tee /etc/wireguard/wg0.conf \> /dev/null

```

**Start WireGuard**

`sudo wg-quick up wg0`

**Enable WireGuard to start automatically on boot**

`sudo systemctl enable wg-quick@wg0`

**After entering the following content on the VM Server, it will output new content to automatically complete the [Interface] and [Peer] information.**

```

echo "
[Interface]

# Your Client Private Key

PrivateKey = $CLIENT\_PRIVATE\_KEY
MTU = 1460
Address = 10.0.0.11/24
DNS = 1.1.1.1, 1.0.0.1
SaveConfig = true

# \--- Server Peer ---

[Peer]

# Your Server Public Key

PublicKey = $SERVER\_PUBLIC\_KEY

# Your Server IP or DDNS

Endpoint = $SERVER\_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
"

```

**Copy the new output and paste it into your Client PC's `/etc/wireguard/wg0.conf` file.**

</details>

---

<details>
<summary>Client Ubuntu 24 Setup</summary>

### Install WireGuard

`sudo apt update && sudo apt install wireguard -y`

### Configure WireGuard (Client: wg0.conf)

`sudo nano /etc/wireguard/wg0.conf`

Paste the content copied from the VM Server.

**Start WireGuard**

`sudo wg-quick up wg0`

**Stop WireGuard**

`sudo wg-quick down wg0`

**Reboot the WireGuard:**

`sudo wg-quick down wg0 && sudo wg-quick up wg0`

**(Optional) Enable automatic startup on boot**

`sudo systemctl enable wg-quick@wg0`

</details>