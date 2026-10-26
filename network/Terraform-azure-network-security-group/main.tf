resource "azurerm_network_security_group" "this" {
  for_each = var.network_security_group

  name                = each.value.name
  location            = each.value.location
  resource_group_name = each.value.resource_group

  dynamic "security_rule" {
    for_each = each.value.security_rule
    iterator = s_rule

    content {
      name                       = s_rule.value.name
      priority                   = s_rule.value.priority
      direction                  = s_rule.value.direction
      access                     = s_rule.value.access
      protocol                   = s_rule.value.protocol
      source_port_range          = s_rule.value.source_port_range
      destination_port_range     = s_rule.value.destination_port_range
      source_address_prefix      = s_rule.value.source_address_prefix
      destination_address_prefix = s_rule.value.destination_address_prefix
    }
  }

  tags = merge(var.tags, each.value.tags)
}