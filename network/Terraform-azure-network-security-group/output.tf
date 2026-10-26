output "network_security_group_ids" {
  description = "Network security group IDs keyed by their logical identifiers."

  value = {
    for key, nsg in azurerm_network_security_group.this :
    key => nsg.id
  }
}

output "network_security_group_names" {
  description = "Network security group names keyed by their logical identifiers."

  value = {
    for key, nsg in azurerm_network_security_group.this :
    key => nsg.name
  }
}