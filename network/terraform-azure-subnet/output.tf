output "subnet_ids" {
  description = "Subnet IDs keyed by the logical identifiers supplied in var.subnet."

  value = {
    for key, subnet in azurerm_subnet.this :
    key => subnet.id
  }
}