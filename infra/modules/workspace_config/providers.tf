provider "databricks" {
  alias                       = "spn"
  azure_workspace_resource_id = var.workspace_id
  azure_client_id             = var.spn_client_id
  azure_client_secret         = var.spn_client_secret
  azure_tenant_id             = var.tenant_id
}

provider "databricks" {
  alias = "account"

  host  = "https://accounts.azuredatabricks.net"
  account_id = var.databricks_account_id

  client_id     = var.spn_client_id
  client_secret = var.spn_client_secret
  azure_tenant_id = var.tenant_id
}