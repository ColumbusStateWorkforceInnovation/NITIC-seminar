# =============================================================================
#  uss-nitic-worker — CPU-only k3s agent node
# =============================================================================
#  Why this exists:
#    The GPU server VM (azurerm_linux_virtual_machine.nitic, Standard_NC4as_T4_v3)
#    is at 85%+ CPU reservation with baseline tools alone, and the NCASv3_T4
#    quota is maxed at 4 vCPU — same-family resize would need a manual GPU quota
#    bump that can take days. Instead, attach a second CPU-only VM as a k3s
#    AGENT so student workloads schedule there while the T4 stays dedicated to
#    Ollama. Same RG, same vnet/subnet, same NSG — only the VM, NIC, and PIP
#    are new. Draws from non-GPU vCPU quota (DSv3 family).
#
#  After `tofu apply`:
#    just bootstrap-agent      # installs k3s agent and joins the cluster
# =============================================================================

resource "azurerm_public_ip" "agent" {
  name                = "${var.agent_vm_name}-pip"
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "agent" {
  name                = "${var.agent_vm_name}-nic"
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nitic.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.agent.id
  }
}

resource "azurerm_linux_virtual_machine" "agent" {
  name                  = var.agent_vm_name
  resource_group_name   = azurerm_resource_group.nitic.name
  location              = azurerm_resource_group.nitic.location
  size                  = var.agent_vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.agent.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "${var.agent_vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    # Worker OS disk doubles as the local-path PV root (/var/lib/rancher) for
    # any student PVCs that land here. 128 GB is enough for a 4-day seminar
    # with ~13 students; bump if you add JupyterLab or other fat images.
    disk_size_gb = 128
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }
}
