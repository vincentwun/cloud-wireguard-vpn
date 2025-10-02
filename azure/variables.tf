variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "azure-wireguard-rg1"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "uksouth"
}

variable "vnet_address_space" {
  description = "VNet address spaces"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Subnet address prefixes"
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vm_name" {
  description = "WireGuard VM name"
  type        = string
  default     = "azure-wireguard-server"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "VM admin username"
  type        = string
  default     = "azureuser"
}

variable "client_count" {
  description = "Number of WireGuard clients"
  type        = number
  default     = 1
}

variable "vpn_ipv4_cidr" {
  description = "WireGuard tunnel IPv4 CIDR"
  type        = string
  default     = "10.10.0.0/24"
}

variable "vpn_ipv6_cidr" {
  description = "WireGuard tunnel IPv6 CIDR"
  type        = string
  default     = "fd00:10:10::/64"
}

variable "vpn_port" {
  description = "WireGuard UDP port"
  type        = number
  default     = 51820
}

variable "dns_servers" {
  description = "DNS servers for clients"
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]
}

variable "use_ipv6_endpoint" {
  description = "Use IPv6 endpoint (Azure supports IPv4 only)"
  type        = bool
  default     = false

  validation {
    condition     = var.use_ipv6_endpoint == false
    error_message = "IPv6 endpoints are not currently supported in the Azure deployment."
  }
}

variable "interface" {
  description = "Primary network interface name"
  type        = string
  default     = "eth0"
}

variable "tags" {
  description = "Azure resource tags"
  type        = map(string)
  default     = {}
}
