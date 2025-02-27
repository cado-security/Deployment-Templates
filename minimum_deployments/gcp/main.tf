terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.10"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.5"
    }
  }
}

###############################################################################
# VARIABLES
###############################################################################

variable "credentials_file" {
  description = "Path to the credentials file"
  type        = string
  default     = ""
}

variable "project_id" {
  type = string
}

variable "region" {
  type = string
}

variable "tags" {
  description = "Tags to apply to main vm and any spawned workers"
  type        = map(string)
  default = {
    stack_name = "cadoresponse"
  }
}

variable "gcp_image" {
  type        = string
  description = <<EOT
Optional override of the GCP image to use.
Example: https://www.googleapis.com/compute/v1/projects/cado-public/global/images/cadoresponse-2-208-0
EOT
  default     = ""
}

# If the user sets this, we'll use it. Otherwise we attempt an HTTP request to checkip.
variable "source_ip" {
  type        = string
  description = "Allow inbound 443 from this IP or CIDR. If blank, we fetch from checkip.amazonaws.com."
  default     = ""
}

variable "bucket" {
  type        = string
  description = "GCS bucket use for CadoResponse data, in same project as deployment."
}

variable "public_ip" {
  type        = bool
  description = "Assign a public IP to the Cado instance"
  default     = true
}

# New variables for specifying VPC network and subnetwork.
# - If both are blank, instance uses the “default” VPC (and default subnetwork).
# - If only network is provided, subnetwork is automatically determined by the region (unless you also set subnetwork).
variable "network_name" {
  description = "VPC network name (or full self_link). Leave blank to use 'default' network."
  type        = string
  default     = ""
}

variable "subnetwork_name" {
  description = "Subnetwork name (or full self_link). Leave blank to use region's default subnetwork."
  type        = string
  default     = ""
}

# Option 1: Provide your own service account email (e.g. existing@my-project.iam.gserviceaccount.com).
# Option 2: Leave blank to let Terraform create one for you.
variable "service_account_email" {
  type        = string
  description = "Use an existing service account email if set, or create a new one if empty."
  default     = ""
}

###############################################################################
# LOCALS
###############################################################################

locals {
  labels = merge(
    {
      "cadoresponse" = "minimum_deploy"
    },
    var.tags
  )

  # Handle Service Account
  effective_sa_email = var.service_account_email != "" ? var.service_account_email : (
    length(google_service_account.vm_service_account) > 0 ? google_service_account.vm_service_account[0].email : ""
  )

  # Determine the network to use: user-provided or default
  effective_network = var.network_name != "" ? var.network_name : "default"

  # Determine the image to use: user-provided or latest Cado image
  cado_json       = var.gcp_image == "" ? jsondecode(data.http.cado_image[0].response_body) : null
  effective_image = var.gcp_image == "" ? local.cado_json.versions[0].gcp_image : var.gcp_image

  # Determine the source IP with /32 if necessary
  raw_source_ip = var.source_ip != "" ? var.source_ip : (
    data.http.source_ip_lookup[0].status_code == 200
    ? chomp(data.http.source_ip_lookup[0].response_body)
    : ""
  )

  effective_source_ip = (
    length(regexall("/", local.raw_source_ip)) == 0
    && local.raw_source_ip != ""
  ) ? format("%s/32", local.raw_source_ip) : local.raw_source_ip
}

###############################################################################
# PROVIDER
###############################################################################

provider "google" {
  credentials = var.credentials_file != "" ? file(var.credentials_file) : null
  project     = var.project_id != "" ? var.project_id : null
  region      = var.region != "" ? var.region : null
}

###############################################################################
# DATA SOURCES
###############################################################################

# Get available zones in the region
data "google_compute_zones" "available" {
  region = var.region != "" ? var.region : null
}

data "google_compute_subnetwork" "selected_subnet_name" {
  count = var.subnetwork_name != "" ? 1 : 0
  name  = var.subnetwork_name
}

# Fetch the latest Cado image if not provided
data "http" "cado_image" {
  count           = var.gcp_image == "" ? 1 : 0
  url             = "https://cado-public.s3.amazonaws.com/cado_updates_json_v2.json"
  request_headers = { Accept = "application/json" }
}

