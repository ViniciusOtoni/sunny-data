module "workspace_config" {
  source = "../modules/workspace_config"

  workspace_url             = data.terraform_remote_state.dbx.outputs.workspace_url
  metastore_name            = "medalforge-catalog"
  uc_storage_root           = "abfss://uc-root@${data.terraform_remote_state.storage.outputs.storage_uc_name}.dfs.core.windows.net/"
  uc_storage_credential_name = "medalforge-uc-cred"

  databricks_account_id     = var.databricks_account_id
  databricks_region         = var.location
  azure_managed_identity_id = data.terraform_remote_state.storage.outputs.access_connector_id

  groups_objects_ids = data.terraform_remote_state.core.outputs.aad_group_object_ids

  raw_url    = "abfss://raw@${data.terraform_remote_state.storage.outputs.storage_lake_name}.dfs.core.windows.net/"
  bronze_url = "abfss://bronze@${data.terraform_remote_state.storage.outputs.storage_lake_name}.dfs.core.windows.net/"
  silver_url = "abfss://silver@${data.terraform_remote_state.storage.outputs.storage_lake_name}.dfs.core.windows.net/"
  gold_url   = "abfss://gold@${data.terraform_remote_state.storage.outputs.storage_lake_name}.dfs.core.windows.net/"

  spn_client_id     = var.spn_client_id
  spn_client_secret = var.spn_client_secret
  tenant_id         = var.tenant_id

  providers = {
    databricks.spn     = databricks.spn
    databricks.account = databricks.account
  }
}
