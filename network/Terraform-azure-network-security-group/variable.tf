variable "network_security_group" {
  description = "Network security groups keyed by stable logical identifiers."

  type = map(object({
    name           = string
    location       = string
    resource_group = string
    tags           = optional(map(string), {})

    security_rule = optional(map(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), {})
  }))


  validation {
    condition = alltrue(flatten([
      for nsg in values(var.network_security_group) : [
        for rule in values(nsg.security_rule) :
        rule.priority >= 100 &&
        rule.priority <= 4096 &&
        floor(rule.priority) == rule.priority
      ]
    ]))

    error_message = "Security rule priorities must be whole numbers between 100 and 4096."
  }

  validation {
    condition = alltrue(flatten([
      for nsg in values(var.network_security_group) : [
        for rule in values(nsg.security_rule) :
        contains(["Inbound", "Outbound"], rule.direction)
      ]
    ]))

    error_message = "Security rule direction must be Inbound or Outbound."
  }

  validation {
    condition = alltrue(flatten([
      for nsg in values(var.network_security_group) : [
        for rule in values(nsg.security_rule) :
        contains(["Allow", "Deny"], rule.access)
      ]
    ]))

    error_message = "Security rule access must be Allow or Deny."
  }

  validation {
    condition = alltrue([
      for nsg in values(var.network_security_group) :
      length(distinct([
        for rule in values(nsg.security_rule) :
        "${rule.direction}:${rule.priority}"
      ])) == length(nsg.security_rule)
    ])

    error_message = "Security rule priorities must be unique within each direction in each NSG."
  }

  validation {
    condition = alltrue([
      for nsg in values(var.network_security_group) :
      length(distinct([
        for rule in values(nsg.security_rule) : rule.name
      ])) == length(nsg.security_rule)
    ])

    error_message = "Security rule names must be unique within each NSG."
  }
}

variable "tags" {
  description = "Common tags applied to all network security groups."
  type        = map(string)
  default     = {}
}