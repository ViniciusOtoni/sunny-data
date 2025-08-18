output "workspace_id" {
  value = local.workspace_id
}

output "assigned_users" {
  value = [for k, g in data.databricks_group.account_groups_user : g.display_name]
}

output "assigned_admins" {
  value = [for k, g in data.databricks_group.account_groups_admin : g.display_name]
}
