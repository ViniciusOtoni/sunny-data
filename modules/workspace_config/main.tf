# extrai o ID numérico do workspace
locals {
  # pega a primeira sequência de dígitos depois de "adb-"
  workspace_id_numeric = tonumber(regex("adb-([0-9]+)", var.workspace_url)[0])
}

# Delay artificial para Sync de role "account_admin"
resource "null_resource" "sync_account_admin" {

  provisioner "local-exec" {
    command = "echo 'Esperando sync da role de account admin...' && sleep 200"
  }
}

# Criar Metastore no Databricks
resource "databricks_metastore" "uc" {
  provider     = databricks.account
  name         = var.metastore_name
  storage_root = var.uc_storage_root
  region       = var.databricks_region

  depends_on = [
    null_resource.sync_account_admin,
  ]
}

# Attach ao workspace o metastore
resource "databricks_metastore_assignment" "attach" {
  provider     = databricks.spn
  workspace_id = local.workspace_id_numeric
  metastore_id = databricks_metastore.uc.id
}

resource "null_resource" "wait_for_assignment" {
  depends_on = [databricks_metastore_assignment.attach]
}



# Storage Credential 
resource "databricks_storage_credential" "uc" {
  provider = databricks.account
  name     = var.uc_storage_credential_name

   
  azure_managed_identity {
    access_connector_id = var.azure_managed_identity_id
  }

  depends_on = [
    null_resource.wait_for_assignment,
  ]
}

# Delay artificial após a criação do Storage Credential
resource "null_resource" "wait_for_credential" {
  depends_on = [databricks_storage_credential.uc]

  provisioner "local-exec" {
    command = "echo 'Esperando propagação do Storage Credential...' && sleep 120"
  }
}

# External locations
resource "databricks_external_location" "raw" {
  provider        = databricks.account
  name            = "raw"
  url             = var.raw_url
  credential_name = databricks_storage_credential.uc.name


  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "bronze" {
  provider        = databricks.account
  name            = "bronze"
  url             = var.bronze_url
  credential_name = databricks_storage_credential.uc.name
  

  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "silver" {
  provider        = databricks.account
  name            = "silver"
  url             = var.silver_url
  credential_name = databricks_storage_credential.uc.name
 

  depends_on = [null_resource.wait_for_credential]
}

resource "databricks_external_location" "gold" {
  provider        = databricks.account
  name            = "gold"
  url             = var.gold_url
  credential_name = databricks_storage_credential.uc.name


  depends_on = [null_resource.wait_for_credential]
}

# Criação dos Grupos de Acesso:

resource "databricks_group" "platform_engineers" {
  provider = databricks.spn
  display_name = "data-platform-engineers"
}
resource "databricks_group" "consumers" {
  provider = databricks.spn
  display_name = "data-consumers"
}

# Catálogos

resource "databricks_catalog" "bronze" {
  provider = databricks.spn
  name        = "bronze"
  comment     = "Camada Bronze"
  isolation_mode = "OPEN" # ou ISOLATED, se quiser mais rígido
}

resource "databricks_catalog" "silver" {
  provider = databricks.spn
  name        = "silver"
  comment     = "Camada Silver"
  isolation_mode = "OPEN"
}

resource "databricks_catalog" "monitoring" {
  provider = databricks.spn
  name        = "monitoring"
  comment     = "Telemetria e observabilidade do lake"
  isolation_mode = "OPEN"
}

# GRANTS

resource "databricks_grants" "bronze" {
  provider = databricks.spn
  catalog = databricks_catalog.bronze.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE", "READ_VOLUME", "WRITE_VOLUME"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG"] # sem SELECT por padrão na bronze
  }
}

resource "databricks_grants" "silver" {
  provider = databricks.spn
  catalog = databricks_catalog.silver.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE", "READ_VOLUME", "WRITE_VOLUME"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}

resource "databricks_grants" "monitoring" {
  provider = databricks.spn
  catalog = databricks_catalog.monitoring.name
  grant {
    principal  = databricks_group.platform_engineers.display_name
    privileges = ["USE_CATALOG", "CREATE"]
  }
  grant {
    principal  = databricks_group.consumers.display_name
    privileges = ["USE_CATALOG", "SELECT"]
  }
}


# Criação Warehouse:

resource "databricks_sql_endpoint" "serverless_wh" {
  provider                  = databricks.spn
  name                      = "wh_serverless_explore"
  cluster_size              = "2X-Small"
  auto_stop_mins            = 15
  enable_serverless_compute = true     

}

# Permissões no warehouse
resource "databricks_permissions" "wh_perms" {

  provider = databricks.spn
  sql_endpoint_id = databricks_sql_endpoint.serverless_wh.id

  access_control {
    group_name       = databricks_group.platform_engineers.display_name
    permission_level = "CAN_MANAGE"
  }
  access_control {
    group_name       = databricks_group.consumers.display_name
    permission_level = "CAN_USE"
  }
}
