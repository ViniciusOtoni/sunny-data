output "spn_client_id" {
  value = module.service_principal.spn_client_id
}

output "spn_object_id" {
  value = module.service_principal.spn_object_id
}

output "spn_client_secret" {
  value     = module.service_principal.spn_client_secret
  sensitive = true
}

output "key_vault_name" {
  value = var.key_vault_name
}

output "rg_core_name" {
  value = azurerm_resource_group.rg_core.name
}

output "rg_datalake_name" {
  value = azurerm_resource_group.rg_datalake.name
}

output "aad_group_object_ids" {
  description = "Mapa: nome do grupo -> objectId no Entra ID"
  value       = { for name, g in azuread_group.aad_groups : name => g.object_id }
}

output "aad_group_names" {
  description = "Lista dos nomes de grupo geridos"
  value       = [for name, _ in azuread_group.aad_groups : name]
}
