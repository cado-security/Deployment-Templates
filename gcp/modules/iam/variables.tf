variable "unique_name" {
  type = string
}

variable "project_id" {
  description = "The Google Cloud project ID where the resources will be created"
  type        = string
}

variable "role" {
  description = "The role to assign to the service account"
  type        = string
  default     = "" # DO NOT CHANGE
}

variable "use_secrets_manager" {
  description = "Use GCP Secret Manager for storing secrets"
  type        = bool
}

variable "local_workers" {
  type        = bool
  description = "Deploy without scalable workers. Only limited acquisition types will be available"
}

variable "deploy_acquisition_permissions" {
  description = "Whether to deploy the acquisition permissions"
  type        = bool
}

variable "enable_platform_updates" {
  description = "Enable platform updates, False requires updates via Terraform"
  type        = bool
}
