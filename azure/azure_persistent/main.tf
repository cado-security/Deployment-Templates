// Variables

variable "resource_group" {
  type = string
  description = "resource group name"
}

variable "region" {
  type = string
  description = "Region to deploy in"
}

variable "share_size" {
  type = number
  description = "Size of network file share"
}

variable "main_data_size" {
  type = number
  description = "Size of main instance persistent disk"
  default = 30
}

variable "tags" {
    type = map(string)
    default = {}
}
// Resources

data "azurerm_subscription" "subscription" {
}

resource "azurerm_resource_group" "group" {
  name = var.resource_group
  location = var.region
  tags = var.tags
}

// Network

resource "azurerm_public_ip" "public_ip" {
  name                = "cado-public-ip"
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  allocation_method   = "Static"   // Static required for provisioner, workaround possibl https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/public_ip#example-usage-retrieve-the-dynamic-public-ip-of-a-new-vm
}

// Storage

resource "azurerm_storage_account" "storage" {
  # Remove special characters
  name                     = "cadostorage${substr(sha256("${var.resource_group}x"), 0, 13)}"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "cadoevidence"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_storage_share" "share" {
  name                 = "cadoshare"
  storage_account_name = azurerm_storage_account.storage.name
  quota                = var.share_size  # TODO increase to 2TB
}

resource "azurerm_managed_disk" "data_disk" {
  name                 = "cado-main-vm-disk"
  resource_group_name  = azurerm_resource_group.group.name
  location             = azurerm_resource_group.group.location
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.main_data_size
}

// Roles

resource "azurerm_role_assignment" "role_assignment_group" {
  // Contributor inside our own resource group
  scope                = azurerm_resource_group.group.id
  role_definition_name = "Contributor" 
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}


resource "azurerm_role_assignment" "role_assignment_storage" {
  // Storage Account Contributor for entire subscription
  scope                = data.azurerm_subscription.subscription.id
  role_definition_name = "Storage Account Contributor" 
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "role_assignment_snapshots" {
  // Disk Snapshot Contributor for entire subscription
  scope                = data.azurerm_subscription.subscription.id
  role_definition_name = "Disk Snapshot Contributor" 
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "role_assignment_vm" {
  // Virtual Machine Contributor for entire subscription - needed to list disks
  scope                = data.azurerm_subscription.subscription.id
  role_definition_name = "Virtual Machine Contributor" 
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_role_assignment" "role_assignment_aks" {
  // Azure Kubernetes Service Contributor for entire subscription - needed to list cluster credentials
  scope = data.azurerm_subscription.subscription.id
  role_definition_name = "Azure Kubernetes Service Cluster Admin Role"
  principal_id = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_user_assigned_identity" "identity" {
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location

  name = "cado-identity"
}