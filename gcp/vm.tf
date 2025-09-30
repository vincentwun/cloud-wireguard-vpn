# Calculate IP addresses for server and clients
locals {
  server_ipv4_address = cidrhost(var.vpn_ipv4_cidr, 1)
  server_ipv6_address = cidrhost(var.vpn_ipv6_cidr, 1)

  client_configs = [
    for idx in range(var.client_count) : {
      ipv4_address = cidrhost(var.vpn_ipv4_cidr, idx + 2)
      ipv6_address = cidrhost(var.vpn_ipv6_cidr, idx + 2)
      private_key  = wireguard_asymmetric_key.clients[idx].private_key
      public_key   = wireguard_asymmetric_key.clients[idx].public_key
    }
  ]

  # Indent string to keep cloud-init.yaml well formatted after interpolation
  peer_configs = indent(6, join("\n", [
    for client in local.client_configs : <<-EOT
    [Peer]
    PublicKey = ${client.public_key}
    AllowedIPs = ${client.ipv4_address}/32,${client.ipv6_address}/128
    EOT
  ]))
}

# Cloud-init template
data "template_file" "cloud_init" {
  template = file("cloud-init.yaml.tpl")

  vars = {
    server_private_key  = wireguard_asymmetric_key.server.private_key
    server_ipv4_address = "${local.server_ipv4_address}/32"
    server_ipv6_address = "${local.server_ipv6_address}/128"
    peer_configs        = local.peer_configs
    interface           = var.interface
  }
}

# Compute instance
resource "google_compute_instance" "wireguard" {
  name         = "wireguard-vpn"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    stack_type = "IPV4_IPV6"
    subnetwork = google_compute_subnetwork.vpn_subnet.id
    access_config {}
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    ssh-keys  = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
    user-data = data.template_file.cloud_init.rendered
  }

  can_ip_forward = true

  tags = ["wireguard-vpn"]
}
