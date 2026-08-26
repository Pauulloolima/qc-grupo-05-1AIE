# -------------------------------------------------------------------------
# Serviço de Busca Cognitiva (Azure AI Search)
# -------------------------------------------------------------------------
resource "azurerm_search_service" "qc" {
  name                = "srch-qc-${random_string.sufixo.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  
  # O tier "basic" é o menor nível que suporta criação de índices vetoriais 
  # sem gerar um custo exorbitante no laboratório.
  sku = "basic" 

  # Permite o uso de chaves de API (Admin Keys) que serão necessárias 
  # para o script Python "indexar_produtos.py" rodar corretamente.
  local_authentication_enabled = true

  tags = var.tags
}