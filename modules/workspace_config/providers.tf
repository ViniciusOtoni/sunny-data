terraform {
  required_providers {
    databricks = {
      source               = "databricks/databricks"
      version              = "~> 1.22"
      configuration_aliases = [
        databricks.spn,
        databricks.account,
      ]
    }
  }
}

