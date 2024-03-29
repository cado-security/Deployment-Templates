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
      size  = 20
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

  metadata_startup_script = join("\n", concat([
    "#!/bin/bash -x",
    "storage_bucket=${google_storage_bucket.bucket.name}",
    "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
    "echo filestore_ip = ${google_filestore_instance.filestore_instance.networks[0].ip_addresses[0]} >> /home/admin/processor/first_run.cfg",
    "echo filestore_name = ${google_filestore_instance.filestore_instance.file_shares[0].name} >> /home/admin/processor/first_run.cfg",
    "echo bucket = $storage_bucket >> /home/admin/processor/first_run.cfg",
    "echo service_account_email = ${var.service_account} >> /home/admin/processor/first_run.cfg",
    "echo processing_mode = scalable-vm >> /home/admin/processor/first_run.cfg",
    "echo feature_flag_platform_upgrade = true >> /home/admin/processor/first_run.cfg",
    ],
    [
      for k, v in var.tags :
      "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
    ],
    [
      "${var.finalize_cmd} 2>&1 | sudo tee /home/admin/processor/init_out"
    ],
    )
  )
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
  name     = "cadoresponse-fileshare-${var.unique_name}"
  location = data.google_compute_zones.available.names[0]
  tier     = "BASIC_HDD"

  file_shares {
    capacity_gb = 1024
    name        = "cado_fileshare"
  }

  networks {
    network           = var.network_name
    modes             = ["MODE_IPV4"]
    reserved_ip_range = "10.5.2.0/29"
  }
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
