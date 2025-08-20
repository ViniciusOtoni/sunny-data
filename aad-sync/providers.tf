provider "azuread" {
  alias         = "admin"
  tenant_id     = var.tenant_id
  client_id     = var.admin_client_id
  client_secret = var.admin_client_secret
}
