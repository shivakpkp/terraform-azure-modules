variable "virtual_network" {
  description = "Virtual networks indexed by stable logical keys."

  type = map(object({
    name                = string
    resource_group_name = string
    address_space       = list(string)
    dns_servers         = optional(list(string), [])
    tags                = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for vnet in values(var.virtual_network) :
      try(
        trimspace(vnet.name) != "" &&
        trimspace(vnet.resource_group_name) != "",
        false
      )
    ])

    error_message = "Each virtual network must have a non-empty name and resource_group_name."
  }

  validation {
    condition = alltrue([
      for vnet in values(var.virtual_network) :
      try(
        length(vnet.address_space) > 0 &&
        alltrue([
          for cidr in vnet.address_space :
          can(cidrhost(cidr, 0))
        ]),
        false
      )
    ])

    error_message = "Each virtual network must have at least one valid CIDR address range."
  }
}

variable "location" {
  description = "Azure region for the virtual networks."
  type        = string
}

variable "tags" {
  description = "Shared tags applied to all virtual networks."
  type        = map(string)
  default     = {}
}