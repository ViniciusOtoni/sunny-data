# Credenciais / IDs    

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "admin_client_id" {
  type        = string
  description = "Client ID da SPN admin (Owner)"
}

variable "admin_client_secret" {
  type        = string
  description = "Client Secret da SPN admin"
  sensitive   = true
}

variable "bootstrap_spn_object_id" {
  type        = string
  description = "Object ID da SPN bootstrap criada manualmente"
}


# Convenções de valores

variable "location" {
  type        = string
  default     = "brazilsouth"
  description = "Região padrão dos recursos"
}

variable "rg_core_name" {
  type        = string
  default     = "rg-medalforge-core"
}

variable "rg_datalake_name" {
  type        = string
  default     = "rg-medalforge-datalake"
}

variable "key_vault_name" {
  type        = string
  default     = "akv-medalforge-rbac-core"
}


# Grupos do Entra ID:

variable "aad_group_names" {
  type    = list(string)
  default = [
    "data-platform-engineers",
    "data-consumers"
  ]
}
