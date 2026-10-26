variable "private_dns" {
  description = "Values for private dns"
  type = map(object({
    name                = string
    resource_group_name = string
    tags                = optional(map(string))
  }))

  validation {
    condition = alltrue([
      for zone in values(var.private_dns) :
      can(regex("\\S", zone.name))
    ])
    error_message = "Each private DNS zone must have a non-empty name."
  }

  validation {
    condition = alltrue([
      for zone in values(var.private_dns) :
      can(regex("\\S", zone.resource_group_name))
    ])
    error_message = "Each private DNS zone must have a non-empty resource_group_name."
  }
}

variable "tags" {
  description = "Shared tags applied to all private DNS zones. Zone-specific tags take precedence."
  type        = map(string)
  default     = {}
}