# -------------------------------------------------------------------------
# Conta do Cosmos DB
# -------------------------------------------------------------------------
resource "azurerm_cosmosdb_account" "qc" {
  name                = "cosmos-qc-${random_string.sufixo.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB" 

  free_tier_enabled = true

  # A liberação do Firewall agora fica embutida aqui
  public_network_access_enabled = true
  ip_range_filter               = var.meu_ip

  consistency_policy {
    consistency_level       = "Session"
    max_interval_in_seconds = 5
    max_staleness_prefix    = 100
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }

  tags = var.tags
}
