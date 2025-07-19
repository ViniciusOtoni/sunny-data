variable "name" {
  description = "Nome do Key Vault"
  type        = string
}

variable "location" {
  description = "Localização do Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do grupo de recursos onde o Key Vault será criado"
  type        = string
}

variable "tenant_id" {
  description = "ID do tenant do Azure"
  type        = string
}

variable "bootstrap_spn_object_id" {
  description = "Object ID da SPN bootstrap com permissão de acesso inicial ao Key Vault"
  type        = string
}

variable "spn_client_id" {
  description = "Client ID da SPN gerada dinamicamente"
  type        = string
}

variable "spn_client_secret" {
  description = "Client Secret da SPN gerada dinamicamente"
  type        = string
  sensitive   = true
}

