variable "region" {
  description = "The zone where the VM will be deployed"
  type        = string
}

variable "unique_name" {
  type = string
}

variable "vm_size" {
  description = "The size of the VM to deploy"
  type        = string
}

variable "vol_size" {
  description = "The size of the volume to attach to the VM"
  type        = number
}

variable "tags" {
  description = "Tags to apply to main vm and any spawned workers"
  type        = map(string)
}

variable "boot_disk_image" {
  description = "The image to use for the VM's boot disk"
  type        = string
}

variable "network_config" {
  description = "The network configuration for the VM"
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network"
}

variable "subnetwork_config" {
  description = "The subnetwork configuration for the VM"
}

variable "service_account" {
  description = "The service account to use for the VM"
  type        = string
}

variable "project_id" {
  description = "Value of the project id to deploy to"
  type        = string
}

variable "proxy" {
  type        = string
  description = "Proxy URL to use for outbound connections in format / User Pass - https://user:pass@1.2.3.4:1234 | IP Auth - https://1.2.3.4:1234"
}

variable "proxy_cert_url" {
  type        = string
  description = "Location of where to download and trust the proxy certificate, leave blank to use proxy without a cert."
}

variable "proxy_whitelist" {
  type        = list(string)
  description = "List of IPs/domains to be included in the no_proxy environment variable"
}

variable "instance_worker_type" {
  type        = string
  description = "Set Worker instance type"
}
variable "nfs_protocol" {
  type        = string
  description = "The Filestore NFS Protocol to use"
}

variable "deploy_nfs" {
  description = "Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files."
  type        = bool
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
