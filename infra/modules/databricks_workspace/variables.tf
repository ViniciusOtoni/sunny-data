# Dados da workspace
variable "workspace_name" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

# Unity Catalog
variable "uc_storage_root" {
  type = string
}

variable "uc_storage_credential_name" {
  type = string
}

variable "storage_account_id" {
  type = string
}

# SPN
variable "spn_client_id" {
  type = string
}

variable "spn_client_secret" {
  type      = string
  sensitive = true
}

variable "tenant_id" {
  type = string
}
