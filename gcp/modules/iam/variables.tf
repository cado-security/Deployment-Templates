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
