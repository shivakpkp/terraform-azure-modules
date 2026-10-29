output "network_interface_ids" {
  description = "Network interface IDs keyed by their logical names."

  value = {
    for key, nic in azurerm_network_interface.this :
    key => nic.id
  }
}

output "network_interface_names" {
  description = "Network interface names keyed by their logical names."

  value = {
    for key, nic in azurerm_network_interface.this :
    key => nic.name
  }
}

output "private_ip_addresses" {
  description = "Primary private IP address of each network interface."

  value = {
    for key, nic in azurerm_network_interface.this :
    key => nic.private_ip_address
  }
}

output "all_private_ip_addresses" {
  description = "All private IP addresses for each network interface."

  value = {
    for key, nic in azurerm_network_interface.this :
    key => nic.private_ip_addresses
  }
}