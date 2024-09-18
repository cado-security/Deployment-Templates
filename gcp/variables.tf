variable "unique_name" {
  description = "Unique name part for GCP deployments"
  type        = string
  validation {
    condition     = length(var.unique_name) > 0
    error_message = "The unique_name is empty, please set a name."
  }
}

variable "credentials_file" {
  description = "Path to the credentials file"
  type        = string
  default     = ""
}

variable "project_id" {
  description = "Project id to deploy to"
  type        = string
}

variable "region" {
  description = "Region to deploy to"
  type        = string
  default     = "us-central1"
}

variable "image" {
  type        = string
  description = "Cado Response VM image path"
  default     = "projects/cado-public/global/images/cadoresponse"
}

variable "tags" {
  description = "Tags to apply to main vm and any spawned workers"
  type        = map(string)
  default     = {}
}

# Sizing options

variable "vm_size" {
  description = "Vm size to deploy"
  type        = string
  default     = "e2-standard-4"
}

variable "vol_size" {
  description = "The volume size to deploy"
  type        = number
  default     = 100
}

variable "finalize_cmd" {
  description = "Command to run on the VM after deployment"
  type        = string
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
}

# Networking options

variable "allowed_ips" {
  description = "The list of IPs to whitelist"
  type        = list(string)
  default     = []
}

variable "inbound_ports" {
  description = "The list of ports to open"
  type        = list(string)
  default     = ["22", "443"] # DO NOT CHANGE
  # 22: SSH, 443: HTTPS
}

variable "local_ports" {
  description = "The list of ports to open to speak on the local subnet"
  type        = list(string)
  default     = ["5432", "9200", "6379", "24224"] # DO NOT CHANGE
  #  5432: PostgreSQL, 9200: Elasticsearch, 6379: Redis, 24224: Fluent-bit
}

variable "role" {
  description = "The role to assign to the service account"
  type        = string
  default     = "" # DO NOT CHANGE
}

variable "create_cloud_build_role_service_account" {
  description = "Create a custom Cloud Build role"
  type        = bool
  default     = true
}

variable "nfs_protocol" {
  description = "The Filestore NFS Protocol to use"
  type        = string
  default     = "NFS_V3"

  validation {
    condition     = can(regex("^(NFS_V3|NFS_V4_1)$", var.nfs_protocol))
    error_message = "Invalid Filestore Protocol selected, only allowed: 'NFS_V3', 'NFS_V4_1'. Default 'NFS_V3'"
  }
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

variable "instance_worker_type" {
  type        = string
  default     = "n2-standard-8"
  description = "Set Worker instance type"
}

variable "custom_networking" {
  description = "Custom networking configuration. Set to null to create new resources."
  type = object({
    vpc_name           = string
    public_subnet_name = string
  })
  default = null
}

variable "deploy_nfs" {
  description = "Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files."
  type        = bool
  default     = true
}

variable "use_secrets_manager" {
  description = "Use GCP Secret Manager for storing secrets"
  type        = bool
  default     = true
}
