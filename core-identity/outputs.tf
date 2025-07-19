output "spn_client_id"      { value = module.service_principal.spn_client_id }
output "spn_object_id"      { value = module.service_principal.spn_object_id }
output "spn_client_secret"  { value = module.service_principal.spn_client_secret sensitive = true }
output "key_vault_name"     { value = module.key_vault.name }
output "rg_core_name"       { value = azurerm_resource_group.rg_core.name }
output "rg_datalake_name"   { value = azurerm_resource_group.rg_datalake.name }
