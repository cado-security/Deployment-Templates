
// Variables
variable "deploy_nfs" {
  type        = bool
  description = "Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files."
  default     = true
}

variable "image_id" {
  type        = string
  description = "A Cado Response image id"
  default     = ""
}

variable "ip_pattern_https" {
  type        = list(string)
  description = "Incoming IPs permitted to access https. CIDR or source IP range or * to match any IP."
  # default = [] # empty list not accepted
}

variable "ip_pattern_all" {
  type        = list(string)
  description = "Incoming IPs permitted to access https and ssh. CIDR or source IP range or * to match any IP."
  # default = $(dig +short myip.opendns.com @resolver1.opendns.com)
}

variable "instance_type" {
  type        = string
  description = "Instance type to use for main"
  default     = "Standard_D2ds_v4" // 2cpu 8gb - WARNING not enough memory for elastic!!!
  // Standard_D8ds_v4 8cpu 32gb
}

variable "resource_group" {
  type        = string
  description = "resource group name"
}

variable "feature_flag_platform_upgrade" {
  type = bool
}

variable "main_size" {
  type        = number
  description = "Size of main instance local disk"
  default     = 30
}


variable "ssh_key_public" {
  type        = string
  description = "Path to SSH public key"
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_key_private" {
  type        = string
  description = "Path to SSH private key"
  default     = "~/.ssh/id_rsa"
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
  sensitive = true
  default   = null
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
  type        = map(string)
  description = "Tags to apply to main vm and any spwaned workers"
  default     = {}
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

variable "deploy_acquisition_permissions" {
  type        = bool
  description = "If set to true, permissions are added at the subscription level, allowing same subscription acquisition."
  default     = true
}

variable "deploy_identity" {
  type        = bool
  description = "If set to true, a user assigned identity will be created and assigned to the VM"
}

// Resources

data "azurerm_subscription" "subscription" {
}

data "azurerm_resource_group" "group" {
  name = var.resource_group
}

data "azurerm_client_config" "current" {}


// Network

resource "azurerm_virtual_network" "network" {
  name                = "cado-network"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.group.name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_security_group" "nsg" {
  name                = "cado-nsg"
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name

  security_rule {
    name                       = "whitelistHttps1"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.ip_pattern_https
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "whitelistHttps2"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefixes    = var.ip_pattern_all
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "whitelistSsh"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.ip_pattern_all
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

data "azurerm_public_ip" "public_ip" {
  name                = "cado-public-ip"
  resource_group_name = data.azurerm_resource_group.group.name
}

resource "azurerm_network_interface" "nic" {
  name                = "cado-nic"
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = data.azurerm_public_ip.public_ip.id
    primary                       = true
  }

  ip_configuration {
    name                          = "static-private-ip"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address            = "10.0.2.10"
    private_ip_address_allocation = "Static"
  }
}

// Storage

data "azurerm_storage_account" "storage" {
  name                = "cadostorage${substr(sha256("${var.resource_group}x"), 0, 13)}"
  resource_group_name = data.azurerm_resource_group.group.name
}

data "azurerm_storage_container" "container" {
  name                 = "cadoevidence"
  storage_account_name = data.azurerm_storage_account.storage.name
}

data "azurerm_storage_share" "share" {
  count                = var.deploy_nfs ? 1 : 0
  name                 = "cadoshare"
  storage_account_name = data.azurerm_storage_account.storage.name
}

data "azurerm_managed_disk" "data_disk" {
  name                = "cado-main-vm-disk"
  resource_group_name = data.azurerm_resource_group.group.name
}


data "azurerm_user_assigned_identity" "identity" {
  count               = var.deploy_identity ? 1 : 0
  name                = "cado-identity"
  resource_group_name = data.azurerm_resource_group.group.name
}


// VMs

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "cado-main-vm"
  resource_group_name = data.azurerm_resource_group.group.name
  location            = data.azurerm_resource_group.group.location
  size                = var.instance_type // 2cpu 8gb
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]
  user_data = base64encode(join("\n", concat([
    "#!/bin/bash -x",
    // Set first_run.cfg
    "echo [FIRST_RUN] | sudo tee /home/admin/processor/first_run.cfg",
    "echo deployment_mode = terraform | sudo tee -a /home/admin/processor/first_run.cfg",
    "echo worker_instance = ${var.worker_vm_type} | sudo tee -a /home/admin/processor/first_run.cfg",
    "echo feature_flag_platform_upgrade = ${var.feature_flag_platform_upgrade} | sudo tee -a /home/admin/processor/first_run.cfg",
    "echo bucket = ${data.azurerm_storage_container.container.name} | sudo tee -a /home/admin/processor/first_run.cfg",
    var.proxy != "" ? "echo -n ${var.proxy} >> /home/admin/processor/envars/PROXY_url" : "",
    var.proxy_cert_url != "" ? "echo -n ${var.proxy_cert_url} >> /home/admin/processor/envars/PROXY_cert_url" : "",
    length(var.proxy_whitelist) > 0 ? "echo -n ${join(",", var.proxy_whitelist)}  >> /home/admin/processor/envars/PROXY_whitelist" : "",
    "echo -n ${azurerm_key_vault.keyvault.vault_uri} | sudo tee -a /home/admin/processor/envars/KEYVAULT_URI",
    "echo -n ${var.use_secrets_manager} | sudo tee -a /home/admin/processor/envars/USE_SECRETS_MANAGER",
    var.service_principal.client_id != "" ? "echo -n ${var.service_principal.client_id} | sudo tee -a /home/admin/processor/envars/AZURE_CLIENT_ID" : "",
    var.service_principal.tenant_id != "" ? "echo -n ${var.service_principal.tenant_id} | sudo tee -a /home/admin/processor/envars/AZURE_TENANT_ID" : "",
    var.service_principal.client_secret != "" ? "echo -n ${var.service_principal.client_secret} | sudo tee -a /home/admin/processor/envars/AZURE_CLIENT_SECRET" : "",
    "echo local_workers = ${var.local_workers} | sudo tee -a /home/admin/processor/first_run.cfg",
    "echo minimum_role_deployment = ${!var.deploy_acquisition_permissions} | sudo tee -a /home/admin/processor/first_run.cfg",
    "echo azure_storage_account = ${data.azurerm_storage_account.storage.name} | sudo tee -a /home/admin/processor/first_run.cfg",
    ],
    var.deploy_nfs ? [
      "echo azure_storage_share = ${data.azurerm_storage_share.share[0].name} | sudo tee -a /home/admin/processor/first_run.cfg",
    ] : [],
    [
      for k, v in var.tags :
      "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
    ],
  )))

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_key_public)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.main_size
  }

  dynamic "identity" {
    for_each = var.deploy_identity ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = ["${data.azurerm_user_assigned_identity.identity[0].id}"]
    }
  }
  tags = var.tags

  source_image_id = var.image_id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data_disk_attachment" {
  managed_disk_id    = data.azurerm_managed_disk.data_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.vm.id
  lun                = "10"
  caching            = "ReadWrite"
}


resource "random_string" "cado" {
  length  = 12
  special = false
}

resource "azurerm_key_vault_access_policy" "cado" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.deploy_identity ? data.azurerm_user_assigned_identity.identity[0].principal_id : var.service_principal.object_id

  secret_permissions = [
    "Get",
    "Set",
    "Delete",
    "List",
  ]
}



resource "azurerm_key_vault" "keyvault" {
  name                        = "cado-${random_string.cado.result}"
  location                    = data.azurerm_resource_group.group.location
  resource_group_name         = data.azurerm_resource_group.group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "standard"
  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}
