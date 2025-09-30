resource "azurerm_resource_group" "wireguard" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

resource "azurerm_virtual_network" "wireguard" {
  name                = "vnet-wireguard"
  location            = azurerm_resource_group.wireguard.location
  resource_group_name = azurerm_resource_group.wireguard.name
  address_space       = var.vnet_address_space

  tags = var.tags
}

resource "azurerm_subnet" "wireguard" {
  name                 = "snet-wireguard"
  resource_group_name  = azurerm_resource_group.wireguard.name
  virtual_network_name = azurerm_virtual_network.wireguard.name
  address_prefixes     = var.subnet_address_prefixes
}

resource "azurerm_public_ip" "wireguard" {
  name                = "pip-wireguard"
  resource_group_name = azurerm_resource_group.wireguard.name
  location            = azurerm_resource_group.wireguard.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = var.tags
}

resource "azurerm_network_security_group" "wireguard" {
  name                = "nsg-wireguard"
  location            = azurerm_resource_group.wireguard.location
  resource_group_name = azurerm_resource_group.wireguard.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowWireGuard"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.vpn_port)
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowOutbound"
    priority                   = 2000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource "azurerm_network_interface" "wireguard" {
  name                = "nic-wireguard"
  location            = azurerm_resource_group.wireguard.location
  resource_group_name = azurerm_resource_group.wireguard.name

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.wireguard.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.wireguard.id
  }

  tags = var.tags
}

resource "azurerm_network_interface_security_group_association" "wireguard" {
  network_interface_id      = azurerm_network_interface.wireguard.id
  network_security_group_id = azurerm_network_security_group.wireguard.id
}
