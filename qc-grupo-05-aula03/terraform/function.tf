# Function App em Flex Consumption (Python 3.11) com Managed Identity SystemAssigned.
# Flex Consumption é o sucessor do Linux Consumption (Y1), que será aposentado
# em set/2028. O pacote de deploy é guardado no container 'deployments'.
resource "azurerm_function_app_flex_consumption" "fn" {
  name                = "func-qc-${random_string.sufixo.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.plan.id

  # Storage do pacote de deploy (auth por connection string — sem chicken-and-egg de MI)
  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.func_sa.primary_blob_endpoint}${azurerm_storage_container.deployments.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.func_sa.primary_access_key

  runtime_name           = "python"
  runtime_version        = "3.12"
  instance_memory_in_mb  = 2048
  maximum_instance_count = 40

  site_config {}

  identity {
    type = "SystemAssigned"
  }

  app_settings = {
    "STORAGE_ACCOUNT_CATALOGO"              = azurerm_storage_account.catalogo.name
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string
  }

  tags = local.tags
}

# Permissão para a Managed Identity da Function ler blobs do Storage do catálogo.
# É o que permite a versão v2-blob da Function operar sem credenciais no código.
resource "azurerm_role_assignment" "fn_blob_reader" {
  scope                = azurerm_storage_account.catalogo.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_function_app_flex_consumption.fn.identity[0].principal_id
}

# Workspace do Log Analytics (Requisito para o App Insights moderno)
resource "azurerm_log_analytics_workspace" "law" {
  name                = "law-qc-${random_string.sufixo.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Application Insights
resource "azurerm_application_insights" "appinsights" {
  name                = "appi-qc-${random_string.sufixo.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  workspace_id        = azurerm_log_analytics_workspace.law.id
  application_type    = "web"
}