# Credenciais / IDs
variable "subscription_id"     { type = string }
variable "tenant_id"           { type = string }
variable "admin_client_id"     { type = string }

variable "admin_client_secret" { 
  type      = string 
  sensitive = true 
}

# Client ID da SPN dinâmica (usada para achá-la no Entra e adicioná-la aos grupos)
variable "dbx_spn_client_id" {
  type        = string
  description = "Client ID da SPN dinâmica (account_admin) no Entra"
}

# Grupos AAD que serão geridos/sincronizados (fonte de verdade = Entra)
variable "aad_group_names" {
  type    = list(string)
  default = [
    "data-platform-engineers",
    "data-consumers",
    "data-analysts"
  ]
}
