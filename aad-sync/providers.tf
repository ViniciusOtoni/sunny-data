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

# Databricks Account provider (autenticação via Azure SPN dinâmica)
provider "databricks" {
  alias              = "account"
  host               = "https://accounts.azuredatabricks.net"
  account_id         = var.databricks_account_id
  azure_client_id    = var.dbx_spn_client_id
  azure_client_secret= var.dbx_spn_client_secret
  azure_tenant_id    = var.tenant_id
  auth_type          = "azure-client-secret"
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


# Client ID da SPN dinâmica armazenado no mesmo KV (criado no core-identity)
data "azurerm_key_vault_secret" "dynamic_spn_client_id" {
  provider     = azurerm.admin
  name         = "spn-client-id"
  key_vault_id = data.azurerm_key_vault.kv.id
}

