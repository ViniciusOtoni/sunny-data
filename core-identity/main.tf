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

# Buffer para propagação da SPN no Entra ID

resource "time_sleep" "after_spn" {
  create_duration = "20s"
  depends_on      = [module.service_principal]
}

# Cria/assegura os grupos no Entra ID (com a SPN admin)
locals {
  aad_groups = toset(var.aad_group_names)
}

# Criação de grupos no Entra id

resource "azuread_group" "aad_groups" {
  for_each         = local.aad_groups
  display_name     = each.key
  security_enabled = true
  provider         = azuread.admin
  depends_on       = [time_sleep.after_spn]
}

# Adiciona a SPN DINÂMICA como membro de TODOS os grupos
resource "azuread_group_member" "dynamic_spn_in_groups" {
  for_each         = azuread_group.aad_groups
  group_object_id  = each.value.object_id
  member_object_id = module.service_principal.spn_object_id
  provider         = azuread.admin

  depends_on = [azuread_group.aad_groups]
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
