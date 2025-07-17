variable "workspace_url" {
  description = "URL da Databricks Workspace"
  type        = string
}

variable "workspace_id" {
  description = "ID da Databricks Workspace"
  type        = string
}

variable "metastore_name" {
  description = "Nome a ser usado no Metastore do Unity Catalog"
  type        = string
}

variable "uc_storage_root" {
  description = "URI ABFSS onde o Unity Catalog guardará os dados gerenciados"
  type        = string
}

variable "uc_storage_credential_name" {
  description = "Nome do Storage Credential a ser usado pelo Unity Catalog"
  type        = string
}

variable "spn_client_id" {
  description = "Client ID da SPN dinâmica"
  type        = string
}

variable "spn_client_secret" {
  description = "Client Secret da SPN dinâmica"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Tenant ID do Azure"
  type        = string
}

variable "bronze_url" {
  description = "URL ABFSS para a camada Bronze"
  type        = string
}

variable "silver_url" {
  description = "URL ABFSS para a camada Silver"
  type        = string
}

variable "gold_url" {
  description = "URL ABFSS para a camada Gold"
  type        = string
}

variable "databricks_account_id" {
  type      = string
  sensitive = true
  description = "ID do account"
}

variable "databricks_region" {
  description = "Região do seu Databricks Account / Unity Catalog (ex: Brazil South)"
  type        = string
}