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

# Storage Account no RG datalake
module "storage_account" {
  source                = "./modules/storage_account"
  resource_group_name   = azurerm_resource_group.rg_datalake.name
  location              = azurerm_resource_group.rg_datalake.location
  storage_account_name  = "medalforgestorage"
  container_name        = "raw"

  providers = {
    azurerm = azurerm.spn
  }
}

# Databricks Workspace no RG datalake
module "databricks_workspace" {
  source              = "./modules/databricks_workspace"
  workspace_name      = "medalforge-databricks"
  location            = azurerm_resource_group.rg_datalake.location
  resource_group_name = azurerm_resource_group.rg_datalake.name

  providers = {
    azurerm = azurerm.spn
  }
}
