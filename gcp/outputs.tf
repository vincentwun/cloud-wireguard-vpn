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