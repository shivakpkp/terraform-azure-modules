output "virtual_machine_ids" {
  description = "Azure resource IDs keyed by logical VM key."
  value       = { for key, vm in azurerm_windows_virtual_machine.this : key => vm.id }
}

output "private_ip_addresses" {
  description = "Primary private IP addresses keyed by logical VM key."
  value       = { for key, vm in azurerm_windows_virtual_machine.this : key => vm.private_ip_address }
}

output "principal_ids" {
  description = "System-assigned identity principal IDs for role assignments."
  value       = { for key, vm in azurerm_windows_virtual_machine.this : key => vm.identity[0].principal_id }
}
