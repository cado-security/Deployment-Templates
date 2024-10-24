variable "region" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "s3_bucket_id" {
  type = string
}

variable "minimum_role_deployment" {
  type = bool
}
