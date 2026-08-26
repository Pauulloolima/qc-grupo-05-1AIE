# -------------------------------------------------------------------------
# Conta de Armazenamento Principal (Data Lake Gen2)
# -------------------------------------------------------------------------
resource "azurerm_storage_account" "qc" {
  name                     = "stqc${random_string.sufixo.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true # Habilita o Hierarchical Namespace (exigência do Synapse)
  min_tls_version          = "TLS1_2"
  tags                     = var.tags
}

# -------------------------------------------------------------------------
# Containers de Dados (Blob)
# -------------------------------------------------------------------------
resource "azurerm_storage_container" "catalogo" {
  name                  = "catalogo"
  storage_account_name  = azurerm_storage_account.qc.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.qc.name
  container_access_type = "private"
}

# -------------------------------------------------------------------------
# File System para o Synapse Workspace
# -------------------------------------------------------------------------
resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapsefs"
  storage_account_id = azurerm_storage_account.qc.id
}