# Get server public IP addresses
locals {
  ipv6_address = google_compute_instance.wireguard.network_interface[0].ipv6_access_config[0].external_ipv6
  ipv4_address = google_compute_instance.wireguard.network_interface[0].access_config[0].nat_ip
}

# Creates ready to use local files for client configurations.
resource "local_sensitive_file" "client_configs" {
  count = var.client_count

  content = templatefile("client-config.tpl", {
    client_private_key  = wireguard_asymmetric_key.clients[count.index].private_key
    client_ipv4_address = local.client_configs[count.index].ipv4_address
    client_ipv6_address = local.client_configs[count.index].ipv6_address
    server_public_key   = wireguard_asymmetric_key.server.public_key
    server_public_ip = (var.use_ipv6_endpoint ?
      "[${local.ipv6_address}]" :
    local.ipv4_address)
  })

  filename        = "client${count.index + 1}.conf"
  file_permission = "0600"
}

# Get ssh private key
output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_openssh
  sensitive = true
}

output "server_public_ipv4" {
  value = local.ipv4_address
}

output "server_public_ipv6" {
  value = local.ipv6_address
}