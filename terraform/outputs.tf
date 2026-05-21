# =============================================================================
#  Outputs — printed after `tofu apply`
# =============================================================================

output "vm_name" {
  description = "Name of the deployed VM."
  value       = azurerm_linux_virtual_machine.nitic.name
}

output "resource_group" {
  description = "Resource group the VM lives in."
  value       = azurerm_resource_group.nitic.name
}

output "location" {
  description = "Azure region."
  value       = azurerm_resource_group.nitic.location
}

output "public_ip" {
  description = "Public IP address of the VM."
  value       = azurerm_public_ip.nitic.ip_address
}

output "ssh_command" {
  description = "Ready-to-paste SSH command (uses the direnv-managed private key)."
  value       = "ssh -i ${replace(pathexpand(var.ssh_public_key_path), ".pub", "")} ${var.admin_username}@${azurerm_public_ip.nitic.ip_address}"
}

output "data_disks" {
  description = "Attached data disks (name / size)."
  value       = [for d in azurerm_managed_disk.data : "${d.name} — ${d.disk_size_gb} GB ${d.storage_account_type}"]
}

output "open_ports" {
  description = "Inbound ports opened on the NSG."
  value       = [for r in var.nsg_rules : "${r.name}: ${r.destination_port_range}/${r.protocol}"]
}
