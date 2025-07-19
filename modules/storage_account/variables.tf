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

variable "container_names" {
  type        = list(string)
  description = "Lista de containers a serem criados"
}
