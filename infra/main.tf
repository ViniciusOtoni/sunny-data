terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

# Recupera informações da subscription
data "azurerm_subscription" "primary" {
  provider = azurerm.admin
}

# Módulo para criar a SPN dinâmica
module "service_principal" {
  source    = "./modules/service_principal"
  tenant_id = var.tenant_id

  providers = {
    azuread = azuread.admin
  }
}

# Resource Group para SPN + Key Vault
resource "azurerm_resource_group" "rg_core" {
  name     = "rg-medalforge-core"
  location = "brazilsouth"
  provider = azurerm.admin
}

# Resource Group para todos os outros recursos da infraestrutura
resource "azurerm_resource_group" "rg_datalake" {
  name     = "rg-medalforge-datalake"
  location = "brazilsouth"
  provider = azurerm.admin
}

# Key Vault no RG core, provisionado pelo admin
module "key_vault" {
  source                  = "./modules/key_vault"
  name                    = "akv-medalforge-rbac-core"
  location                = azurerm_resource_group.rg_core.location
  resource_group_name     = azurerm_resource_group.rg_core.name
  tenant_id               = var.tenant_id
  bootstrap_spn_object_id = var.bootstrap_spn_object_id
  spn_client_id           = module.service_principal.spn_client_id
  spn_client_secret       = module.service_principal.spn_client_secret

  providers = {
    azurerm = azurerm.admin
  }
}

# Role Assignment: SPN como Reader na subscription
resource "azurerm_role_assignment" "spn_reader_subscription" {
  provider             = azurerm.admin
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = module.service_principal.spn_object_id
}

# Role Assignment: SPN como Contributor no RG datalake
resource "azurerm_role_assignment" "spn_contributor_datalake" {
  provider             = azurerm.admin
  scope                = azurerm_resource_group.rg_datalake.id
  role_definition_name = "Contributor"
  principal_id         = module.service_principal.spn_object_id

  depends_on = [
    azurerm_resource_group.rg_datalake
  ]
}

# Storage Account para o Unity Catalog
module "storage_for_uc" {
  source               = "./modules/storage_account"
  resource_group_name  = azurerm_resource_group.rg_datalake.name
  location             = azurerm_resource_group.rg_datalake.location
  storage_account_name = "medalforgedatabricks"
  container_names       = ["uc-root"]    

  providers = {
    azurerm = azurerm.spn
  }
}

# Storage Account para os dados do Lake
module "storage_for_lake" {
  source               = "./modules/storage_account"
  resource_group_name  = azurerm_resource_group.rg_datalake.name
  location             = azurerm_resource_group.rg_datalake.location
  storage_account_name = "medalforgestorage"
  container_names      = ["raw", "bronze", "silver", "gold"]     

  providers = {
    azurerm = azurerm.spn
  }
}

# Databricks Workspace no RG datalake

module "workspace_create" {
  source              = "./modules/workspace_create"
  workspace_name      = "medalforge-databricks"
  location            = azurerm_resource_group.rg_datalake.location
  resource_group_name = azurerm_resource_group.rg_datalake.name

  providers = {
    azurerm = azurerm.spn
  }
}

# Criar Access Conector
resource "azurerm_databricks_access_connector" "uc" {
  name                = "ac-medalforge"
  resource_group_name = azurerm_resource_group.rg_datalake.name
  location            = azurerm_resource_group.rg_datalake.location
  workspace_name      = module.workspace_create.workspace_name
  identity {
    type = "SystemAssigned"
  }
}

# Permissão para a identidade gerênciada criada

resource "azurerm_role_assignment" "ac_storage_blob_data_contributor" {
  scope                = azurerm_storage_account.lake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.uc.identity[0].principal_id
}


# Atualizando configurações da Workspac
module "workspace_config" {
  source = "./modules/workspace_config"

  # passa o workspace_id criado no módulo anterior
  workspace_url             = module.workspace_create.workspace_url
  workspace_id              = module.workspace_create.workspace_id
  databricks_account_id     = var.databricks_account_id
  azure_managed_identity_id = azurerm_databricks_access_connector.uc.id

  # Unity Catalog
  databricks_region         = azurerm_resource_group.rg_datalake.location
  metastore_name            = "medalforge-catalog"
  uc_storage_root           = "abfss://${module.storage_for_uc.container_names[0]}@${module.storage_for_uc.storage_account_name}.dfs.core.windows.net/"
  uc_storage_credential_name = "medalforge-uc-cred"

  # SPN creds
  spn_client_id     = module.service_principal.spn_client_id
  spn_client_secret = module.service_principal.spn_client_secret
  tenant_id         = var.tenant_id

  # External locations URLs
  raw_url = "abfss://raw@${module.storage_for_lake.storage_account_name}.dfs.core.windows.net/"
  bronze_url = "abfss://bronze@${module.storage_for_lake.storage_account_name}.dfs.core.windows.net/"
  silver_url = "abfss://silver@${module.storage_for_lake.storage_account_name}.dfs.core.windows.net/"
  gold_url   = "abfss://gold@${module.storage_for_lake.storage_account_name}.dfs.core.windows.net/"

  
  providers = {
    # mapeia o alias interno "spn" para o provider databricks.spn do root
    databricks.spn     = databricks.spn
    # mapeia o alias interno "account" para o provider databricks.account do root
    databricks.account = databricks.account
  }
}