variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
  sensitive   = true
}

variable "admin_client_id" {
  description = "Client ID da conta admin"
  type        = string
  sensitive   = true
}

variable "admin_client_secret" {
  description = "Client Secret da conta admin"
  type        = string
  sensitive   = true
}

variable "spn_client_id" {
  type    = string
  default = ""
}

variable "spn_client_secret" {
  type      = string
  default   = ""
}
