# Azure Windows virtual machines

Reusable Terraform module creating Windows VMs and their OS disks from a map of stable logical keys. Place this folder at `compute/terraform-azure-windows-vm` in your modules repository.

## Requirements

- Terraform >= 1.5; AzureRM >= 4.0 and < 5.0. This package deliberately targets AzureRM 4.x; review and validate before changing the major version.
- Existing resource groups and NICs; use separate networking modules. NICs must be available for attachment and compatible with the VM region, size and networking requirements.
- A supported Windows Marketplace image, VM size and regional quota. Secure Boot and vTPM default to enabled and require a compatible Generation 2 image and VM size. Marketplace images requiring a purchase plan and custom images are outside this module's scope.

## Usage

See `examples/basic/main.tf` for a complete caller accepting an existing resource group and NIC. The provider belongs in the caller, not this module.

After putting the module at the proposed repository path, callers can use:

```hcl
source = "git::https://github.com/shivakpkp/terraform-azure-modules.git//compute/terraform-azure-windows-vm?ref=prod"
```

This path is a proposed location, not a claim that it already exists remotely. For production, replace `prod` with a release tag or commit that actually exists.

Pass your NIC module's ID output into `network_interface_ids`. The first ID is the primary NIC. A direct output reference establishes the dependency automatically; no manual `depends_on` is necessary. The exact output name depends on your NIC module.

## Inputs

| Input | Required | Purpose |
| --- | --- | --- |
| windows_virtual_machines | Yes | Map of VM specifications; see variables.tf |
| admin_passwords | Yes | Sensitive map using the same keys as the VM map |
| tags | No | Shared tags; VM-specific tags override matching keys |

Each VM requires name, computer_name, resource_group_name, location, size, admin_username, network_interface_ids and source_image_reference. Optional settings include zone, license_type, OS disk configuration, security flags and tags.

OS disks default to Premium_LRS with ReadWrite caching and the image's disk size. System-assigned identity, VM agent, automatic Windows OS updates and managed boot diagnostics are enabled. Identity role assignments are managed separately. `license_type` is unset by default; select Azure Hybrid Benefit values only with appropriate license entitlement.

The example uses `latest` for convenience. Pin a tested image version for reproducible production deployments. Review plans when changing image, naming or placement settings because some changes replace VMs. Automatic OS updates are the baseline here; organization-managed update schedules require an intentional module extension.

## Outputs

- virtual_machine_ids: Azure resource IDs by VM key.
- private_ip_addresses: primary private addresses by VM key.
- principal_ids: managed identity principal IDs by VM key.

## Password handling

Supply passwords from protected CI inputs or a secret store. Do not commit secrets in tfvars. `sensitive = true` redacts normal CLI output but the `admin_password` argument still stores the password in Terraform state, including when the input comes from Key Vault. Protect remote state with encryption and tightly scoped access. Passwords are separate from the VM map so sensitive values do not prevent for_each from enumerating VM keys.

## Scope and operation

This module does not create public IPs or RDP rules. Use an existing private access path such as Bastion or VPN. Manage NSGs, data disk attachments, backup, monitoring agents, domain join and RBAC through separate resources/modules as required. One VM is not a high-availability design; multiple instances need application-level redundancy and appropriate placement.

## Validation

Terraform CLI was unavailable in the authoring environment; no provider validation, plan or Azure deployment has been performed. In the caller directory run:

```sh
terraform fmt -recursive
terraform init
terraform validate
terraform plan
```

Review the plan before applying. Use your normal provider lock file and environment-specific security checks.

Reference: https://registry.terraform.io/providers/hashicorp/azurerm/4.51.0/docs/resources/windows_virtual_machine
