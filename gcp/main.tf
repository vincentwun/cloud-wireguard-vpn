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