# -------------------------------------------------------------------------
# Outputs Gerais
# -------------------------------------------------------------------------
output "resource_group_name" {
  description = "Nome do Grupo de Recursos"
  value       = azurerm_resource_group.rg.name
}

# -------------------------------------------------------------------------
# Outputs do Banco Relacional (SQL)
# -------------------------------------------------------------------------
output "sql_server_name" {
  description = "Nome do Servidor SQL"
  value       = azurerm_mssql_server.sql.name
}

output "sql_database_name" {
  description = "Nome do Banco de Dados SQL"
  value       = azurerm_mssql_database.db.name
}

# -------------------------------------------------------------------------
# Outputs do Cosmos DB (NoSQL)
# -------------------------------------------------------------------------
output "cosmos_account_name" {
  description = "Nome da conta do Cosmos DB"
  value       = azurerm_cosmosdb_account.qc.name
}

output "cosmos_endpoint" {
  description = "Endpoint de conexão do Cosmos DB"
  value       = azurerm_cosmosdb_account.qc.endpoint
}

# -------------------------------------------------------------------------
# Outputs do AI Search (Vetor)
# -------------------------------------------------------------------------
output "search_service_name" {
  description = "Nome do serviço do Azure AI Search"
  value       = azurerm_search_service.qc.name
}

output "search_endpoint" {
  description = "URL do endpoint do AI Search"
  value       = "https://${azurerm_search_service.qc.name}.search.windows.net"
}

# -------------------------------------------------------------------------
# Outputs de Armazenamento e Segurança (Storage & Key Vault)
# -------------------------------------------------------------------------
output "storage_account_name" {
  description = "Nome da conta de armazenamento (Data Lake)"
  value       = azurerm_storage_account.qc.name
}

output "key_vault_name" {
  description = "Nome do cofre de senhas"
  value       = azurerm_key_vault.kv.name
}

# -------------------------------------------------------------------------
# Outputs Sensíveis (Senhas não serão exibidas por padrão)
# -------------------------------------------------------------------------
output "storage_account_key" {
  description = "Chave de acesso do Storage"
  value       = azurerm_storage_account.qc.primary_access_key
  sensitive   = true
}

output "mongodb_connection_string" {
  description = "Connection String do Cosmos DB (MongoDB API)"
  value       = azurerm_cosmosdb_account.qc.primary_mongodb_connection_string
  sensitive   = true
}