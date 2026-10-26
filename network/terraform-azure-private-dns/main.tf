resource "azurerm_private_dns_zone" "this" {
  for_each = var.private_dns

  name                = each.value.name
  resource_group_name = each.value.resource_group_name

  # Zone-specific tags override shared tags with the same key.
  tags = merge(var.tags, each.value.tags)
}