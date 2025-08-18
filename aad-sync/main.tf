locals {
  groups = toset(var.aad_group_names)
}

# 1) Criar/assegurar grupos no Entra ID
resource "azuread_group" "aad_groups" {
  for_each         = local.groups
  display_name     = each.key
  security_enabled = true
  providers        = { azuread = azuread.admin }
}

# 2) Enterprise App “Azure Databricks SCIM Provisioning Connector”
data "azuread_application_template" "dbx_scim" {
  display_name = "Azure Databricks SCIM Provisioning Connector"
  providers    = { azuread = azuread.admin }
}

resource "azuread_application" "scim_app" {
  display_name = "dbx-account-scim"
  template_id  = data.azuread_application_template.dbx_scim.template_id
  feature_tags { enterprise = true, gallery = true }
  providers = { azuread = azuread.admin }
}

resource "azuread_service_principal" "scim_sp" {
  client_id                    = azuread_application.scim_app.client_id
  app_role_assignment_required = false  # permite assignment sem exigência prévia
  providers = { azuread = azuread.admin }
}

# 3) Segredos do job de provisionamento (SCIM BaseAddress + SecretToken)
resource "azuread_synchronization_secret" "scim_creds" {
  service_principal_id = azuread_service_principal.scim_sp.id
  credential { key = "BaseAddress" value = var.account_scim_url }
  credential { key = "SecretToken" value = data.azurerm_key_vault_secret.scim_token.value }
  credential { key = "SyncAll"     value = "false" } # sincroniza só “assigned”
  providers = { azuread = azuread.admin }
}

# 4) Escopo: atribuir grupos ao Enterprise App (role “User”)
resource "azuread_app_role_assignment" "assign_groups" {
  for_each            = azuread_group.aad_groups
  principal_object_id = each.value.object_id
  resource_object_id  = azuread_service_principal.scim_sp.object_id
  app_role_id         = azuread_service_principal.scim_sp.app_role_ids["User"]
  providers           = { azuread = azuread.admin }
  depends_on          = [azuread_synchronization_secret.scim_creds]
}

# 5) Job de sicronização (modelo “databricks”)
resource "azuread_synchronization_job" "scim_job" {
  service_principal_id = azuread_service_principal.scim_sp.id
  template_id          = "databricks"
  enabled              = true
  providers            = { azuread = azuread.admin }
  depends_on           = [azuread_app_role_assignment.assign_groups]
}


