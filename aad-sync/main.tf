terraform {
  required_providers {
    azuread = { source = "hashicorp/azuread" }
  }
}

locals {
  groups = toset(var.aad_group_names)
}

# Resolve os grupos que JÁ existem (criados no core-identity)
data "azuread_groups" "by_display_name" {
  display_names = [for g in local.groups : g]
  provider      = azuread.admin
}

# Resolve a SPN dinâmica pelo client_id (pego do KV no workflow)
data "azuread_service_principal" "dynamic_spn" {
  client_id = var.dbx_spn_client_id
  provider  = azuread.admin
}

# Adiciona a SPN a todos os grupos existentes
resource "azuread_group_member" "dynamic_spn_in_groups" {
  for_each         = { for g in data.azuread_groups.by_display_name.groups : lower(g.display_name) => g }
  group_object_id  = each.value.id
  member_object_id = data.azuread_service_principal.dynamic_spn.object_id
  provider         = azuread.admin
}
