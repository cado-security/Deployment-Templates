data "google_project" "current_project" {
  project_id = var.project_id
}

resource "google_project_iam_custom_role" "cado_cloudbuild_role" {
  project     = data.google_project.current_project.project_id
  role_id     = "CADOCloudbuildRole"
  title       = "CADO Cloud Build Role"
  description = "A custom CADO role for Cloud Build with scoped permissions"
  permissions = [
    # Compute Engine - Instances
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.getSerialPortOutput",
    "compute.instances.list",
    "compute.instances.setLabels",
    "compute.instances.setMetadata",
    "compute.instances.setServiceAccount",

    # Compute Engine - Disks
    "compute.disks.create",
    "compute.disks.delete",
    "compute.disks.get",
    "compute.disks.list",
    "compute.disks.setLabels",
    "compute.disks.use",
    "compute.disks.useReadOnly",

    # Compute Engine - Images
    "compute.images.get",
    "compute.images.list",
    "compute.images.useReadOnly",

    # Compute Engine - Networks and Subnetworks
    "compute.networks.get",
    "compute.networks.list",
    "compute.subnetworks.use",
    "compute.subnetworks.useExternalIp",

    # Compute Engine - Zones and Operations
    "compute.zoneOperations.get",
    "compute.zones.list",

    # Compute Engine - Miscellaneous
    "compute.machineTypes.list",
    "compute.projects.get",

    # Cloud Storage
    "storage.buckets.get",
    "storage.buckets.list",
    "storage.objects.get",

    # IAM
    "iam.serviceAccounts.actAs",

    # Logging
    "logging.logEntries.create",

    # Pub/Sub
    "pubsub.topics.publish",

    # Resource Manager
    "resourcemanager.projects.get",

    # Cloud Source Repositories
    "source.repos.get",
    "source.repos.list",

    # Cloud Build
    "cloudbuild.workerpools.use",
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_roles" {
  project = data.google_project.current_project.project_id
  role    = google_project_iam_custom_role.cado_cloudbuild_role.name
  member  = "serviceAccount:${data.google_project.current_project.number}@cloudbuild.gserviceaccount.com"
}
