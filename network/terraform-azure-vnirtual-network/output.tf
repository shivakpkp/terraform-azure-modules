output "virtual_networks" {
  description = "Virtual network details indexed by the input keys."

  value = {
    for key, vnet in azurerm_virtual_network.this : key => {
      id                  = vnet.id
      name                = vnet.name
      resource_group_name = vnet.resource_group_name
      address_space       = vnet.address_space
    }
  }
}