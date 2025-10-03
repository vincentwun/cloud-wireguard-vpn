# Get ssh private key
output "ssh_private_key" {
  description = "Private SSH key to access the WireGuard server."
  value     = tls_private_key.ssh.private_key_openssh
  sensitive = true
}

# Get server public IPv4 address
output "server_public_ipv4" {
  description = "Public IPv4 address assigned to the WireGuard server."
  value = local.ipv4_address
}

# Get server public IPv6 address
output "server_public_ipv6" {
  description = "Public IPv6 address assigned to the WireGuard server."
  value = local.ipv6_address
}