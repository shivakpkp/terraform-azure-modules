# Azure Network Security Group Module

Creates Azure Network Security Groups (NSGs) with inline security rules, common tags, and per-NSG tags. Multiple NSGs are managed through a map of stable logical identifiers.

## Requirements

- Terraform 1.3 or later for optional object attributes with defaults.
- An AzureRM provider configured in the calling root module.
- Existing resource groups for the NSGs.

## Usage

This example assumes the module is stored at `./modules/network-security-group` relative to your root module. Adjust `source` to its actual location.

```hcl
module "network_security_group" {
  source = "./modules/network-security-group"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  network_security_group = {
    web = {
      name           = "nsg-web-dev"
      location       = "canadacentral"
      resource_group = "rg-network-dev"

      tags = {
        Application = "web"
      }

      security_rule = {
        allow_https = {
          name                       = "Allow-HTTPS"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "10.20.0.0/16"
          destination_address_prefix = "10.30.1.0/24"
        }
      }
    }
  }
}
```

The example allows inbound TCP traffic on port 443 from `10.20.0.0/16` to `10.30.1.0/24`. Adapt these ranges to your network.

## Inputs

| Name | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `network_security_group` | `map(object)` | Yes | — | NSG definitions keyed by logical identifiers, such as `web`. |
| `tags` | `map(string)` | No | `{}` | Common tags applied to all NSGs. |

### Network security group attributes

| Attribute | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | `string` | Yes | — | Azure NSG name. |
| `location` | `string` | Yes | — | Azure region. |
| `resource_group` | `string` | Yes | — | Existing resource group name. |
| `tags` | `map(string)` | No | `{}` | NSG-specific tags; override common tags with matching keys. |
| `security_rule` | `map(object)` | No | `{}` | Inline custom security rules. |

### Security rule attributes

All attributes below are required for each rule.

| Attribute | Type | Description |
| --- | --- | --- |
| `name` | `string` | Rule name, unique within the NSG. |
| `priority` | `number` | Integer from 100 to 4096; lower numbers take precedence. Must be unique within each direction in the NSG. |
| `direction` | `string` | `Inbound` or `Outbound`. |
| `access` | `string` | `Allow` or `Deny`. |
| `protocol` | `string` | Traffic protocol, for example `Tcp`, `Udp`, or `*`. |
| `source_port_range` | `string` | Source port, range, or `*`. |
| `destination_port_range` | `string` | Destination port, range, or `*`. |
| `source_address_prefix` | `string` | Source CIDR, IP address, supported service tag, or `*`. |
| `destination_address_prefix` | `string` | Destination CIDR, IP address, supported service tag, or `*`. |

The variable validations check priority range and integer values, direction, access, duplicate rule names, and duplicate priorities within each direction. This interface uses singular port and address fields; it does not expose lists or application security group IDs.

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `network_security_group_ids` | `map(string)` | NSG IDs keyed by the input logical identifiers. |
| `network_security_group_names` | `map(string)` | NSG names keyed by the input logical identifiers. |

Expose the IDs from your root module:

```hcl
output "network_security_group_ids" {
  value = module.network_security_group.network_security_group_ids
}
```

Reference one NSG using its key:

```hcl
module.network_security_group.network_security_group_ids["web"]
```

## Associate an NSG with a subnet

Associations are managed in the calling configuration. The following example assumes `azurerm_subnet.this["web"]` exists in your root module:

```hcl
resource "azurerm_subnet_network_security_group_association" "web" {
  subnet_id                 = azurerm_subnet.this["web"].id
  network_security_group_id = module.network_security_group.network_security_group_ids["web"]
}
```

## Operational notes

- Keep NSG map keys stable: changing a key changes the Terraform resource address.
- Rules are managed inline. Do not also manage rules for the same NSG with separate `azurerm_network_security_rule` resources.
- Omitting `security_rule` generates no custom rule blocks. Azure default NSG rules still apply; this is not a deny-all configuration.
- Removing all inline rule blocks may not remove previously managed rules because of the provider's inline-rule handling. Review the plan; explicitly clearing rules requires a configuration that sets `security_rule = []`.
- Creating an NSG does not attach it to a subnet or network interface. Create the appropriate association to apply it to traffic.

## References

- [AzureRM network security group documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group)
- [Terraform dynamic blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
