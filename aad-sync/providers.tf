provider "azurerm" {
  alias           = "admin"
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.admin_client_id
  client_secret   = var.admin_client_secret
  features {}
}

# Entra ID (Microsoft Graph) com a SPN “admin” (Owner + consent Graph)
provider "azuread" {
  alias         = "admin"
  tenant_id     = var.tenant_id
  client_id     = var.admin_client_id
  client_secret = var.admin_client_secret
}

# Pegar SCIM token no Key Vault
data "azurerm_key_vault" "kv" {
  provider            = azurerm.admin
  name                = var.kv_name
  resource_group_name = var.kv_rg_name
}

data "azurerm_key_vault_secret" "scim_token" {
  provider    = azurerm.admin
  name        = var.scim_secret_name            
  key_vault_id = data.azurerm_key_vault.kv.id
}

