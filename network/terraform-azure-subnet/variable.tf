variable "subnet" {
  description = "Subnets keyed by stable logical identifiers."

  type = map(object({
    name                 = string
    resource_group_name  = string
    virtual_network_name = string
    address_prefixes     = list(string)

    delegation = optional(object({
      name                    = optional(string, "delegation")
      service_delegation_name = string
      actions                 = optional(list(string))
    }))
  }))

  validation {
    condition = alltrue([
      for subnet in values(var.subnet) :
      alltrue([
        for value in [
          subnet.name,
          subnet.resource_group_name,
          subnet.virtual_network_name
        ] : try(length(trimspace(value)) > 0, false)
      ])
    ])

    error_message = "Subnet name, resource group name, and virtual network name must not be empty."
  }

  validation {
    condition = alltrue([
      for subnet in values(var.subnet) :
      try(
        length(subnet.address_prefixes) > 0 &&
        alltrue([
          for prefix in subnet.address_prefixes :
          can(cidrhost(prefix, 0))
        ]),
        false
      )
    ])

    error_message = "Each subnet must have at least one valid IPv4 or IPv6 CIDR prefix."
  }
}