output "managed_group_names" {
  description = "Grupos AAD geridos por este microserviço"
  value       = [for g in azuread_group.aad_groups : g.display_name]
}

output "managed_group_object_ids" {
  description = "Object IDs dos grupos AAD geridos"
  value       = { for k, g in azuread_group.aad_groups : k => g.object_id }
}

output "dynamic_spn_object_id" {
  description = "Object ID da SPN dinâmica no Entra"
  value       = data.azuread_service_principal.dynamic_spn.object_id
}
