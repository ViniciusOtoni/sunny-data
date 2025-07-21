module "workspace_create" {
  source              = "../modules/workspace_create"
  workspace_name      = var.workspace_name
  location            = var.location
  resource_group_name = data.terraform_remote_state.storage.outputs.rg_datalake_name
  access_connector_id = data.terraform_remote_state.storage.outputs.access_connector_id

  providers = {
    azurerm = azurerm.spn   # usa a SPN dinâmica
  }
}
