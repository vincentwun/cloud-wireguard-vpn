variable "resource_group_name" {
  description = "Name of the Azure resource group to create or reuse."
  type        = string
  default     = "azure-wireguard-rg1"
}

variable "location" {
  description = "Azure region where resources will be deployed."
  type        = string
  default     = "westus"
}

variable "vnet_address_space" {
  description = "Address spaces assigned to the Virtual Network."
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefixes" {
  description = "Address prefixes for the subnet hosting the WireGuard VM."
  type        = list(string)
  default     = ["10.0.1.0/24"]
}

variable "vm_name" {
  description = "Name of the WireGuard virtual machine."
  type        = string
  default     = "azure-wireguard-server"
}

variable "vm_size" {
  description = "Azure VM size to use for the WireGuard server."
  type        = string
  default     = "Standard_B2ats_v2"
}

variable "admin_username" {
  description = "Admin username configured on the WireGuard VM."
  type        = string
  default     = "azureuser"
}

variable "client_count" {
  description = "Number of WireGuard clients to provision."
  type        = number
  default     = 1
}

variable "vpn_ipv4_cidr" {
  description = "IPv4 CIDR block used by the WireGuard tunnel network."
  type        = string
  default     = "10.10.0.0/24"
}

variable "vpn_ipv6_cidr" {
  description = "IPv6 CIDR block used by the WireGuard tunnel network."
  type        = string
  default     = "fd00:10:10::/64"
}

variable "vpn_port" {
  description = "UDP port exposed for WireGuard traffic."
  type        = number
  default     = 51820
}

variable "dns_servers" {
  description = "DNS resolvers pushed to WireGuard clients."
  type        = list(string)
  default     = ["1.1.1.1", "2606:4700:4700::1111"]
}

variable "use_ipv6_endpoint" {
  description = "Whether to expose the server endpoint using IPv6. Azure setup currently supports IPv4 only."
  type        = bool
  default     = false

  validation {
    condition     = var.use_ipv6_endpoint == false
    error_message = "IPv6 endpoints are not currently supported in the Azure deployment."
  }
}

variable "interface" {
  description = "Primary network interface name on the WireGuard VM used for egress firewall rules."
  type        = string
  default     = "eth0"
}

variable "tags" {
  description = "Optional tags applied to Azure resources."
  type        = map(string)
  default     = {}
}
