variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "us-west1-a"
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-micro"
}

variable "image" {
  description = "OS image"
  default     = "ubuntu-os-cloud/ubuntu-minimal-2404-lts-amd64"
}

variable "client_count" {
  description = "Number of WireGuard clients"
  type        = number
  default     = 1
}

variable "gcp_subnetwork_cidr" {
  description = "GCP subnetwork IPv4 CIDR"
  default     = "10.0.0.0/24"
}

variable "vpn_ipv4_cidr" {
  description = "WireGuard VPN IPv4 CIDR"
  type        = string
  default     = "10.10.0.0/24"
}

variable "vpn_ipv6_cidr" {
  description = "WireGuard VPN IPv6 CIDR"
  type        = string
  default     = "fd00:10:10::/64"
}

variable "use_ipv6_endpoint" {
  description = "Use IPv6 endpoint in client config, otherwise use IPv4"
  default     = false
}

variable "interface" {
  description = "Default network interface"
  default     = "ens4"
}