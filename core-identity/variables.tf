# Credenciais / IDs

variable "subscription_id"         { type = string }
variable "tenant_id"               { type = string }
variable "admin_client_id"         { type = string }
variable "admin_client_secret"     { type = string }
variable "bootstrap_spn_object_id" { type = string }

# Convenções de nomes 

variable "location"         { type = string  default = "brazilsouth" }
variable "rg_core_name"     { type = string  default = "rg-medalforge-core" }
variable "rg_datalake_name" { type = string  default = "rg-medalforge-datalake" }
variable "key_vault_name"   { type = string  default = "akv-medalforge-rbac-core" }

