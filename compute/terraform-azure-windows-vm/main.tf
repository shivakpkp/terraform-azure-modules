resource "azurerm_windows_virtual_machine" "this" {
  for_each = var.windows_virtual_machines

  name                  = each.value.name
  computer_name         = each.value.computer_name
  resource_group_name   = each.value.resource_group_name
  location              = each.value.location
  size                  = each.value.size
  admin_username        = each.value.admin_username
  admin_password        = lookup(var.admin_passwords, each.key, null)
  network_interface_ids = each.value.network_interface_ids
  zone                  = each.value.zone
  license_type          = each.value.license_type

  provision_vm_agent       = true
  patch_mode               = "AutomaticByOS"
  secure_boot_enabled      = each.value.secure_boot_enabled
  vtpm_enabled             = each.value.vtpm_enabled

  os_disk {
    name                 = each.value.os_disk.name
    caching              = each.value.os_disk.caching
    storage_account_type = each.value.os_disk.storage_account_type
    disk_size_gb         = each.value.os_disk.disk_size_gb
  }

  source_image_reference {
    publisher = each.value.source_image_reference.publisher
    offer     = each.value.source_image_reference.offer
    sku       = each.value.source_image_reference.sku
    version   = each.value.source_image_reference.version
  }

  identity {
    type = "SystemAssigned"
  }

  # Empty block enables boot diagnostics with Azure-managed storage.
  boot_diagnostics {}

  tags = merge(var.tags, each.value.tags)

  lifecycle {
    precondition {
      condition     = contains(keys(var.admin_passwords), each.key)
      error_message = "Provide an admin_passwords entry for every VM key."
    }
  }
}
