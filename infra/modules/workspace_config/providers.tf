terraform {
  required_providers {
    databricks = {
      source               = "databricks/databricks"
      version              = "~> 1.0"
      configuration_aliases = [
        databricks.spn,
        databricks.account,
      ]
    }
  }
}

# declara os dois aliases que o módulo vai usar
provider "databricks" {
  alias = "spn"
}

provider "databricks" {
  alias = "account"
}
