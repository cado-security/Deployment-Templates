data "google_project" "current_project" {
  project_id = var.project_id
}

locals {
  roles = [
    "roles/cloudbuild.builds.builder",
    "roles/compute.instanceAdmin.v1",
    "roles/iam.serviceAccountUser"
  ]
}

resource "google_project_iam_member" "cloudbuild_sa_roles" {
  count   = length(local.roles)
  project = data.google_project.current_project.project_id
  role    = local.roles[count.index]
  member  = "serviceAccount:${data.google_project.current_project.number}@cloudbuild.gserviceaccount.com"
}
