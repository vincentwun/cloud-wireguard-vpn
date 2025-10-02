# Create a Linux VM
resource "azurerm_linux_virtual_machine" "wireguard" {
  name                = var.vm_name
  location            = azurerm_resource_group.wireguard.location
  resource_group_name = azurerm_resource_group.wireguard.name
  size                = var.vm_size
  admin_username      = var.admin_username

  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.wireguard.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init_config)

  tags = var.tags
}