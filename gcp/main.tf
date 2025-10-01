terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.12.0"
    }
    // For generating WireGuard key pairs
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.3.1"
    }
    // For generating SSH key
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.0.0"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

provider "wireguard" {}

# SSH Key Generation
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# WireGuard Key Generation
resource "wireguard_asymmetric_key" "server" {}

resource "wireguard_asymmetric_key" "clients" {
  count = var.client_count
}

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