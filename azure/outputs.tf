# Get ssh private key
output "ssh_private_key" {
  description = "PEM formatted private key for SSH access to the WireGuard VM."
  value       = tls_private_key.ssh.private_key_openssh
  sensitive   = true
}

# Get server public IP address
output "public_ip_address" {
  description = "Public IPv4 address assigned to the WireGuard server."
  value       = azurerm_public_ip.wireguard.ip_address
}
