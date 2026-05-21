# =============================================================================
#  uss-nitic — Azure test VM for "Admiral Bash's Island Adventure"
# -----------------------------------------------------------------------------
#  Quick start:
#    1. cp terraform.tfvars.example terraform.tfvars   # then edit as needed
#    2. az login                                       # authenticate the CLI
#    3. direnv allow                                   # forges the SSH key,
#                                                      #   exports ARM_SUBSCRIPTION_ID
#    4. tofu init
#    5. tofu plan
#    6. tofu apply
#
#  This stack is run with OpenTofu (`tofu`). The block below is still named
#  `terraform {}` — OpenTofu keeps that name for compatibility, so leave it.
#
#  Everything that varies between runs/people lives in variables.tf and is
#  overridable via terraform.tfvars — this config is meant to be portable.
# =============================================================================

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  # Authenticates via the Azure CLI — run `az login` first.
  # subscription_id is taken from the ARM_SUBSCRIPTION_ID env var (exported by
  # .envrc) unless var.subscription_id is set explicitly in terraform.tfvars.
  subscription_id = var.subscription_id != "" ? var.subscription_id : null

  features {}
}
