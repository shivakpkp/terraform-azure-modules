# Azure Private DNS Zone Module

Creates Azure Private DNS zones using a map of configurations. Supports shared tags and optional zone-specific tags.

## Requirements

- Terraform >= 1.3.0
- HashiCorp AzureRM provider configured in the root module
- Existing resource groups for the DNS zones

## Usage

```hcl
module "private_dns" {
  source = "./modules/private-dns"

  private_dns = {
    blob = {
      name                = "privatelink.blob.core.windows.net"
      resource_group_name = "rg-dns-prod"

      tags = {
        Service = "Storage"
      }
    }

    sql = {
      name                = "privatelink.database.windows.net"
      resource_group_name = "rg-dns-prod"
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

Replace `source` with the path to this module.

Keep map keys such as `blob` and `sql` stable because Terraform uses them to identify resource instances in state.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `private_dns` | `map(object)` | Yes | — | DNS zone configurations keyed by stable logical identifiers. |
| `tags` | `map(string)` | No | `{}` | Shared tags applied to all zones. |

Each object in `private_dns` supports:

| Attribute | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | Private DNS zone name. |
| `resource_group_name` | `string` | Yes | — | Name of the existing resource group. |
| `tags` | `map(string)` | No | `{}` | Zone-specific tags. Override shared tags with matching keys. |

Zone names and resource group names must contain at least one non-whitespace character. Azure validates the remaining naming requirements.

## Outputs

| Name | Description |
|------|-------------|
| `private_dns_zone` | Map of created zones containing `id`, `name`, and `resource_group_name`, keyed by the input identifiers. |

### Access a zone ID

```hcl
output "blob_private_dns_zone_id" {
  description = "Resource ID of the Blob Storage private DNS zone."
  value       = module.private_dns.private_dns_zone["blob"].id
}
```

### Access all zones

```hcl
output "private_dns_zones" {
  description = "Details of all private DNS zones created by the module."
  value       = module.private_dns.private_dns_zone
}
```

## Scope

This module creates Private DNS zones only. Manage VNet links, DNS records, and private endpoint DNS zone groups separately.

For Azure Private Link, use the DNS zone name required by the target Azure service.