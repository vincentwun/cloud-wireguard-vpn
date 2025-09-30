# variables.tf
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
  description = "OS project and family "
  default     = "ubuntu-os-cloud/ubuntu-minimal-2404-lts-amd64"
}

variable "client_count" {
  description = "Number of WireGuard clients to create"
  type        = number
  default     = 1
}

variable "gcp_subnetwork_cidr" {
  description = "IPv4 CIDR for GCP subnetwork where instance will be hosted"
  default     = "10.0.0.0/24"
}

variable "vpn_ipv4_cidr" {
  description = "IPv4 CIDR for WireGuard VPN"
  type        = string
  default     = "10.10.0.0/24"
}

variable "vpn_ipv6_cidr" {
  description = "IPv6 CIDR for WireGuard VPN"
  type        = string
  default     = "fd00:10:10::/64"
}

variable "use_ipv6_endpoint" {
  description = "Use IPv6 endpoint in client config, otherwise use IPv4"
  default     = true
}

variable "interface" {
  description = "Default network interface on the instance"
  default     = "ens4"
}

