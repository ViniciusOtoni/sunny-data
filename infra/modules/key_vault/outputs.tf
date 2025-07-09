output "key_vault_id" {
  value       = azurerm_key_vault.this.id
  description = "ID do Key Vault"
}

output "key_vault_uri" {
  value       = azurerm_key_vault.this.vault_uri
  description = "URI do Key Vault"
}