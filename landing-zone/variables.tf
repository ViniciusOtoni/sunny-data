variable "subscription_id"         { type = string }
variable "tenant_id"               { type = string }
variable "admin_client_id"         { type = string }
variable "admin_client_secret"     { type = string  sensitive = true }

variable "state_sa_name" {
  type        = string
  default     = "stmedalforgestate"
  description = "Storage Account usado como backend remoto de todos os micro-serviços"
}

variable "location" { type = string  default = "brazilsouth" }
