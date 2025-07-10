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

# Módulo para criar a SPN

module "service_principal" {
  source    = "./modules/service_principal"
  tenant_id = var.tenant_id

  providers = {
    azuread = azuread.admin
  }
}

# RG para recursos persistentes
resource "azurerm_resource_group" "rg_core" {
  name     = "rg-medalforge-core"
  location = "brazilsouth"
  provider = azurerm.spn
}

# RG para infraestrutura do projeto
resource "azurerm_resource_group" "rg_datalake" {
  name     = "rg-medalforge-datalake"
  location = "brazilsouth"
  provider = azurerm.spn
}

# Subscription atual
data "azurerm_subscription" "primary" {}

# Permissões para a SPN 
resource "azurerm_role_assignment" "spn_contributor_datalake" {
  provider             = azurerm.admin
  scope                = azurerm_resource_group.rg_datalake.id
  role_definition_name = "Contributor"
  principal_id         = module.service_principal.spn_object_id
}

resource "azurerm_role_assignment" "spn_reader_subscription" {
  provider             = azurerm.admin
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Reader"
  principal_id         = module.service_principal.spn_object_id
}

# Key Vault no RG Core
module "key_vault" {
  source                  = "./modules/key_vault"
  name                    = "akv-medalforge-rbac"
  location                = azurerm_resource_group.rg_core.location
  resource_group_name     = azurerm_resource_group.rg_core.name
  tenant_id               = var.tenant_id
  bootstrap_spn_object_id = var.bootstrap_spn_object_id
  spn_client_id           = module.service_principal.spn_client_id
  spn_client_secret       = module.service_principal.spn_client_secret
  providers               = { azurerm = azurerm.admin }
}

# Storage Account no RG Datalake
module "storage_account" {
  source                = "./modules/storage_account"
  providers             = { azurerm = azurerm.spn }
  resource_group_name   = azurerm_resource_group.rg_datalake.name
  location              = azurerm_resource_group.rg_datalake.location
  storage_account_name  = "medalforgestorage"
  container_name        = "raw"
}

# Databricks Workspace no RG Datalake
module "databricks_workspace" {
  source              = "./modules/databricks_workspace"
  workspace_name      = "medalforge-databricks"
  location            = azurerm_resource_group.rg_datalake.location
  resource_group_name = azurerm_resource_group.rg_datalake.name

  providers = {
    azurerm = azurerm.spn
  }
}
