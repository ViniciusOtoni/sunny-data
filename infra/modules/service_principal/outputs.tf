output "application_client_id" {
  value = azuread_application.this.client_id
}

output "spn_object_id" {
  value = azuread_service_principal.this.object_id
}

output "spn_client_id" {
  value = azuread_service_principal.this.client_id
}

output "spn_client_secret" {
  value     = azuread_application_password.this.value
}
