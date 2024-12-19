locals {
  split_unique_name = split("-", var.unique_name)
  created_role      = one(google_project_iam_custom_role.custom_role[*].name)
  account_id_suffix = length(local.split_unique_name) > 1 ? "-${local.split_unique_name[length(local.split_unique_name) - 1]}" : ""
}

locals {
  base_permissions = [
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
  ]

  workers_permissions = [
    // Worker Permissions
    "compute.disks.create",
    "compute.instances.create",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",
    "compute.addresses.use",
    "compute.instances.addAccessConfig",
    "compute.instances.delete",
    "compute.instances.setLabels",
    "compute.subnetworks.use",
    "compute.networks.get",
    "compute.networks.list",
    "compute.instances.setTags",
    "compute.instances.get",

    // Adjusting Settings
    "compute.machineTypes.get",
    "compute.machineTypes.list",
    "compute.regions.get",
  ]

  upgrade_permissions = [
    // Upgrade Permissions
    "compute.disks.create",
    "compute.instances.attachDisk",
    "compute.images.useReadOnly",
    "compute.instances.create",
    "compute.addresses.use",
    "compute.instances.detachDisk",
    "compute.instances.deleteAccessConfig",
    "compute.zoneOperations.get",
    "compute.disks.use",
    "compute.subnetworks.useExternalIp",
  ]

  secretmanager_permissions = [
    // Secret Management
    "secretmanager.secrets.create",
    "secretmanager.versions.access",
    "secretmanager.versions.add"
  ]

  acquisition_permissions = [
    "resourcemanager.projects.get",

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
    "compute.projects.get",

    // GKE Acquisition
    "container.clusters.get",
    "container.clusters.list",
    "container.pods.exec",
    "container.pods.get",
    "container.pods.list",
  ]


  # Generate the full list of permissions
  permissions = concat(
    local.base_permissions,
    local.secretmanager_permissions,
    local.upgrade_permissions,
    local.workers_permissions,
    var.deploy_acquisition_permissions ? local.acquisition_permissions : [],
  )
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
  permissions = local.permissions
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
