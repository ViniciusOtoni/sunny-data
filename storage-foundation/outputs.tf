output "access_connector_id" {
  value = azurerm_databricks_access_connector.uc.id
}

output "storage_lake_name" {
  value = module.storage_lake.storage_account_name
}

output "storage_uc_name" {
  value = module.storage_uc.storage_account_name
}

output "rg_datalake_name" {
  value = local.rg_datalake
}
