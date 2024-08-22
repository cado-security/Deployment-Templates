## Terraform module to configure a VM on GCP

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.10"
    }
  }
}

# Configure the Google Provider
provider "google" {
  credentials = var.credentials_file != "" ? file(var.credentials_file) : null
  project     = var.project_id
  region      = var.region
}

locals {
  use_beta = var.nfs_protocol == "NFS_V4_1"
}

module "configure" {
  count      = var.create_cloud_build_role_service_account ? 1 : 0
  source     = "./modules/configure"
  project_id = var.project_id
}

module "networking" {
  source            = "./modules/networking"
  region            = var.region
  unique_name       = var.unique_name
  allowed_ips       = var.allowed_ips
  inbound_ports     = var.inbound_ports
  local_ports       = var.local_ports
  custom_networking = var.custom_networking
}

module "iam" {
  source      = "./modules/iam"
  project_id  = var.project_id
  unique_name = var.unique_name
  role        = var.role
}

module "deploy" {
  source               = "./modules/deploy"
  project_id           = var.project_id
  region               = var.region
  unique_name          = var.unique_name
  vm_size              = var.vm_size
  vol_size             = var.vol_size
  tags                 = var.tags
  service_account      = module.iam.service_account
  boot_disk_image      = var.image
  network_config       = module.networking.vpc_network
  subnetwork_config    = module.networking.custom_subnetwork
  network_name         = module.networking.vpc_network_name
  finalize_cmd         = var.finalize_cmd
  proxy                = var.proxy
  proxy_cert_url       = var.proxy_cert_url
  instance_worker_type = var.instance_worker_type
  use_beta             = local.use_beta
  deploy_nfs           = var.deploy_nfs
}
