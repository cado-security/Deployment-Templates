provider "google" {
  project = var.project_id
}

# The test module references the module in the root directory
module "test" {
  source = "../.."

  project_id  = var.project_id
  unique_name = "test"
}

# The module must declare a project variable that Marketplace can
# set for validation
variable "project_id" {
  type = string
}
