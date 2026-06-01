# =============================================================================
#  Variables — every value the lab might want to change lives here.
#  Override any of these in terraform.tfvars (copy from terraform.tfvars.example).
# =============================================================================

variable "subscription_id" {
  description = "Azure subscription ID. Leave empty to use ARM_SUBSCRIPTION_ID (exported by .envrc from `az account show`)."
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "Resource group to create the VM and its network into."
  type        = string
  default     = "nitic-june2026"
}

variable "location" {
  description = <<-EOT
    Azure region. NOTE: GPU SKUs are not in every region — verify the chosen
    vm_size is offered here before applying:
      az vm list-skus --location <region> --size Standard_NC --all -o table
    The NCasT4_v3 GPU quota for this lab was granted in North Central US.
  EOT
  type        = string
  default     = "northcentralus"
}

variable "vm_name" {
  description = "Name of the virtual machine (also used as the prefix for vnet/nsg/nic/disks)."
  type        = string
  default     = "uss-nitic"
}

variable "vm_size" {
  description = "Azure VM SKU. Standard_NC4as_T4_v3 is the lab GPU node (4 vCPU, 28GB RAM, 1× NVIDIA Tesla T4 16GB). For a CPU-only VM use e.g. Standard_D4as_v5."
  type        = string
  default     = "Standard_NC4as_T4_v3"
}

variable "admin_username" {
  description = "Admin (SSH) user created on the VM."
  type        = string
  default     = "azureuser"
}

# ── Agent (worker) VM — see agent.tf ────────────────────────────────────────
# A second VM that joins the k3s cluster as an agent. Exists to give student
# workloads CPU/RAM headroom without touching the GPU VM's NCASv3_T4 quota.

variable "agent_vm_name" {
  description = "Name of the k3s agent (worker) VM. Used as the prefix for its NIC/PIP/OS disk."
  type        = string
  default     = "uss-nitic-worker"
}

variable "agent_vm_size" {
  description = <<-EOT
    Azure VM SKU for the k3s agent. Default Standard_D8s_v3 (8 vCPU / 32 GB RAM,
    Intel, ~$0.38/hr North Central US). Draws from the Standard DSv3 Family
    vCPU quota — confirm headroom:
      az vm list-usage --location northcentralus -o json | jq '.[] | select(.localName | test("DSv3"))'
  EOT
  type        = string
  default     = "Standard_D8s_v3"
}

variable "ssh_public_key_path" {
  description = <<-EOT
    Path to the SSH PUBLIC key planted on the VM. Normally set automatically by
    .envrc (TF_VAR_ssh_public_key_path -> ./.ssh/uss-nitic.pub). Only set this
    in terraform.tfvars if you want to override the direnv-managed key.
  EOT
  type        = string
  default     = "~/.ssh/uss-nitic.pub"
}

variable "os_image" {
  description = <<-EOT
    Marketplace image (publisher:offer:sku:version). Default targets Ubuntu
    24.04 LTS, Gen2 — the Gen2 SKU is plain "server" (there is no
    "server-gen2"). 24.04 is used because the NVIDIA driver + container
    toolkit are battle-tested there; 26.04 is too new for reliable GPU
    support. List available SKUs with:
      az vm image list-skus --location northcentralus --publisher Canonical --offer ubuntu-24_04-lts -o table
  EOT
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  default = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB."
  type        = number
  default     = 64
}

variable "os_disk_type" {
  description = "Storage account type for the OS disk (Standard_LRS, StandardSSD_LRS, Premium_LRS)."
  type        = string
  default     = "Premium_LRS"
}

variable "data_disks" {
  description = "Extra managed data disks to create and attach. Empty list = no data disks."
  type = list(object({
    name         = string
    size_gb      = number
    lun          = number
    storage_type = string
    caching      = string
  }))
  default = [
    {
      name         = "data01"
      size_gb      = 256
      lun          = 0
      storage_type = "Premium_LRS"
      caching      = "ReadWrite"
    },
  ]
}

variable "nsg_rules" {
  description = "Inbound NSG allow rules. Defaults cover SSH, HTTP/S, the k3s API, and the Kubernetes NodePort range."
  type = list(object({
    name                   = string
    priority               = number
    destination_port_range = string
    source_address_prefix  = optional(string, "*")
    protocol               = optional(string, "Tcp")
  }))
  default = [
    { name = "SSH", priority = 1001, destination_port_range = "22" },
    { name = "HTTP", priority = 1002, destination_port_range = "80" },
    { name = "HTTPS", priority = 1003, destination_port_range = "443" },
    { name = "k3s-API", priority = 1004, destination_port_range = "6443" },
    { name = "NodePorts", priority = 1005, destination_port_range = "30000-32767" },
  ]
}

variable "install_gpu_driver" {
  description = <<-EOT
    Whether to install the GPU driver via the Azure NvidiaGpuDriverLinux VM
    extension. Default false — and it should stay false: the extension is
    unreliable on Ubuntu 22.04+. The Tesla T4 driver is installed instead by
    scripts/setup-remote-k3s-server.sh during `just bootstrap-server`. Turning
    the extension on would fight that.
  EOT
  type        = bool
  default     = false
}

variable "gpu_driver_extension" {
  description = "VM extension used when install_gpu_driver = true."
  type = object({
    publisher            = string
    type                 = string
    type_handler_version = string
  })
  default = {
    publisher            = "Microsoft.HpcCompute"
    type                 = "NvidiaGpuDriverLinux"
    type_handler_version = "1.9"
  }
}

variable "tags" {
  description = "Tags applied to every resource."
  type        = map(string)
  default = {
    project     = "NITIC-seminar"
    seminar     = "Admiral Bash's Island Adventure"
    environment = "test"
  }
}
