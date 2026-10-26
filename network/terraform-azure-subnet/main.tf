resource "azurerm_subnet" "this" {
  for_each = var.subnet

  name                 = each.value.name
  resource_group_name  = each.value.resource_group_name
  virtual_network_name = each.value.virtual_network_name
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = each.value.delegation == null ? [] : [each.value.delegation]
    iterator = subnet_delegation

    content {
      name = subnet_delegation.value.name

      service_delegation {
        name    = subnet_delegation.value.service_delegation_name
        actions = subnet_delegation.value.actions
      }
    }
  }
}