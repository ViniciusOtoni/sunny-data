locals {
  # Extrai o ID numérico do workspace a partir da URL do estado remoto
  workspace_url = data.terraform_remote_state.dbx.outputs.workspace_url
  workspace_id  = tonumber(regex("adb-([0-9]+)", local.workspace_url)[0])

  users = toset(var.workspace_user_groups)
  admins = toset(var.workspace_admin_groups)
}

# Resolve grupos de CONTA (provisionados via SCIM) pelo display_name
data "databricks_group" "account_groups_user" {
  provider     = databricks.account
  for_each     = local.users
  display_name = each.key
}

data "databricks_group" "account_groups_admin" {
  provider     = databricks.account
  for_each     = local.admins
  display_name = each.key
}

# Matricula como USER
resource "databricks_mws_permission_assignment" "ws_users" {
  provider     = databricks.account
  for_each     = data.databricks_group.account_groups_user

  workspace_id = local.workspace_id
  principal_id = each.value.id
  permissions  = ["USER"]
}

# Matricula como ADMIN (se houver)
resource "databricks_mws_permission_assignment" "ws_admins" {
  provider     = databricks.account
  for_each     = data.databricks_group.account_groups_admin

  workspace_id = local.workspace_id
  principal_id = each.value.id
  permissions  = ["ADMIN"]
}
