# -------------------------------------------------------------------------
# Configuração Central do Terraform e Provedores
# -------------------------------------------------------------------------
terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Mantendo uma versão estável 3.x
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# -------------------------------------------------------------------------
# Inicialização do Provedor Azure
# -------------------------------------------------------------------------
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

# -------------------------------------------------------------------------
# Criação do Grupo de Recursos Principal
# -------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# -------------------------------------------------------------------------
# Gerador de Sufixo Aleatório (Essencial para Storage e Key Vault)
# -------------------------------------------------------------------------
resource "random_string" "sufixo" {
  length  = 6
  special = false
  upper   = false
  numeric = true
}