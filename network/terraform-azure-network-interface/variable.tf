variable "network_interfaces" {
  description = "Network interfaces keyed by a stable logical name."
  nullable    = false

  type = map(object({
    name                = string
    location            = string
    resource_group_name = string

    ip_configuration = list(object({
      name                          = string
      subnet_id                     = string
      private_ip_address_allocation = optional(string, "Dynamic")
      private_ip_address            = optional(string)
      public_ip_address_id          = optional(string)
      primary                       = optional(bool, false)
    }))

    dns_servers                    = optional(list(string), [])
    accelerated_networking_enabled = optional(bool, false)
    ip_forwarding_enabled          = optional(bool, false)
    tags                           = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for nic in values(var.network_interfaces) :
      try(length(nic.ip_configuration) > 0, false)
    ])
    error_message = "Each network interface must have at least one IP configuration."
  }

  validation {
    condition = alltrue(flatten([
      for nic in values(var.network_interfaces) : [
        for config in nic.ip_configuration :
        contains(["Dynamic", "Static"], config.private_ip_address_allocation)
      ]
    ]))
    error_message = "Private IP allocation must be either Dynamic or Static."
  }

  validation {
    condition = alltrue(flatten([
      for nic in values(var.network_interfaces) : [
        for config in nic.ip_configuration :
        config.private_ip_address_allocation == "Static" ? (
          try(trimspace(config.private_ip_address) != "", false)
        ) : config.private_ip_address == null
      ]
    ]))
    error_message = "Static allocation requires private_ip_address; Dynamic allocation requires it to be omitted."
  }

  validation {
    condition = alltrue([
      for nic in values(var.network_interfaces) :
      length(nic.ip_configuration) <= 1 ? true : (
        nic.ip_configuration[0].primary &&
        length([
          for config in nic.ip_configuration : config
          if config.primary
        ]) == 1
      )
    ])
    error_message = "When multiple IP configurations are supplied, only the first must have primary = true."
  }
}

variable "tags" {
  type        = map(string)
  description = "Add the tags"
}


