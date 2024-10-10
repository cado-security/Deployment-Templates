variable "key_name" {
  type = string
}

variable "feature_flag_platform_upgrade" {
  type = bool
}

variable "public_deployment" {
  type = bool
}

variable "primary_subnet" {
  type = object({
    id                = string
    cidr_block        = string
    availability_zone = string
  })
  description = "Subnet object containing various attributes"
}

variable "security_group_id" {
  type = string
}

variable "tags" {
  type = map(string)
}

variable "ami_id" {
  type = string
}

variable "finalize_cmd" {
  type = string
}

variable "vm_size" {
  type = string
}

variable "proxy" {
  type = string
}

variable "proxy_cert_url" {
  type = string
}

variable "proxy_whitelist" {
  type = list(string)
}

variable "vol_size" {
  type = number
}

variable "role_name" {
  type = string
}

variable "instance_role_name" {
  type = string
}

variable "lb_target_group_arn" {
  type = string
}

variable "instance_worker_type" {
  type = string
}

variable "configure_cloudwatch" {
  type = bool
}

variable "deploy_nfs" {
  type = bool
}

variable "local_workers" {
  type = bool
}

variable "use_secrets_manager" {
  type = bool
}
