provider "databricks" {
  alias                       = "spn"
  azure_workspace_resource_id = var.workspace_id
  azure_client_id             = var.spn_client_id
  azure_client_secret         = var.spn_client_secret
  azure_tenant_id             = var.tenant_id
}