locals {
  split_unique_name = split("-", var.unique_name)
  created_role      = one(google_project_iam_custom_role.custom_role[*].name)
  account_id_suffix = length(local.split_unique_name) > 1 ? "-${local.split_unique_name[length(local.split_unique_name) - 1]}" : ""
}

resource "google_service_account" "user_service_account" {
  account_id   = "sa-${local.split_unique_name[0]}${local.account_id_suffix}"
  display_name = "CadoResponse Service Account ${var.unique_name}"
  project      = var.project_id
}

resource "google_project_iam_custom_role" "custom_role" {
  count       = var.role == "" ? 1 : 0
  role_id     = replace("myCadoResponseRole_${var.unique_name}", "-", "_")
  title       = "myCadoResponseRole-${var.unique_name}"
  description = "CadoResponse Role"
  permissions = [
    // Instance Acquisition
    "cloudbuild.builds.get",
    "cloudbuild.builds.create",
    "compute.disks.get",
    "compute.disks.use",
    "compute.disks.list",
    "compute.disks.useReadOnly",
    "compute.globalOperations.get",
    "compute.images.create",
    "compute.instances.get",
    "compute.instances.list",
    "compute.images.delete",
    "compute.images.get",
    "compute.instances.getSerialPortOutput",

    // Compute Management
    "compute.disks.create",
    "compute.disks.setLabels",
    "compute.images.useReadOnly",
    "compute.instances.attachDisk",
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.machineTypes.list",
    "compute.machineTypes.get",
    "compute.regions.get",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",
    "compute.networks.get",
    "compute.networks.list",
    "compute.zones.list",
    "compute.zoneOperations.get",


    // Platform Update
    "compute.addresses.use",
    "compute.instances.addAccessConfig",
    "compute.instances.detachDisk",
    "compute.instances.deleteAccessConfig",

    // GKE Acquisition
    "container.clusters.get",
    "container.clusters.list",
    "container.pods.exec",
    "container.pods.get",
    "container.pods.list",

    // IAM & Authentication
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.create",
    "iam.serviceAccounts.enable",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.getAccessToken",
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.implicitDelegation",
    "iam.serviceAccounts.list",
    "iam.serviceAccounts.signBlob",

    // Project Management
    "resourcemanager.projects.get",
    "compute.projects.get",

    // Secret Management
    "secretmanager.versions.access",
    "secretmanager.versions.add",
    "secretmanager.secrets.create",

    // Bucket Acquisition
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list",
  ]
}

resource "google_project_iam_member" "project_iam_member_cado" {
  project    = var.project_id
  role       = local.created_role != null ? local.created_role : var.role
  member     = "serviceAccount:${google_service_account.user_service_account.email}"
  depends_on = [google_project_iam_custom_role.custom_role]
}

output "service_account" {
  description = "The service account to apply to the instance"
  value       = google_service_account.user_service_account.email
}
