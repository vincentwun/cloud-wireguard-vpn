terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
    // For generating SSH key
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    // For generating WireGuard key pairs
    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "wireguard" {}

# Create a resource group
resource "azurerm_resource_group" "wireguard" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# SSH Key Generation
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# WireGuard Key Generation
resource "wireguard_asymmetric_key" "server" {}

# WireGuard Key Generation for clients
resource "wireguard_asymmetric_key" "clients" {
  count = var.client_count
}