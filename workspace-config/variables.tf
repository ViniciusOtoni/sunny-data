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
  default     = brazilsouth
}

variable "workspace_url" {
  description = "URL da Databricks Workspace (ex.: https://adb-xxxx.azuredatabricks.net)"
  type        = string
}


# Unity Catalog
variable "metastore_name" {
  description = "Nome do Metastore a ser criado"
  type        = string
}

variable "uc_storage_root" {
  description = "Caminho ABFSS raiz onde o Metastore guardará dados gerenciados"
  type        = string
}

variable "uc_storage_credential_name" {
  description = "Nome do Storage Credential que aponta para o Access Connector"
  type        = string
}

variable "azure_managed_identity_id" {
  description = "Resource ID do Databricks Access Connector (Managed Identity)"
  type        = string
}

# External Locations
variable "raw_url"    { description = "ABFSS da camada Raw"    type = string }
variable "bronze_url" { description = "ABFSS da camada Bronze" type = string }
variable "silver_url" { description = "ABFSS da camada Silver" type = string }
variable "gold_url"   { description = "ABFSS da camada Gold"   type = string }

