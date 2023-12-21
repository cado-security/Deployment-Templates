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
  default     = "projects/cado-public/global/images/cadoresponse-2-101-0"
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
  default     = ["22", "443", "5432", "9200", "6379"] # DO NOT CHANGE
  # 22: SSH, 443: HTTPS, 5432: PostgreSQL, 9200: Elasticsearch, 6379: Redis
}

variable "role" {
  description = "The role to assign to the service account"
  type        = string
  default     = "" # DO NOT CHANGE
}
