resource "azurerm_network_interface" "this" {
  for_each = var.network_interfaces

  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  location            = each.value.location

  dns_servers                    = each.value.dns_servers
  accelerated_networking_enabled = each.value.accelerated_networking_enabled
  ip_forwarding_enabled          = each.value.ip_forwarding_enabled

  dynamic "ip_configuration" {
    for_each = each.value.ip_configuration
    iterator = ipc

    content {
      name                          = ipc.value.name
      subnet_id                     = ipc.value.subnet_id
      private_ip_address_allocation = ipc.value.private_ip_address_allocation
      private_ip_address            = ipc.value.private_ip_address
      public_ip_address_id          = ipc.value.public_ip_address_id
      primary                       = ipc.value.primary
    }
  }

  tags = var.tags
}