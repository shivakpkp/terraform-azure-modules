# Azure Subnet Module

Creates Azure subnets in existing virtual networks, with an optional service delegation for each subnet.

## Requirements

- Terraform >= 1.3.0 for optional object attributes.
- AzureRM provider configured in the calling root module.
- Existing resource groups and virtual networks.

## Usage

```hcl
module "subnet" {
  source = "git::https://github.com/shivakpkp/terraform-azure-modules.git//network/terraform-azure-subnet?ref=prod"

  subnet = {
    web = {
      name                 = "snet-web-dev"
      resource_group_name  = "rg-network-dev"
      virtual_network_name = "vnet-app-dev"
      address_prefixes     = ["10.20.1.0/24"]
    }

    app_service = {
      name                 = "snet-app-service-dev"
      resource_group_name  = "rg-network-dev"
      virtual_network_name = "vnet-app-dev"
      address_prefixes     = ["10.20.2.0/24"]

      delegation = {
        name                    = "app-service"
        service_delegation_name = "Microsoft.Web/serverFarms"
        actions                 = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
  }
}
```

The source uses the repository's `prod` branch. For reproducible deployments, replace `prod` with an existing release tag or full commit SHA.

If another module creates the VNet in the same configuration, pass its output as `virtual_network_name` so Terraform can infer the dependency.

## Inputs

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `subnet` | `map(object)` | Yes | Subnets keyed by stable logical identifiers. |

Each subnet supports:

| Attribute | Type | Required | Default |
| --- | --- | --- | --- |
| `name` | `string` | Yes | — |
| `resource_group_name` | `string` | Yes | — |
| `virtual_network_name` | `string` | Yes | — |
| `address_prefixes` | `list(string)` | Yes | — |
| `delegation` | `object` | No | `null` |

The optional delegation object supports:

| Attribute | Type | Required | Default |
| --- | --- | --- | --- |
| `name` | `string` | No | `"delegation"` |
| `service_delegation_name` | `string` | Yes | — |
| `actions` | `list(string)` | No | `null` |

This module accepts one delegation object per subnet. Omit it to create a subnet without a delegation. Choose a service and actions supported by Azure and your AzureRM provider version.

## Outputs

| Name | Type | Description |
| --- | --- | --- |
| `subnet_ids` | `map(string)` | Subnet IDs keyed by the input logical identifiers. |

```hcl
output "web_subnet_id" {
  value = module.subnet.subnet_ids["web"]
}
```

## Validation and scope

- Subnet, resource group, and virtual network names must contain non-whitespace characters.
- Each subnet must contain at least one valid IPv4 or IPv6 CIDR prefix.
- Validation does not check prefix overlap or whether prefixes fit inside the VNet address space.
- Keep map keys stable because they form part of the Terraform resource addresses.
- NSG associations, route table associations, service endpoints, and private endpoint policy settings are not managed by this module.
