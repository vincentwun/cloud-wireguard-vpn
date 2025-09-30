# client-config.tpl
[Interface]
PrivateKey = ${client_private_key}
Address = ${client_ipv4_address}/32,${client_ipv6_address}/128
DNS = ${dns_servers}

[Peer]
PublicKey = ${server_public_key}
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = ${server_public_ip}:51820
PersistentKeepalive = 25
