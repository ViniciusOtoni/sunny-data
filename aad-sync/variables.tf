# Credenciais / IDs
variable "subscription_id"     { type = string }
variable "tenant_id"           { type = string }
variable "admin_client_id"     { type = string }

variable "admin_client_secret" { 
    type = string 
    sensitive = true 
}


variable "databricks_account_id" {
  type        = string
  sensitive   = true
  description = "ID do Databricks Account"
}

variable "dbx_spn_client_id" {
  type        = string
  description = "Client ID da SPN dinâmica (account_admin)"
}

variable "dbx_spn_client_secret" {
  type      = string
  sensitive = true
  description = "Client Secret da SPN dinâmica"
}


# Key Vault onde está o SCIM token
variable "kv_name"         { type = string }        
variable "kv_rg_name"      { type = string }          
variable "scim_secret_name"{ type = string }          


variable "account_scim_url" { type = string }

# Grupos AAD que serão sincronizados para a CONTA
variable "aad_group_names" {
  type    = list(string)
  default = [
    "data-platform-engineers",
    "data-consumers",
    "data-analysts"
  ]
}
