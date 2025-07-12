output "storage_account_name" {
  value = azurerm_storage_account.this.name
}

output "container_names" {
  value = [for container in azurerm_storage_container.this : container.name]
}

output "storage_account_id" {
  value = azurerm_storage_account.this.id
}