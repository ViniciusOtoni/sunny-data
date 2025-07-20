# Recuperando valores do tfstate gerado pelo microserviço (CORE-IDENTITY)
locals {
  rg_core     = data.terraform_remote_state.identity.outputs.rg_core_name
  spn_object  = data.terraform_remote_state.identity.outputs.spn_object_id
}


# Storage Account + container para estados do terraform
resource "azurerm_storage_account" "tfstate" {
  name                     = var.state_sa_name
  resource_group_name      = local.rg_core
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags = { environment = "infra" }
  provider = azurerm.admin
}

resource "azurerm_storage_container" "landing" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
  provider = azurerm.admin
}

# Role: SPN dinâmica como Storage Blob Data Owner
resource "azurerm_role_assignment" "spn_sa_owner" {
  scope                = azurerm_storage_account.tfstate.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = local.spn_object
  provider             = azurerm.admin
}
