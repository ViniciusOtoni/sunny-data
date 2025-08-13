terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.5"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.0"
    }
  }
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.workspace_name
  location                    = var.location
  resource_group_name         = var.resource_group_name
  sku                         = "premium"
  managed_resource_group_name = "${var.resource_group_name}-databricks-rg"

  access_connector_id = var.access_connector_id
  default_storage_firewall_enabled = false

}


