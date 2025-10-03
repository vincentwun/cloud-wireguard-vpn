terraform {
  required_version = ">= 1.12.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
    // For generating SSH key
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    // For generating WireGuard key pairs
    wireguard = {
      source  = "OJFord/wireguard"
      version = ">= 0.4.0"
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