## Create a VPC network with a firewall rule(s)
locals {
  use_custom_networking = var.custom_networking == null ? false : true
}

data "google_compute_network" "selected_vpc_name" {
  name = local.use_custom_networking ? var.custom_networking.vpc_name : google_compute_network.vpc_network[0].name
}

data "google_compute_subnetwork" "selected_subnet_name" {
  name = local.use_custom_networking ? var.custom_networking.public_subnet_name : google_compute_subnetwork.custom_subnetwork[0].name
}

resource "google_compute_network" "vpc_network" {
  count                   = local.use_custom_networking == true ? 0 : 1
  name                    = "cadoresponse-vpc-${var.unique_name}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "custom_subnetwork" {
  count                    = local.use_custom_networking == true ? 0 : 1
  name                     = "cadoresponse-subnet-${var.unique_name}"
  region                   = var.region
  ip_cidr_range            = "10.5.1.0/24"
  network                  = google_compute_network.vpc_network[0].name
  private_ip_google_access = true
}

resource "google_compute_firewall" "firewall_rule" {
  name    = "cadoresponse-fw-${var.unique_name}"
  network = data.google_compute_network.selected_vpc_name.name

  allow {
    protocol = "tcp"
    ports    = var.inbound_ports
  }

  source_ranges = concat(var.allowed_ips, [data.google_compute_subnetwork.selected_subnet_name.ip_cidr_range])
}

resource "google_compute_firewall" "local_firewall_rule" {
  name    = "cadoresponse-fw-${var.unique_name}-local"
  network = data.google_compute_network.selected_vpc_name.name

  allow {
    protocol = "tcp"
    ports    = var.local_ports
  }

  source_ranges = [data.google_compute_subnetwork.selected_subnet_name.ip_cidr_range]
}


output "vpc_network" {
  description = "The self link of the created VPC network"
  value       = data.google_compute_network.selected_vpc_name.self_link
}

output "vpc_network_name" {
  description = "The name of the created VPC network"
  value       = data.google_compute_network.selected_vpc_name.name
}

output "custom_subnetwork" {
  description = "The self link of the created subnetwork"
  value       = data.google_compute_subnetwork.selected_subnet_name.self_link
}
