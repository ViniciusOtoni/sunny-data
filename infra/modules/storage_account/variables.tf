variable "resource_group_name" {
  type        = string
  description = "Nome do Resource Group"
}

variable "location" {
  type        = string
  description = "Região do recurso"
}

variable "storage_account_name" {
  type        = string
  description = "Nome do Storage Account"
}

variable "container_name" {
  type        = string
  description = "Nome do container dentro do Storage Account"
}
