# Compute Instance
resource "google_compute_instance" "wireguard" {
  name         = "wireguard-vpn"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    stack_type = "IPV4_IPV6"
    subnetwork = google_compute_subnetwork.vpn_subnet.id
    access_config {}
    ipv6_access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata = {
    ssh-keys  = "ubuntu:${tls_private_key.ssh.public_key_openssh}"
    user-data = data.template_file.cloud_init.rendered
  }

  can_ip_forward = true

  tags = ["wireguard-vpn"]
}
