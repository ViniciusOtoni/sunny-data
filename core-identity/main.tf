locals {
  aad_group_names = [
    "data-platform-engineers",
    "data-consumers",
    "data-analysts",
  ]
}

# Definição dos Resource Groups  

#RG ecossistema CORE
resource "azurerm_resource_group" "rg_core" {
  name     = var.rg_core_name
  location = var.location
  provider = azurerm.admin
}

# RG ecossistema LAKE
resource "azurerm_resource_group" "rg_datalake" {
  name     = var.rg_datalake_name
  location = var.location
  provider = azurerm.admin
}


# Criação da SPN dinâmica (Referência ao módulo)

module "service_principal" {
  source    = "../modules/service_principal"
  tenant_id = var.tenant_id

  providers = { azuread = azuread.admin }
}

# Criação de grupos no Entra id

resource "azuread_group" "aad_groups" {
  for_each         = toset(local.aad_group_names)
  display_name     = each.key
  security_enabled = true
  provider         = azuread.admin
}

# Key Vault + secrets  

module "key_vault" {
  source                  = "../modules/key_vault"
  name                    = var.key_vault_name
  location                = var.location
  resource_group_name     = azurerm_resource_group.rg_core.name
  tenant_id               = var.tenant_id
  bootstrap_spn_object_id = var.bootstrap_spn_object_id
  spn_client_id           = module.service_principal.spn_client_id
  spn_client_secret       = module.service_principal.spn_client_secret

  providers = { azurerm = azurerm.admin }
}


# Atribuição de Roles para a SPN dinâmica 

# Reader na subscription inteira
data "azurerm_subscription" "current" {
  provider = azurerm.admin
}

resource "azurerm_role_assignment" "spn_reader_subscription" {
  provider             = azurerm.admin
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Reader"
  principal_id         = module.service_principal.spn_object_id
}

# Contributor apenas no RG do LAKE
resource "azurerm_role_assignment" "spn_contributor_datalake" {
  provider             = azurerm.admin
  scope                = azurerm_resource_group.rg_datalake.id
  role_definition_name = "Contributor"
  principal_id         = module.service_principal.spn_object_id
}

resource "azurerm_role_assignment" "spn_uaccess_rg_datalake" {
  provider             = azurerm.admin
  scope                = azurerm_resource_group.rg_datalake.id
  role_definition_name = "User Access Administrator"
  principal_id         = module.service_principal.spn_object_id
  principal_type       = "ServicePrincipal" 
}
