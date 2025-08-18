variable "tenant_id"           { type = string }
variable "spn_client_id"       { type = string }

variable "spn_client_secret"   { 
    type = string 
    sensitive = true 
}

variable "databricks_account_id" { 
    type = string 
    sensitive = true 
}

# Grupos que entram como USER e ADMIN
variable "workspace_user_groups" {
  type    = list(string)
  default = ["data-platform-engineers","data-consumers","data-analysts"]
}

variable "workspace_admin_groups" {
  type    = list(string)
  default = ["data-platform-engineers"] # opcional promover como ADMIN
}
