# Azure Virtual Network Module

Creates Azure virtual networks with address spaces, optional custom DNS servers,
and shared or network-specific tags.

## Requirements

- Terraform >= 1.3.0
- AzureRM provider configured in the calling project
- Existing resource groups for the virtual networks

All networks created by one module call use the same Azure region.

## Usage

```hcl
module "network" {
  source = "git::https://github.com/shivakpkp/terraform-azure-modules.git//network/terraform-azure-vnirtual-network?ref=prod"

  location = "canadacentral"

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }

  virtual_network = {
    application = {
      name                = "vnet-app-dev"
      resource_group_name = "rg-network-dev"
      address_space       = ["10.20.0.0/16"]

      tags = {
        Workload = "application"
      }
    }

    management = {
      name                = "vnet-management-dev"
      resource_group_name = "rg-network-dev"
      address_space       = ["10.30.0.0/16"]
      dns_servers         = ["10.30.1.4", "10.30.1.5"]
    }
  }
}
```

Custom DNS server addresses must point to reachable DNS servers.
This module does not deploy those servers.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `virtual_network` | `map(object)` | Yes | — | Virtual networks indexed by stable logical keys |
| `location` | `string` | Yes | — | Azure region for all networks |
| `tags` | `map(string)` | No | `{}` | Shared tags applied to all networks |

Each entry in `virtual_network` supports:

| Attribute | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `name` | `string` | Yes | — | Virtual network name |
| `resource_group_name` | `string` | Yes | — | Existing resource group name |
| `address_space` | `list(string)` | Yes | — | One or more CIDR address ranges |
| `dns_servers` | `list(string)` | No | `[]` | Custom DNS servers; empty uses Azure-provided DNS |
| `tags` | `map(string)` | No | `{}` | Network-specific tags that override shared tags with the same key |

## Outputs

| Name | Description |
|------|-------------|
| `virtual_networks` | Map containing each network's `id`, `name`, `resource_group_name`, and `address_space`, indexed by the input keys |

Example: retrieve the application network ID.

```hcl
output "application_vnet_id" {
  value = module.network.virtual_networks["application"].id
}
```

## Validation and Behavior

- Network and resource group names must not be empty.
- Each network must have at least one valid CIDR address range.
- CIDR validation does not detect overlapping address spaces.
- Keep map keys stable. Changing a key changes the Terraform resource
  address and requires a state migration to avoid replacement.
- Manage custom DNS through this module only; do not also use a separate
  DNS servers resource for the same network.

## Scope

This module manages virtual networks. Resource groups, subnets, network
security groups, route tables, and peerings are managed separately.