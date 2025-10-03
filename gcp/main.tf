terraform {
  required_version = ">= 1.12.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0.0"
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

provider "wireguard" {}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}