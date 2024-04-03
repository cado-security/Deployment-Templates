## Create a VPC network with a firewall rule(s)

resource "google_compute_network" "vpc_network" {
  name                    = "cadoresponse-vpc-${var.unique_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnetwork" {
  name                     = "cadoresponse-subnet-${var.unique_name}"
  region                   = var.region
  ip_cidr_range            = "10.5.1.0/24"
  network                  = google_compute_network.vpc_network.name
  private_ip_google_access = true
}

resource "google_compute_firewall" "firewall_rule" {
  name    = "cadoresponse-fw-${var.unique_name}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = var.inbound_ports
  }

  source_ranges = concat(var.allowed_ips, [google_compute_subnetwork.custom_subnetwork.ip_cidr_range])
}

resource "google_compute_firewall" "loca_firewall_rule" {
  name = "cadoresponse-fw-${var.unique_name}-local"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = var.local_ports
  }

  source_ranges = [google_compute_subnetwork.custom_subnetwork.ip_cidr_range]
}


output "vpc_network" {
  description = "The self link of the created VPC network"
  value       = google_compute_network.vpc_network.self_link
}

output "vpc_network_name" {
  description = "The name of the created VPC network"
  value       = google_compute_network.vpc_network.name
}

output "custom_subnetwork" {
  description = "The self link of the created subnetwork"
  value       = google_compute_subnetwork.custom_subnetwork.self_link
}
