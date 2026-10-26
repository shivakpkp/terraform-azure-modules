output "private_dns_zone" {
  value = { for k, dns in azurerm_private_dns_zone.this : k => {
    id   = dns.id,
    name = dns.name
    }
  }
}
