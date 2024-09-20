
// Variables

variable "deploy_nfs" {
  type        = bool
  description = "Deploy NFS for storing files after processing. Setting to false will disable the re-running of analysis pipelines and downloading files."
  default     = true
}

variable "image_id" {
  type        = string
  description = "Cado Response VHD blobstore URL"
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

variable "finalize_cmd" {
  type        = string
  description = "Finalize command"
  default     = "sudo /home/admin/processor/release/finalize.sh --main"
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
  type        = map(string)
  description = "Tags to apply to main vm and any spwaned workers"
  default     = {}
}

variable "use_secrets_manager" {
  type        = bool
  description = "Use Azure Key Vault for storing secrets"
  default     = true
}

// Resources

data "azurerm_subscription" "subscription" {
}

data "azurerm_resource_group" "group" {
  name = var.resource_group
}

data "azurerm_client_config" "current" {}


// Network

resource "azurerm_image" "image" {
  name                = "cado_response"
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name

  os_disk {
    os_type  = "Linux"
    os_state = "Generalized"
    blob_uri = var.image_id # azurerm_storage_blob.vhd.url
    size_gb  = 30
  }
}

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

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_key_public)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = var.main_size
  }

  identity {
    type         = "UserAssigned"
    identity_ids = ["${data.azurerm_user_assigned_identity.identity.id}"]
  }

  tags = var.tags

  source_image_id = azurerm_image.image.id

  provisioner "remote-exec" {
    inline = concat([
      // Set first_run.cfg
      "echo [FIRST_RUN] | sudo tee /home/admin/processor/first_run.cfg",
      "echo elastic_hostname = ${self.private_ip_address}:9200 | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo private_ip = ${self.private_ip_address} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo deployment_mode = terraform | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo worker_instance = ${var.worker_vm_type} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo feature_flag_platform_upgrade = ${var.feature_flag_platform_upgrade} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo bucket = ${data.azurerm_storage_container.container.name} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo PROXY_url = ${var.proxy} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo PROXY_cert_url = ${var.proxy_cert_url} | sudo tee -a /home/admin/processor/first_run.cfg",
      "echo -n ${azurerm_key_vault.keyvault.vault_uri} | sudo tee -a /home/admin/processor/envars/KEYVAULT_URI",
      ],
      var.deploy_nfs ? [
        "echo azure_storage_share = ${data.azurerm_storage_share.share[0].name} | sudo tee -a /home/admin/processor/first_run.cfg",
        "echo azure_storage_account = ${data.azurerm_storage_account.storage.name} | sudo tee -a /home/admin/processor/first_run.cfg"
      ] : [],
      [
        for k, v in var.tags :
        "echo CUSTOM_TAG_${k} = ${v} | sudo tee -a /home/admin/processor/first_run.cfg"
      ],
      [
        "echo -n ${var.use_secrets_manager} | sudo tee -a /home/admin/processor/envars/USE_SECRETS_MANAGER"
      ],
      [
        join(" ", concat([
          "${var.finalize_cmd}",
          var.proxy != "" ? " --proxy ${var.proxy}" : "",
          var.proxy_cert_url != "" ? " --proxy-cert-url ${var.proxy_cert_url}" : "",
          "2>&1 | sudo tee /home/admin/processor/init_out"
        ]))
      ],
    )

    connection {
      type        = "ssh"
      user        = "adminuser"
      private_key = file(var.ssh_key_private)
      host        = data.azurerm_public_ip.public_ip.ip_address
    }
  }
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
  object_id    = data.azurerm_user_assigned_identity.identity.principal_id

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
}
