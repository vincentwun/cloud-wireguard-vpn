locals {
  server_ipv4_address = cidrhost(var.vpn_ipv4_cidr, 1)
  server_ipv6_address = cidrhost(var.vpn_ipv6_cidr, 1)

  client_configs = [
    for idx in range(var.client_count) : {
      ipv4_address  = cidrhost(var.vpn_ipv4_cidr, idx + 2)
      ipv6_address  = cidrhost(var.vpn_ipv6_cidr, idx + 2)
      private_key   = wireguard_asymmetric_key.clients[idx].private_key
      public_key    = wireguard_asymmetric_key.clients[idx].public_key
      preshared_key = wireguard_preshared_key.clients[idx].preshared_key
    }
  ]

  peer_configs = indent(6, join("\n", [
    for cfg in local.client_configs : <<-EOT
		[Peer]
		PublicKey = ${cfg.public_key}
		PresharedKey = ${cfg.preshared_key}
		AllowedIPs = ${cfg.ipv4_address}/32,${cfg.ipv6_address}/128
		EOT
  ]))

  cloud_init_config = templatefile("${path.module}/cloud-init.yaml.tpl", {
    server_private_key  = wireguard_asymmetric_key.server.private_key
    server_ipv4_address = "${local.server_ipv4_address}/32"
    server_ipv6_address = "${local.server_ipv6_address}/128"
    peer_configs        = local.peer_configs
    interface           = var.interface
  })

  server_endpoint = azurerm_public_ip.wireguard.ip_address
}

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
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-noble"
    sku       = "24_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.cloud_init_config)

  tags = var.tags
}

resource "local_sensitive_file" "client_configs" {
  count = var.client_count

  content = templatefile("${path.module}/client-config.tpl", {
    client_private_key  = local.client_configs[count.index].private_key
    client_ipv4_address = local.client_configs[count.index].ipv4_address
    client_ipv6_address = local.client_configs[count.index].ipv6_address
    server_public_key   = wireguard_asymmetric_key.server.public_key
    server_public_ip    = local.server_endpoint
    dns_servers         = join(", ", var.dns_servers)
  })

  filename        = format("%s/client-configs/client%02d.conf", path.module, count.index + 1)
  file_permission = "0600"
}
