# -------------------------------------------------------------------------
# Capturar dados da assinatura e usuário atual
# -------------------------------------------------------------------------
data "azurerm_client_config" "current" {}

# -------------------------------------------------------------------------
# Cofre de Senhas (Azure Key Vault)
# -------------------------------------------------------------------------
resource "azurerm_key_vault" "kv" {
  name                       = "kv-qc-${random_string.sufixo.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false # Facilita apagar no lab se precisar recriar
  
  # A política de acesso principal que dá permissão total para a 
  # identidade (usuário) que está rodando o Terraform gerenciar as senhas
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions    = ["Get", "List", "Create", "Delete", "Recover", "Backup", "Restore", "Purge"]
    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge"]
  }

  tags = var.tags
}

# -------------------------------------------------------------------------
# Segredos do Key Vault
# -------------------------------------------------------------------------

# Guardando a Connection String do Cosmos DB
resource "azurerm_key_vault_secret" "cosmos_connection" {
  name         = "cosmos-connection-string"
  value        = azurerm_cosmosdb_account.qc.primary_mongodb_connection_string
  key_vault_id = azurerm_key_vault.kv.id
  
  # Garante que o segredo só seja criado depois que a política de acesso estiver pronta
  depends_on = [azurerm_key_vault.kv] 
}

# Guardando a senha do Administrador do SQL
resource "azurerm_key_vault_secret" "sql_admin_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault.kv]
}

# Guardando a Chave de Acesso Primária do Storage
resource "azurerm_key_vault_secret" "storage_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.qc.primary_access_key
  key_vault_id = azurerm_key_vault.kv.id
  depends_on   = [azurerm_key_vault.kv]
}