locals {
    llm_capacity = 1
    embedding_capacity = 1
}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

# Azure AI Search (Cognitive Search)
resource "azurerm_search_service" "search" {
  name                = var.search_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "free"
}

# Azure OpenAI (Cognitive Services account, kind=OpenAI)
resource "azurerm_cognitive_account" "openai" {
  name                = var.ai_services_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  kind                = "OpenAI"
  sku_name            = "S0"

  # To let Terraform read primary/secondary access keys as outputs:
  local_auth_enabled  = true

  custom_subdomain_name = var.ai_services_name

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "llm" {
  name                 = var.llm_deployment_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.llm_deployment_name
    version = var.llm_model_version
  }

  sku {
    name = "GlobalStandard"
    capacity = local.llm_capacity
  }
}

# OpenAI deployments (Embeddings)
resource "azurerm_cognitive_deployment" "embeddings" {
  name                 = var.embedding_name
  cognitive_account_id = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = var.embedding_name
    version = var.embedding_version
  }

  sku {
    name = "Standard"
    capacity = local.embedding_capacity
  }
}

# Azure AI Foundry (Hub + Project)
data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "keyvault" {
  name                = "ragkeyvault04"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name                 = "standard"
  purge_protection_enabled = false # can purge, true: cannot purge
}

resource "azurerm_key_vault_access_policy" "kv_policy" {
  key_vault_id = azurerm_key_vault.keyvault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Get",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}

resource "azurerm_storage_account" "storageaccount" {
  name                     = "ragsa04"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_ai_foundry" "hub" {
  name                = var.hub_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  storage_account_id  = azurerm_storage_account.storageaccount.id
  key_vault_id        = azurerm_key_vault.keyvault.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_ai_foundry_project" "project" {
  name               = var.project_name
  location           = azurerm_ai_foundry.hub.location
  ai_services_hub_id = azurerm_ai_foundry.hub.id

  identity { type = "SystemAssigned" }
}

### Connect hub/project to cognitive services (OpenAI)
## Create azure ai services instance to connect above cognitive models (chat, embedding) to hub/project
## -- AI Services connector (the "bridge" used by Hub/Project) --
## Use this one with Microsoft.CognitiveServices provider only,
## don't need it if using Microsoft.MachineLearningServices

# resource "azurerm_ai_services" "connector" {
#   name                = var.ai_services_connector_name
#   location            = azurerm_resource_group.rg.location
#   resource_group_name = azurerm_resource_group.rg.name
#   sku_name = "S0"
#   identity { type = "SystemAssigned" }
# }

## -- Project → OpenAI connection --
## Link: https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/projects/connections?pivots=deployment-language-terraform
## https://blog.timja.dev/azure-ai-studio-with-terraform/

resource "azapi_resource" "openai_connection" {
  type      = "Microsoft.MachineLearningServices/workspaces/connections@2025-09-01"
  name      = "openai-connection"
  parent_id = azurerm_ai_foundry.hub.id

  body = {
    properties = {
      category = "AzureOpenAI"
      target   = azurerm_cognitive_account.openai.endpoint
      authType = "ApiKey" 
      credentials    = {
        key = azurerm_cognitive_account.openai.primary_access_key
      }
      metadata = {
        ApiType    = "AzureOpenAI"
        ResourceId = azurerm_cognitive_account.openai.id
      }
    }
  }
}

## Create the .env file
## Check endpoint: tf state show azurerm_search_service.search
resource "local_file" "dotenv" {
  filename = "../.env"
  content  = <<-EOT
    AZURE_OPENAI_ENDPOINT=${azurerm_cognitive_account.openai.endpoint}
    AZURE_OPENAI_API_KEY=${azurerm_cognitive_account.openai.primary_access_key}
    AZURE_OPENAI_CHAT_COMPLETIONS_DEPLOYMENT_NAME="${var.llm_deployment_name}"

    AZURE_OPENAI_EMBEDDING_MODEL=${var.embedding_name}
    EMBEDDING_VECTOR_DIMENSIONS=3072

    AZURE_SEARCH_SERVICE_ENDPOINT=${"https://${var.search_name}.search.windows.net"}
    AZURE_SEARCH_SERVICE_ADMIN_KEY=${azurerm_search_service.search.primary_key}
    SEARCH_INDEX_NAME=index-doc
  EOT
}