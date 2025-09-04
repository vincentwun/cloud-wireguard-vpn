# WireGuard VPN on Cloud Platform

A simple and secure WireGuard VPN that allows you to create a private encrypted tunnel through a GCP or Azure VM for remote access or to protect your traffic.

---

## Resources

Google Cloud Account:
- [Google Cloud Free Tier](https://cloud.google.com/free/docs/free-cloud-features#compute)

Azure Account:
- [Azure Free Account](https://azure.microsoft.com/en-us/pricing/purchase-options/azure-account?icid=azurefreeaccount#freeservices)

Network Latency Test Tool:
- [Cloud Providers Ping Test](https://cloudpingtest.com/)

Dynamic DNS (DDNS):
- [Duck DNS](https://www.duckdns.org/)
- [No-IP](https://www.noip.com/)

---

<details>
<summary>Create GCP VM</summary>

1. Log in to the Google Cloud Console and create a new Project.
2. Enable the Compute Engine API.
3. Navigate to Compute Engine > VM instances and create a new virtual machine.

| Instance Setting | Value |
|------|--------|
| Name | `gcp-wireguard-server` |
| Region | `us-west1` or your preferred location |
| Machine type | `e2-micro` or your preferred type |

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
| Network tags | Add a new tag `wireguard-server` |

4. After completing all settings, click `Create`.

## Set up GCP Firewall Rule

1. In the GCP Console search bar, type `firewall` > Create firewall rule.

### Allow WireGuard Ingress

| Field | Value |
|------|--------|
| Name | `allow-wireguard-ingress` |
| Direction of traffic | Ingress |
| Target | Specified target tags `wireguard-server` |
| Source IP ranges | `0.0.0.0/0` or your static IP |
| Protocols and ports | `UDP:51820` |
| Action on match | Allow |

2. After completing all settings, click `Create`.

3. Then, on the VM instances page, click `SSH` to access the GCP VM via the browser.

</details>

---

<details>
<summary>Create Azure VM</summary>

1. Log in to the Azure Portal and create a new Resource Group.
2. In the Azure Portal, search for "Virtual machines" and click "Create".
3. Navigate to Compute > Virtual machines and create a new virtual machine.

| Basic | Value |
|------|--------|
| Virtual machine name | `azure-wireguard-server` |
| Region | `(US) West US` or your preferred location |
| Security type | `Standard` |
| Image | `Ubuntu Server 24.04 LTS - Gen2` |
| VM architecture | `x64` |
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
| Destination | `Any` |
| Service | `Custom` |
| Destination port ranges | `51820` |
| Protocol | `UDP` |
| Action | `Allow` |
| Priority | `1010` |
| Name | `AllowWireGuardInbound` |

4. After completing all settings, click `Review + create`, then `Create`.

5. SSH to your Azure VM.

Find the `azure-wireguard-server` VM page > Connect > More ways to connect > Connect via Azure CLI > Check access > Connect.

</details>

---

<details>
<summary>VM Server Configuration</summary>

### Install WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### Enable IP Forwarding

`sudo nano /etc/sysctl.conf`

**Uncomment the line**

Find `#net.ipv4.ip_forward=1` and change it to `net.ipv4.ip_forward=1`.

After saving the file, run the following command to apply the settings immediately:

`sudo sysctl -p`

### Generate WireGuard Keys

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

**Generate WireGuard Server Configuration File**

GCP VMs typically use the `ens4` network interface. You can run the `ip a` command to confirm.

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

Azure VMs typically use the `eth0` network interface. You can run the `ip a` command to confirm.

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

**Start WireGuard**

`sudo wg-quick up wg0`

**Enable WireGuard to start on boot**

`sudo systemctl enable wg-quick@wg0`

**Enter the following content on the VM Server, it will generate a new output that automatically completes the [Interface] and [Peer] data**

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

**Copy the new output and paste it into `/etc/wireguard/wg0.conf` on your Client PC.**

</details>

---

<details>
<summary>Client Ubuntu 24 Configuration</summary>

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

**(Optional) Set WireGuard to start on boot**

`sudo systemctl enable wg-quick@wg0`

</details>