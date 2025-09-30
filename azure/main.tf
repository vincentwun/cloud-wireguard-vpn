terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }

    wireguard = {
      source  = "OJFord/wireguard"
      version = "0.3.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "wireguard" {}

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "wireguard_asymmetric_key" "server" {}

resource "wireguard_asymmetric_key" "clients" {
  count = var.client_count
}

resource "wireguard_preshared_key" "clients" {
  count = var.client_count
}
