terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
    }
  }
}

locals {
  groups = toset(var.aad_group_names)
}

# 1) Criar/assegurar grupos no Entra ID
resource "azuread_group" "aad_groups" {
  for_each         = local.groups
  display_name     = each.key
  security_enabled = true
  provider         = azuread.admin
}

# 2) Resolver a SPN dinâmica pelo client_id informado
data "azuread_service_principal" "dynamic_spn" {
  client_id = var.dbx_spn_client_id
  provider  = azuread.admin
}

# 3) Colocar a SPN dinâmica em TODOS os grupos
resource "azuread_group_member" "dynamic_spn_in_groups" {
  for_each         = azuread_group.aad_groups
  group_object_id  = each.value.object_id
  member_object_id = data.azuread_service_principal.dynamic_spn.object_id
  provider         = azuread.admin
}
