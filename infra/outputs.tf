output "spn_client_id" {
  value = module.service_principal.spn_client_id
}

output "spn_object_id" {
  value = module.service_principal.spn_object_id
}

output "application_client_id" {
  value = module.service_principal.application_client_id
}

output "spn_client_secret" {
  value     = module.service_principal.spn_client_secret
  sensitive = true
}
