output "scim_enterprise_app_object_id" {
  value = azuread_service_principal.scim_sp.object_id
}

output "synced_group_names" {
  value = [for g in azuread_group.aad_groups : g.display_name]
}
