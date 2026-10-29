variable "windows_virtual_machines" {
  description = "Windows VMs keyed by stable logical identifiers. NICs and resource groups must be supplied separately."
  type = map(object({
    name                  = string
    computer_name         = string
    resource_group_name   = string
    location              = string
    size                  = string
    admin_username        = string
    network_interface_ids = list(string)
    zone                  = optional(string)
    license_type          = optional(string)
    secure_boot_enabled   = optional(bool, true)
    vtpm_enabled          = optional(bool, true)
    tags                  = optional(map(string), {})

    os_disk = optional(object({
      name                 = optional(string)
      caching              = optional(string, "ReadWrite")
      storage_account_type = optional(string, "Premium_LRS")
      disk_size_gb         = optional(number)
    }), {})

    source_image_reference = object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    })
  }))
  nullable = false

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      length(trimspace(vm.name)) > 0 &&
      length(trimspace(vm.resource_group_name)) > 0 &&
      length(trimspace(vm.location)) > 0 &&
      length(trimspace(vm.size)) > 0 &&
      length(trimspace(vm.admin_username)) > 0
    ])
    error_message = "VM name, resource group, location, size and administrator username must not be blank."
  }

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      can(regex("^[A-Za-z0-9][A-Za-z0-9-]{0,14}$", vm.computer_name)) &&
      !can(regex("^[0-9]+$", vm.computer_name))
    ])
    error_message = "Computer names must be 1-15 letters, digits or hyphens, start with a letter or digit, and not be entirely numeric."
  }

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      length(vm.network_interface_ids) > 0 &&
      length(distinct(vm.network_interface_ids)) == length(vm.network_interface_ids)
    ])
    error_message = "Each VM requires at least one NIC ID, without duplicates. The first NIC is primary."
  }

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      contains(["None", "ReadOnly", "ReadWrite"], vm.os_disk.caching) &&
      contains(["Standard_LRS", "StandardSSD_LRS", "Premium_LRS"], vm.os_disk.storage_account_type)
    ])
    error_message = "Use a supported OS disk caching mode and Standard_LRS, StandardSSD_LRS or Premium_LRS storage."
  }

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      vm.os_disk.disk_size_gb == null ? true : (
        vm.os_disk.disk_size_gb >= 1 && vm.os_disk.disk_size_gb <= 4095 &&
        floor(vm.os_disk.disk_size_gb) == vm.os_disk.disk_size_gb
      )
    ])
    error_message = "OS disk size must be an integer from 1 to 4095 GiB, or omitted to use the image size. It must also be at least the source image size."
  }

  validation {
    condition = alltrue([
      for vm in values(var.windows_virtual_machines) :
      vm.license_type == null ? true : contains(["None", "Windows_Client", "Windows_Server"], vm.license_type)
    ])
    error_message = "license_type must be null, None, Windows_Client or Windows_Server."
  }
}

variable "admin_passwords" {
  description = "Administrator passwords keyed by the same logical VM keys. Supply through a secret store or protected CI variables."
  type        = map(string)
  sensitive   = true
  nullable    = false

  validation {
    condition = alltrue([
      for password in values(var.admin_passwords) :
      password == null ? false : length(password) >= 14 && length(password) <= 123
    ])
    error_message = "Administrator passwords must contain 14-123 characters. Azure also enforces complexity and disallowed-password rules."
  }
}

variable "tags" {
  description = "Shared tags. Per-VM tags take precedence."
  type        = map(string)
  default     = {}
  nullable    = false
}
