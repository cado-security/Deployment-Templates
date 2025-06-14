
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.27.0"
    }
  }
  # Optional: add a backend to store tf state in Azure. Otherwise, make sure to keep your tfstate!
}

provider "azurerm" {
  features {}
}

// default variables enclosed in < > should be updated

variable "deploy_nfs" {
  type        = bool
  description = "Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files."
  default     = true
}

variable "deploy_acquisition_permissions" {
  type        = bool
  description = "If set to true, permissions are added at the subscription level, allowing same subscription acquisition."
  default     = true
}

variable "image_id" {
  type        = string
  description = "A Cado Response image id"
  default     = "/communityGalleries/cadoplatform-1a38e0c7-afa4-4e0d-9c56-433a12cd67b1/images/CadoResponseV2.0/versions/latest"
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
  default     = "Standard_D16ds_v5"
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
  default     = 100 # "<ENTER SIZE FOR PERSISTANCE DISK>"
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
variable "proxy_whitelist" {
  type        = list(string)
  description = "List of IPs/domains to be included in the no_proxy environment variable"
  default     = []
}
variable "service_principal" {
  description = "The details of an azure service principal"
  type = object({
    client_id     = string
    tenant_id     = string
    client_secret = string
    object_id     = string
  })
  default = null
  validation {
    condition = (
      var.service_principal == null ||
      (var.service_principal.client_id == "" && var.service_principal.tenant_id == "" && var.service_principal.client_secret == "" && var.service_principal.object_id == "") ||
      (var.service_principal.client_id != "" && var.service_principal.tenant_id != "" && var.service_principal.client_secret != "" && var.service_principal.object_id != "")
    )
    error_message = "service_principal must be null or contain client_id, tenant_id, client_secret and object_id"
  }
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

variable "use_secrets_manager" {
  type        = bool
  description = "Use Azure Key Vault for storing secrets"
  default     = true
}

variable "local_workers" {
  type        = bool
  default     = false
  description = "Deploy without scalable workers. Only limited acquisition types will be available"
}

// Resources
module "azure_persistent" {
  source                         = "./../azure_persistent"
  resource_group                 = var.resource_group
  region                         = var.region
  share_size                     = var.share_size
  main_data_size                 = var.main_data_size
  tags                           = var.tags
  deploy_acquisition_permissions = var.deploy_acquisition_permissions
  deploy_identity                = var.service_principal == null || (var.service_principal.client_id == "" && var.service_principal.tenant_id == "" && var.service_principal.client_secret == "" && var.service_principal.object_id == "")
}

module "azure_transient" {
  source                         = "./../azure_transient"
  resource_group                 = var.resource_group
  image_id                       = var.image_id
  ip_pattern_https               = var.ip_pattern_https
  deploy_nfs                     = var.deploy_nfs
  ip_pattern_all                 = var.ip_pattern_all
  instance_type                  = var.instance_type
  main_size                      = var.main_size
  worker_vm_type                 = var.worker_vm_type
  ssh_key_private                = var.ssh_key_private
  ssh_key_public                 = var.ssh_key_public
  proxy                          = var.proxy
  proxy_cert_url                 = var.proxy_cert_url
  proxy_whitelist                = var.proxy_whitelist
  service_principal              = var.service_principal
  feature_flag_platform_upgrade  = var.feature_flag_platform_upgrade
  use_secrets_manager            = var.use_secrets_manager
  deploy_acquisition_permissions = var.deploy_acquisition_permissions
  deploy_identity                = var.service_principal == null || (var.service_principal.client_id == "" && var.service_principal.tenant_id == "" && var.service_principal.client_secret == "" && var.service_principal.object_id == "")
  depends_on = [
    module.azure_persistent
  ]
  tags          = var.tags
  local_workers = var.local_workers
}
