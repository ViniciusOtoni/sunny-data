# Credenciais / IDs
variable "subscription_id"     { type = string }
variable "tenant_id"           { type = string }
variable "admin_client_id"     { type = string }

variable "admin_client_secret" { 
    type = string 
    sensitive = true 
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
