# -------------------------------------------------------------------------
# Servidor SQL (Azure SQL Logical Server)
# -------------------------------------------------------------------------
resource "azurerm_mssql_server" "sql" {
  name                         = "sql-qc-${random_string.sufixo.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "qcadmin"
  administrator_login_password = var.sql_admin_password
  tags                         = var.tags
}

# -------------------------------------------------------------------------
# Banco de Dados (Azure SQL Database)
# -------------------------------------------------------------------------
resource "azurerm_mssql_database" "db" {
  name           = "sqldb-qc"
  server_id      = azurerm_mssql_server.sql.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  max_size_gb    = 2
  sku_name       = "Basic" # Tier mais barato para o laboratório
  zone_redundant = false
  tags           = var.tags
}

# -------------------------------------------------------------------------
# Regras de Firewall (Segurança)
# -------------------------------------------------------------------------

# Permite que outros serviços do Azure (como o Synapse ou Azure Functions) acessem o banco
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Libera o seu IP público para que você consiga conectar via DBeaver/SSMS
resource "azurerm_mssql_firewall_rule" "allow_meu_ip" {
  name             = "AllowMeuIP"
  server_id        = azurerm_mssql_server.sql.id
  start_ip_address = var.meu_ip
  end_ip_address   = var.meu_ip
}