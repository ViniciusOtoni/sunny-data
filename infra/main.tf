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


module "service_principal" {
  source    = "./modules/service_principal"
  tenant_id = var.tenant_id

  providers = {
    azuread = azuread.admin
  }
}

data "azurerm_subscription" "primary" {}

resource "azurerm_role_assignment" "spn_contributor" {
  provider             = azurerm.admin
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"                # ou "Reader", se só precisar ler providers
  principal_id         = module.service_principal.spn_object_id
}

resource "azurerm_resource_group" "rg_medalforge" {
  name     = "rg-medalforge"
  location = "brazilsouth"
  
  provider = azurerm.spn
}


module "key_vault" {
  source                  = "./modules/key_vault"
  name                    = "akv-medalforge-rbac"
  location                = azurerm_resource_group.rg_medalforge.location
  resource_group_name     = azurerm_resource_group.rg_medalforge.name
  tenant_id               = var.tenant_id
  bootstrap_spn_object_id = var.bootstrap_spn_object_id
  spn_client_id           = module.service_principal.spn_client_id
  spn_client_secret       = module.service_principal.spn_client_secret
  providers               = { azurerm = azurerm.admin }
}


module "storage_account" {
  source                = "./modules/storage_account"
  providers             = { azurerm = azurerm.spn }
  resource_group_name   = azurerm_resource_group.rg_medalforge.name
  location              = azurerm_resource_group.rg_medalforge.location
  storage_account_name  = "medalforgestorage"
  container_name        = "raw"
}


module "databricks_workspace" {
  source              = "./modules/databricks_workspace"
  workspace_name      = "medalforge-databricks"
  location            = azurerm_resource_group.rg_medalforge.location
  resource_group_name = azurerm_resource_group.rg_medalforge.name

  providers = {
    azurerm = azurerm.spn
  }
}
