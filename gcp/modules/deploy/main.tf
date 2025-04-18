## This file is used to deploy a VM instance in GCP

data "google_compute_zones" "available" {
  region = var.region
}

resource "google_compute_instance" "vm_instance" {

  name         = "cadoresponse-vm-${var.unique_name}"
  machine_type = var.vm_size
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = var.boot_disk_image
      size  = 30
    }
  }

  labels = var.tags

  network_interface {
    network    = var.network_config
    subnetwork = var.subnetwork_config
    access_config {
      nat_ip = google_compute_address.ip.address
    }

  }
  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"] # TODO This gives default perms, revisit this if we're having auth issues
  }

  metadata = {
    user-data = join("\n", concat([
      "#!/bin/bash -x",
      "storage_bucket=${google_storage_bucket.bucket.name}",
      "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
      var.deploy_nfs ? "echo filestore_ip = ${google_filestore_instance.filestore_instance[0].networks[0].ip_addresses[0]} >> /home/admin/processor/first_run.cfg" : "",
      var.deploy_nfs ? "echo filestore_name = ${google_filestore_instance.filestore_instance[0].file_shares[0].name} >> /home/admin/processor/first_run.cfg" : "",
      "echo bucket = $storage_bucket >> /home/admin/processor/first_run.cfg",
      "echo service_account_email = ${var.service_account} >> /home/admin/processor/first_run.cfg",
      "echo deployment_mode = terraform >> /home/admin/processor/first_run.cfg",
      "echo feature_flag_platform_upgrade = ${var.enable_platform_updates} >> /home/admin/processor/first_run.cfg",
      var.proxy != "" ? "echo -n ${var.proxy} >> /home/admin/processor/envars/PROXY_url" : "",
      var.proxy_cert_url != "" ? "echo -n ${var.proxy_cert_url} >> /home/admin/processor/envars/PROXY_cert_url" : "",
      length(var.proxy_whitelist) > 0 ? "echo -n ${join(",", var.proxy_whitelist)}  >> /home/admin/processor/envars/PROXY_whitelist" : "",
      "echo worker_instance = ${var.instance_worker_type} >> /home/admin/processor/first_run.cfg",
      "echo local_workers = ${var.local_workers} >> /home/admin/processor/first_run.cfg",
      "echo minimum_role_deployment = ${!var.deploy_acquisition_permissions} >> /home/admin/processor/first_run.cfg",
      "echo -n ${var.use_secrets_manager} > /home/admin/processor/envars/USE_SECRETS_MANAGER",
      ],
      [
        for k, v in var.tags :
        "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
      ],
      )
    )
  }

}

resource "google_compute_address" "ip" {
  name = "cadoresponse-ip-${var.unique_name}"
}


resource "google_compute_disk" "data_disk" {
  name                      = "cadoresponse-data-disk-${var.unique_name}"
  type                      = "pd-standard"
  size                      = var.vol_size
  zone                      = data.google_compute_zones.available.names[0]
  labels                    = var.tags
  physical_block_size_bytes = 4096
}

resource "google_compute_attached_disk" "attached_data_disk" {
  disk        = google_compute_disk.data_disk.id
  instance    = google_compute_instance.vm_instance.id
  device_name = google_compute_disk.data_disk.name
}

resource "google_filestore_instance" "filestore_instance" {
  count    = var.deploy_nfs ? 1 : 0
  name     = "cadoresponse-fileshare-${var.unique_name}"
  location = var.nfs_protocol == "NFS_V3" ? data.google_compute_zones.available.names[0] : var.region
  tier     = var.nfs_protocol == "NFS_V3" ? "BASIC_HDD" : "ENTERPRISE"

  file_shares {
    capacity_gb = 1024
    name        = "cado_fileshare"
  }

  networks {
    network = var.network_name
    modes   = ["MODE_IPV4"]
  }
  protocol   = var.nfs_protocol
  depends_on = [var.network_config]
}


resource "google_storage_bucket" "bucket" {
  name                        = "cadoresponse-bucket-${var.unique_name}"
  location                    = var.region
  project                     = var.project_id
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = true
}
