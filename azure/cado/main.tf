
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100.0"
    }
  }
  # Optional: add a backend to store tf state in Azure. Otherwise, make sure to keep your tfstate!
}

provider "azurerm" {
  features {}
}

// default variables enclosed in < > should be updated

variable "image_id" {
  type        = string
  description = "Cado Response VHD blobstore URL"
  default     = "<VHD BLOBSTORE URL FROM YOUR STORAGE ACCOUNT>"
}

variable "ip_pattern_https" {
  type        = list(string)
  description = "Incoming IPs permitted to access https. CIDR or source IP range or * to match any IP."
  default     = ["<ENTER IP ADDRESS DETAILS HERE>"] # empty list not accepted
}

variable "ip_pattern_all" {
  type        = list(string)
  description = "Incoming IPs permitted to access https and ssh. CIDR or source IP range or * to match any IP."
  default     = ["<ENTER IP ADDRESS DETAILS HERE>"] # empty list not accpeted
}

variable "instance_type" {
  type        = string
  description = "Instance type to use for main"
  default     = "Standard_D16ds_v4"
}

variable "feature_flag_platform_upgrade" {
  type        = bool
  default     = true
  description = "Set to false if you wish to upgrade via terraform directly. Visit https://docs.cadosecurity.com/cado-response/manage/updating for support."
}

variable "resource_group" {
  type        = string
  description = "resource group name"
  default     = "<ENTER RESOURCE GROUP NAME>"
}

variable "region" {
  type        = string
  description = "Region to deploy in"
  default     = "<ENTER REGION TO DEPLOY PLATFORM INTO>"
}

variable "share_size" {
  type        = number
  description = "Size of network file share"
  default     = 500 # "<ENTER SIZE OF NETWORK SHARE TO BE CREATED>"
}

variable "main_size" {
  type        = number
  description = "Size of main instance local disk"
  default     = 30 # Do not change
}

variable "main_data_size" {
  type        = number
  description = "Size of main instance persistent disk"
  default     = 30 # "<ENTER SIZE FOR PERSISTANCE DISK>"
}

variable "processing_mode" {
  type        = string
  description = "Processing mode to start in"
  default     = "scalable-vm" # Do not change
}

variable "ssh_key_public" {
  type        = string
  description = "Path to SSH public key"
  default     = "~/.ssh/id_rsa.pub" # <PATH TO SSH PUBLIC KEY>
}

variable "ssh_key_private" {
  type        = string
  description = "Path to SSH private key"
  default     = "~/.ssh/id_rsa" # <PATH TO SSH PRIVATE KEY>
}

variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main" # Do not change
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

variable "worker_vm_type" {
  type        = string
  description = "Default worker vm size"
  default     = "Standard_D8ds_v4"
}

variable "tags" {
  type    = map(string)
  default = {}
}

// Resources
module "azure_persistent" {
  source         = "./../azure_persistent"
  resource_group = var.resource_group
  region         = var.region
  share_size     = var.share_size
  main_data_size = var.main_data_size
  tags           = var.tags
}

module "azure_transient" {
  source                        = "./../azure_transient"
  resource_group                = var.resource_group
  image_id                      = var.image_id
  ip_pattern_https              = var.ip_pattern_https
  ip_pattern_all                = var.ip_pattern_all
  instance_type                 = var.instance_type
  main_size                     = var.main_size
  processing_mode               = var.processing_mode
  worker_vm_type                = var.worker_vm_type
  ssh_key_private               = var.ssh_key_private
  ssh_key_public                = var.ssh_key_public
  finalize_cmd                  = var.finalize_cmd
  proxy                         = var.proxy
  proxy_cert_url                = var.proxy_cert_url
  feature_flag_platform_upgrade = var.feature_flag_platform_upgrade
  depends_on = [
    module.azure_persistent
  ]
  tags = var.tags
}
