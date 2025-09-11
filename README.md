# WireGuard VPN on Cloud Platform

A simple, secure WireGuard VPN that allows you to create a private encrypted tunnel using a GCP or Azure VM for remote access or traffic protection.

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
<summary>Create GCP VM</summary>

1. Log in to Google Cloud Console and create a new Project <YOUR_PROJECT_NAME>
2. Open GCP Cloud Shell

```
PROJECT=<YOUR_PROJECT_NAME>

# Enable Compute Engine API
gcloud services enable compute.googleapis.com

# Create a new virtual machine
gcloud compute instances create gcp-wireguard-server \
    --project=$PROJECT \
    --zone=us-west1-a \
    --machine-type=e2-micro \
    --network-interface=network-tier=PREMIUM,stack-type=IPV4_ONLY,subnet=default \
    --can-ip-forward \
    --provisioning-model=STANDARD \
    --tags=wireguard-server,http-server,https-server

# Configure GCP firewall rules
gcloud compute --project=$PROJECT firewall-rules create allow-wireguard-ingress --description=allow-wireguard-ingress --direction=INGRESS --priority=1000 --network=default --action=ALLOW --rules=udp:51820 --source-ranges=0.0.0.0/0 --target-tags=wireguard-server
```

3. On the VM page, click `SSH` to access the GCP VM via browser

</details>

---

<details>
<summary>Create Azure VM</summary>

1. Log in to Azure Portal
2. Open Cloud Shell in Azure Portal

```
# Create resource group
az group create \
  --name azure-wireguard-rg1 \
  --location westus

# Create network security group
az network nsg create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-nsg \
  --location westus

# Add WireGuard inbound security rule
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

# Create virtual machine
az vm create \
  --resource-group azure-wireguard-rg1 \
  --name azure-wireguard-server \
  --location westus \
  --image Canonical:UbuntuServer:24_04-lts-gen2:latest \
  --size Standard_B2ats_v2 \
  --authentication-type ssh \
  --generate-ssh-keys \
  --public-ip-sku Standard \
  --nsg azure-wireguard-nsg
```

3. SSH to your Azure VM

Navigate to the azure-wireguard-server VM page > Connect > More ways to connect > Connect via Azure CLI > Check access > Connect

</details>

---

<details>
<summary>VM Server Setup</summary>

### Install WireGuard

`sudo apt update -y && sudo apt install wireguard -y`

### Enable IP Forwarding

`sudo nano /etc/sysctl.conf`

**Uncomment**

Find `#net.ipv4.ip_forward=1` and change it to `net.ipv4.ip_forward=1`

Save the file and apply the settings immediately:

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

**Generate WireGuard Server Configuration**

GCP VMs typically use the ens4 network interface; confirm by running `ip a`.

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

Azure VMs typically use the eth0 network interface; confirm by running `ip a`.

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

**Enable WireGuard on Boot**

`sudo systemctl enable wg-quick@wg0`

**Run the following on the VM Server to generate output for [Interface] and [Peer]**

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

**Copy the output and paste it into your Client PC's /etc/wireguard/wg0.conf**

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

**Reboot WireGuard**

`sudo wg-quick down wg0 && sudo wg-quick up wg0`

**(Optional) Enable WireGuard on Boot**

`sudo systemctl enable wg-quick@wg0`

</details>