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

# Creates ready to use local files for client configurations.
output "client_config_files" {
  description = "Paths to generated WireGuard client configuration files."
  value       = [for cfg in local_sensitive_file.client_configs : cfg.filename]
}

# Convenience SSH command
output "ssh_command" {
  description = "Convenience SSH command for connecting to the WireGuard VM."
  value       = format("ssh -i /path/to/private_key %s@%s", var.admin_username, azurerm_public_ip.wireguard.ip_address)
}
