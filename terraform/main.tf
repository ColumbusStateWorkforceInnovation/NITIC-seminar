# =============================================================================
#  uss-nitic — resource group, network, and GPU test VM
# =============================================================================

resource "azurerm_resource_group" "nitic" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# --- Networking --------------------------------------------------------------

resource "azurerm_virtual_network" "nitic" {
  name                = "${var.vm_name}-vnet"
  address_space       = ["10.20.0.0/16"]
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  tags                = var.tags
}

resource "azurerm_subnet" "nitic" {
  name                 = "${var.vm_name}-subnet"
  resource_group_name  = azurerm_resource_group.nitic.name
  virtual_network_name = azurerm_virtual_network.nitic.name
  address_prefixes     = ["10.20.1.0/24"]
}

resource "azurerm_network_security_group" "nitic" {
  name                = "${var.vm_name}-nsg"
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  tags                = var.tags

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = security_rule.value.protocol
      source_port_range          = "*"
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = "*"
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "nitic" {
  subnet_id                 = azurerm_subnet.nitic.id
  network_security_group_id = azurerm_network_security_group.nitic.id
}

resource "azurerm_public_ip" "nitic" {
  name                = "${var.vm_name}-pip"
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "nitic" {
  name                = "${var.vm_name}-nic"
  location            = azurerm_resource_group.nitic.location
  resource_group_name = azurerm_resource_group.nitic.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nitic.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.nitic.id
  }
}

# --- Virtual machine ---------------------------------------------------------

resource "azurerm_linux_virtual_machine" "nitic" {
  name                  = var.vm_name
  resource_group_name   = azurerm_resource_group.nitic.name
  location              = azurerm_resource_group.nitic.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nitic.id]
  tags                  = var.tags

  # SSH key only — password auth stays disabled (the default).
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(pathexpand(var.ssh_public_key_path))
  }

  os_disk {
    name                 = "${var.vm_name}-osdisk"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.os_image.publisher
    offer     = var.os_image.offer
    sku       = var.os_image.sku
    version   = var.os_image.version
  }
}

# --- Data disks --------------------------------------------------------------

resource "azurerm_managed_disk" "data" {
  for_each = { for d in var.data_disks : d.name => d }

  name                 = "${var.vm_name}-${each.value.name}"
  location             = azurerm_resource_group.nitic.location
  resource_group_name  = azurerm_resource_group.nitic.name
  storage_account_type = each.value.storage_type
  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  tags                 = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  for_each = { for d in var.data_disks : d.name => d }

  managed_disk_id    = azurerm_managed_disk.data[each.key].id
  virtual_machine_id = azurerm_linux_virtual_machine.nitic.id
  lun                = each.value.lun
  caching            = each.value.caching
}

# --- Optional GPU driver extension ------------------------------------------
#  Off by default. See var.install_gpu_driver for the AMD-vs-NVIDIA caveat.

resource "azurerm_virtual_machine_extension" "gpu_driver" {
  count = var.install_gpu_driver ? 1 : 0

  name                       = "${var.vm_name}-gpu-driver"
  virtual_machine_id         = azurerm_linux_virtual_machine.nitic.id
  publisher                  = var.gpu_driver_extension.publisher
  type                       = var.gpu_driver_extension.type
  type_handler_version       = var.gpu_driver_extension.type_handler_version
  auto_upgrade_minor_version = true
  tags                       = var.tags
}
