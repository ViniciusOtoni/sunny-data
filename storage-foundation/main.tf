locals {
  rg_datalake = data.terraform_remote_state.landing.outputs.rg_datalake_name
  spn_object_id = data.terraform_remote_state.landing.outputs.spn_object_id
}


# Storage Account > Unity Catalog

module "storage_uc" {
  source               = "../modules/storage_account"
  resource_group_name  = local.rg_datalake
  location             = var.location
  storage_account_name = "medalforgedatabricks"
  container_names      = ["uc-root"]

  providers = { azurerm = azurerm.admin }
}


# Storage Account > Data Lake

module "storage_lake" {
  source               = "../modules/storage_account"
  resource_group_name  = local.rg_datalake
  location             = var.location
  storage_account_name = "medalforgestorage"
  container_names      = ["raw", "bronze", "silver", "gold"]

  providers = { azurerm = azurerm.admin }
}

# Databricks Access Connector

resource "azurerm_databricks_access_connector" "uc" {
  name                = "ac-medalforge"
  resource_group_name = local.rg_datalake
  location            = var.location

  identity { type = "SystemAssigned" }

  provider = azurerm.admin
}

# Permissão da Manage identity nos dois storages
resource "azurerm_role_assignment" "to_uc" {
  scope                = module.storage_uc.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc.identity[0].principal_id
  provider             = azurerm.admin
}

resource "azurerm_role_assignment" "to_lake" {
  scope                = module.storage_lake.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc.identity[0].principal_id
  provider             = azurerm.admin
}

# Permissão para a SPN dinâmica 
resource "azurerm_role_assignment" "spn_to_lake" {
  scope                = module.storage_lake.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.spn_object_id
  provider             = azurerm.admin
}