# Fetch caller's public IP if not provided
data "http" "source_ip_lookup" {
  count              = var.source_ip == "" ? 1 : 0
  url                = "http://checkip.amazonaws.com/"
  request_headers    = { Accept = "text/plain" }
  request_timeout_ms = 5000
}

data "google_storage_bucket" "provided_bucket" {
  name = var.bucket
}

###############################################################################
# SERVICE ACCOUNT
###############################################################################

# Create a new service account if none is provided
resource "google_service_account" "vm_service_account" {
  count        = var.service_account_email == "" ? 1 : 0
  account_id   = substr("cado-sa-${local.labels["stack_name"]}", 0, 30)
  display_name = "VM Service Account"
  project      = var.project_id
}

resource "google_project_iam_custom_role" "custom_role" {
  role_id     = replace("myCadoResponseRole_${local.labels["stack_name"]}", "-", "_")
  title       = "myCadoResponseRole-${local.labels["stack_name"]}"
  description = "CadoResponse Role"
  permissions = [
    // Minimal Permissions To Run
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getAccessToken",
    "iam.serviceAccounts.getIamPolicy",

    // Cado Host
    "iam.serviceAccounts.signBlob",

    // Bucket Acquisition
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",

    // Project Access
    "compute.projects.get",
    "resourcemanager.projects.get",
  ]
}

resource "google_project_iam_member" "project_iam_member_cado" {
  project    = var.project_id
  role       = google_project_iam_custom_role.custom_role.name
  member     = "serviceAccount:${local.effective_sa_email}"
  depends_on = [google_project_iam_custom_role.custom_role]
}

###############################################################################
# DISK RESOURCES
###############################################################################

# Create a data disk
resource "google_compute_disk" "data_disk" {
  name                      = "cadoresponse-data-disk-${local.labels["stack_name"]}"
  type                      = "pd-standard"
  size                      = 50
  zone                      = data.google_compute_zones.available.names[0]
  labels                    = local.labels
  physical_block_size_bytes = 4096
}

###############################################################################
# INSTANCE CREATION
###############################################################################

resource "google_compute_instance" "vm_instance" {
  name         = "cado-response-vm-${local.labels["stack_name"]}"
  machine_type = "n2-standard-16"
  zone         = data.google_compute_zones.available.names[0]
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = local.effective_image
    }
  }

  network_interface {
    network    = local.effective_network
    subnetwork = length(data.google_compute_subnetwork.selected_subnet_name) > 0 ? data.google_compute_subnetwork.selected_subnet_name[0].name : null

    dynamic "access_config" {
      for_each = var.public_ip ? [1] : []
      content {
      }
    }
  }

  # Attach the service account
  service_account {
    email  = local.effective_sa_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    user-data = join("\n", concat([
      "#!/bin/bash -x",
      "echo [FIRST_RUN] > /home/admin/processor/first_run.cfg",
      var.bucket != "" ? "echo bucket = ${var.bucket} >> /home/admin/processor/first_run.cfg" : "",
    ]))
  }
}

###############################################################################
# ATTACH DATA DISK
###############################################################################

resource "google_compute_attached_disk" "attached_data_disk" {
  disk        = google_compute_disk.data_disk.id
  instance    = google_compute_instance.vm_instance.id
  device_name = google_compute_disk.data_disk.name
}

###############################################################################
# FIREWALL RULE FOR 443 IF WE HAVE A VALID IP
###############################################################################

resource "google_compute_firewall" "allow_443" {
  count   = local.effective_source_ip == "" ? 0 : 1
  name    = "allow-443-${local.labels["stack_name"]}"
  network = local.effective_network

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = [local.effective_source_ip]
}

###############################################################################
# OUTPUTS
###############################################################################

output "instance_info" {
  description = "Cado Response VM login information"
  value = format(
    "IP Address: https://%s | Instance PWD (ID): %s | Service Account: %s",
    var.public_ip ? google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip : google_compute_instance.vm_instance.network_interface[0].network_ip,
    google_compute_instance.vm_instance.instance_id,
    local.effective_sa_email
  )
}

