# WireGuard VPN on Cloud Platform

A simple and secure WireGuard VPN that lets you create a private encrypted tunnel via a GCP VM for remote access or protecting traffic.

-----

## Resources You Might Use

Google Cloud Account:

  - [Google Cloud Free Tier](https://cloud.google.com/free/docs/free-cloud-features?hl=en)

Network Latency Test Tool:

  - [Cloud Providers Ping Test](https://cloudpingtest.com/)

Dynamic DNS (DDNS):

  - [Duck DNS](https://www.duckdns.org/)
  - [No-IP](https://www.noip.com/)

-----

## Create a GCP VM

1.  Log in to the Google Cloud Console and create a new Project.
2.  Enable the Compute Engine API.
3.  Navigate to Compute Engine \> VM instances, and create a new virtual machine.

| Instance Setting | Value |
|------|--------|
| Name | `gcp-wireguard-server` |
| Region | `us-west1` or your desired location |
| Machine Type | `e2-micro` or your desired type |

| OS & Storage Setting | Value |
|------|--------|
| Disk | `Standard persistent disk` |
| Size | `30GB` |
| Image | `Ubuntu 24.04 LTS` |

| Network Setting | Value |
|------|--------|
| Allow HTTP traffic | ☑️ |
| Allow HTTPS traffic | ☑️ |
| IP Forwarding | ☑️ |
| Network tags | Add new tag `wireguard-server` |

4.  After completing all settings, click `Create`.

-----

## Configure GCP Firewall Rules

1.  In the GCP Console search bar, type firewall \> create a firewall rule.

### Allow WireGuard Inbound Connections (Ingress)

| Field | Value |
|------|--------|
| Name | `allow-wireguard-ingress` |
| Direction | Ingress |
| Target | Specified VM tag `wireguard-server` |
| Source IP | `0.0.0.0/0` or your fixed IP |
| Protocol/Ports | `UDP:51820` |
| Action | Allow |

2.  After completing all settings, click `Create`.

-----

## VM Server Configuration

### Install WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### Enable IP Forwarding

`sudo nano /etc/sysctl.conf`

**Uncomment `net.ipv4.ip_forward=1`**

`net.ipv4.ip_forward=1`

Save the file, then run the following command to apply the settings immediately:
`sudo sysctl -p`

-----

### Generate WireGuard Keys

-----

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

**Generate WireGuard Server config file**

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
" | sudo tee /etc/wireguard/wg0.conf > /dev/null
```

**Start WireGuard**

`sudo wg-quick up wg0`

**Enable WireGuard to start on boot**

`sudo systemctl enable wg-quick@wg0`

**Copy the following output, and paste it into your Client PC's /etc/wireguard/wg0.conf**

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

-----

# Client Ubuntu 24 Configuration

### Install WireGuard

`sudo apt update && sudo apt install wireguard -y`

### Configure WireGuard (Client: wg0.conf)

`sudo nano /etc/wireguard/wg0.conf`

Paste the output copied from the VM Server.

**Start WireGuard**

`sudo wg-quick up wg0`

**Stop WireGuard**

`sudo wg-quick down wg0`

**Reboot the WireGuard:**

`sudo wg-quick down wg0 && sudo wg-quick up wg0`

**(Optional) Enable WireGuard to start on boot**

`sudo systemctl enable wg-quick@wg0`