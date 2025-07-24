# Credenciais 
variable "tenant_id" {
  description = "Tenant ID do Azure"
  type        = string
}

variable "spn_client_id" {
  description = "Client ID da SPN dinâmica (Account Admin)"
  type        = string
}

variable "spn_client_secret" {
  description = "Client Secret da SPN dinâmica"
  type        = string
  sensitive   = true
}


# Databricks configs
variable "databricks_account_id" {
  description = "ID do Databricks Account onde será criado o metastore"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Região do Databricks Account (ex.: brazilsouth)"
  type        = string
  default     = "brazilsouth"
}


