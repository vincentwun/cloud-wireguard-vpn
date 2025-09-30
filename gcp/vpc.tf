# VPC Network
resource "google_compute_network" "vpn_network" {
  name                    = "wireguard-network"
  auto_create_subnetworks = false
}

# Subnet
resource "google_compute_subnetwork" "vpn_subnet" {
  name          = "wireguard-subnet"
  ip_cidr_range = var.gcp_subnetwork_cidr
  network       = google_compute_network.vpn_network.id
  region        = var.region

  stack_type       = "IPV4_IPV6"
  ipv6_access_type = "EXTERNAL"
}

# Firewall rules
resource "google_compute_firewall" "wireguard_udp" {
  name    = "allow-wireguard"
  network = google_compute_network.vpn_network.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpn_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "wireguard_udp_ipv6" {
  name    = "allow-wireguard-ipv6"
  network = google_compute_network.vpn_network.name

  allow {
    protocol = "udp"
    ports    = ["51820"]
  }

  source_ranges = ["::/0"]
}

resource "google_compute_firewall" "ssh_ipv6" {
  name    = "allow-ssh-ipv6"
  network = google_compute_network.vpn_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["::/0"]
}