output "scim_enterprise_app_object_id" {
  description = "Object ID do Enterprise Application (Service Principal) no Entra ID"
  value       = data.azuread_service_principal.scim_sp.object_id
}

output "scim_enterprise_app_id" {
  description = "ID do recurso do Enterprise Application (igual ao object_id)"
  value       = data.azuread_service_principal.scim_sp.id
}

output "scim_application_object_id" {
  description = "Object ID do Application Registration (app) que suporta o Enterprise App"
  value       = azuread_application.scim_app.id
}

output "scim_application_client_id" {
  description = "Client ID (appId) do Application Registration"
  value       = azuread_application.scim_app.client_id
}

output "synced_group_names" {
  description = "Grupos AAD direcionados para o SCIM"
  value       = [for g in azuread_group.aad_groups : g.display_name]
}