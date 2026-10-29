# Azure Network Interface Terraform Module

Creates Azure network interfaces from a map of specifications. Each NIC can have one or more IP configurations, optional public IP associations, custom DNS servers, and configurable forwarding and accelerated networking.

NICs are indexed by the logical keys in `network_interfaces`, so callers can reference their IDs when creating virtual machines.

## Scope

This module manages `azurerm_network_interface` resources. Resource groups, virtual networks, subnets, public IP resources, network security groups, and virtual machines are managed separately. Supply existing subnet and public IP resource IDs or reference outputs from other modules.

## Requirements

- Terraform 1.3 or later for optional object attributes with defaults.
- The `hashicorp/azurerm` provider, configured and authenticated in the root module. Select a version supporting the arguments used by this module and declare version constraints in `versions.tf`.
- An existing resource group and subnet, with permissions to create and connect network interfaces.

## Usage

The example assumes the module is stored at `./modules/network-interface`. Adjust `source` to your actual module location. `var.app_subnet_id` is an input declared in the calling root module.

```hcl
module "network_interfaces" {
  source = "./modules/network-interface"

  network_interfaces = {
    app = {
      name                = "nic-app-dev-001"
      location            = "canadacentral"
      resource_group_name = "rg-app-dev"

      ip_configuration = [
        {
          name      = "internal"
          subnet_id = var.app_subnet_id
          primary   = true
        }
      ]
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

Private IP allocation defaults to `Dynamic`. This example does not associate a public IP.

### Multiple IP configurations

Replace the example NIC's `ip_configuration` list with the following to request two static private addresses. The addresses are illustrative: choose available addresses within your subnet, excluding Azure-reserved addresses.

```hcl
ip_configuration = [
  {
    name                          = "primary"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.10"
    primary                       = true
  },
  {
    name                          = "secondary"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.20.1.11"
  }
]
```

### Associate a public IP

Add `public_ip_address_id` to the relevant IP configuration, using an ID from a separately managed public IP:

```hcl
public_ip_address_id = azurerm_public_ip.app.id
```

This field accepts a resource ID, not a literal IP address. Public IP association does not configure NSG rules or guest firewall rules.

### Reference a NIC from a VM

Inside your virtual machine resource:

```hcl
network_interface_ids = [
  module.network_interfaces.network_interface_ids["app"]
]
```

`app` is the input map key, not the NIC's Azure resource name. Keep map keys stable: changing a key changes the resource's Terraform address and may cause replacement unless state is migrated.

## Inputs

| Name | Type | Required | Description |
| --- | --- | --- | --- |
| `network_interfaces` | `map(object(...))` | Yes | NIC definitions keyed by stable logical names. |
| `tags` | `map(string)` | Depends on its variable declaration | Shared tags assigned to every NIC. Examples explicitly supply this input. |

### Network interface attributes

| Attribute | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | `string` | Yes | — | Azure NIC name. |
| `location` | `string` | Yes | — | Azure region. |
| `resource_group_name` | `string` | Yes | — | Existing resource group name. |
| `ip_configuration` | `list(object(...))` | Yes | — | At least one IP configuration. |
| `dns_servers` | `list(string)` | No | `[]` | Custom DNS servers; an empty list uses the virtual network DNS settings. |
| `accelerated_networking_enabled` | `bool` | No | `false` | Enables accelerated networking; verify VM size and operating system support. |
| `ip_forwarding_enabled` | `bool` | No | `false` | Enables NIC-level IP forwarding. Guest operating system forwarding must be configured separately when needed. |

The resource implementation uses `tags = var.tags`. Any per-NIC `tags` attribute in the input object is currently ignored; it is not merged with shared tags.

### IP configuration attributes

| Attribute | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | `string` | Yes | — | Configuration name, unique within the NIC. |
| `subnet_id` | `string` | Yes | — | Target subnet resource ID. |
| `private_ip_address_allocation` | `string` | No | `"Dynamic"` | `Dynamic` or `Static`. |
| `private_ip_address` | `string` | For static allocation | `null` | Requested static private IP; omit for dynamic allocation. |
| `public_ip_address_id` | `string` | No | `null` | Resource ID of a separately managed public IP. |
| `primary` | `bool` | No | `false` | Marks the primary IP configuration. |

With multiple configurations, set `primary = true` on the first entry and leave the others false. A list preserves the intended configuration order. Setting it explicitly for a single configuration also makes the intent clear.

## Outputs

These outputs correspond to the module's `outputs.tf` definitions.

| Name | Type | Description |
| --- | --- | --- |
| `network_interface_ids` | `map(string)` | NIC resource IDs keyed by input map keys. |
| `network_interface_names` | `map(string)` | Azure NIC names keyed by input map keys. |
| `private_ip_addresses` | `map(string)` | Primary private IP for each NIC. |
| `all_private_ip_addresses` | `map(list(string))` | All private IPs for each NIC. |

Dynamically allocated addresses may remain unknown until apply.

## Validation and deployment

Run from the calling root module:

```shell
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Review the plan before running `terraform apply`. Validation checks configuration structure; a successful deployment also depends on Azure permissions, subnet capacity, address availability, and resource compatibility.

## References

- [AzureRM network interface resource](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface)
- [Terraform dynamic blocks](https://developer.hashicorp.com/terraform/language/expressions/dynamic-blocks)
- [Terraform module sources](https://developer.hashicorp.com/terraform/language/modules/sources)
