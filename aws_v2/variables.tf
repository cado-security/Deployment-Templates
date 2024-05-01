variable "region" {
  description = "Region to deploy to"
  type        = string
  default     = "us-west-1"
}

variable "key_name" {
  type = string
}

variable "ami_id" {
  description = "Cado Response AMI ID"
  type        = string
}

variable "ssh_location" { # Deprecated with private
  description = "IP address to allow ssh access from"
  type        = list(string)
}

variable "http_location" {
  description = "IP address to allow http access from"
  type        = list(string)
}

variable "feature_flag_platform_upgrade" {
  type    = bool
  default = false
}

variable "public_deployment" {
  description = "To determine if we should deploy without a public IP"
  type        = bool
  default     = false
}

variable "private_load_balancer" {
  description = "To determine if we should deploy an internal load balancer"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "Certificate arn to use for the ALB"
  type        = string
  default     = ""
}

# Sizing options

variable "vm_size" {
  description = "VM size to deploy"
  type        = string
  default     = "m5.4xlarge"
}

variable "vol_size" {
  description = "Volume size to deploy"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to main vm and any spawned workers"
  type        = map(string)
  default     = {}
}

variable "proxy" {
  type        = string
  description = "Proxy URL to use for outbound connections in format / User Pass - https://user:pass@1.2.3.4:1234 | IP Auth - https://1.2.3.4:1234"
  default     = ""
}

variable "proxy_cert_url" {
  type        = string
  description = "Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert."
  default     = ""
}

# DO NOT CHANGE

variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
}


variable "custom_networking" {
  description = "Custom networking configuration. Set to null to create new resources."
  type = object({
    vpc_id             = string
    public_subnet_id   = string
    private_subnet_id  = string
    public_subnet_b_id = string
  })
  default = null
}

variable "instance_worker_type" {
  type        = string
  default     = "i4i.2xlarge"
  description = "Set Worker instance type"
}
