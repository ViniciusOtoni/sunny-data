terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

resource "azurerm_key_vault" "this" {
  name                        = var.name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  tenant_id                   = var.tenant_id
  sku_name                    = "standard"
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true 
}   

resource "azurerm_role_assignment" "bootstrap_kv_secrets_officer" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.bootstrap_spn_object_id 
}

resource "azurerm_key_vault_secret" "spn_client_id" {
  name         = "spn-client-id"
  value        = var.spn_client_id
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.bootstrap_kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "spn_client_secret" {
  name         = "spn-client-secret"
  value        = var.spn_client_secret
  key_vault_id = azurerm_key_vault.this.id
  depends_on   = [azurerm_role_assignment.bootstrap_kv_secrets_officer]
}
