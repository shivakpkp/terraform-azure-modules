resource "azurerm_virtual_network" "this" {
  for_each = var.virtual_network

  name                = each.value.name
  location            = var.location
  resource_group_name = each.value.resource_group_name
  address_space       = each.value.address_space
  dns_servers         = try (each.value.dns_servers, [])

  tags = merge(var.tags, each.value.tags)
}