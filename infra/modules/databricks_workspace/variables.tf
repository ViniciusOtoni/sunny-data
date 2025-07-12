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
