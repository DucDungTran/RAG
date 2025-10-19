#!/bin/bash
# Create Azure AI resources

rgName=rg-rag-05
aiSearchName=ai-search-rag-05
aiServiceName=ai-services-rag-05
location=swedencentral
llmDeploymentName=gpt-4.1-nano
llmModelVersion=2025-04-14
embeddingModelName=text-embedding-3-large

# Create a resource group
az group create -n $rgName -l $location

# Create an ai search service
az search service create -n $aiSearchName -g $rgName --sku free

# Create an Azure AI services resource
az cognitiveservices account create -n $aiServiceName -g $rgName --kind OpenAI --sku S0 -l $location --custom-domain $aiServiceName

# Check list of OpenAI models that are currently available in the location
# az cognitiveservices account list-models -n $aiServiceName -g $rgName -o table

# Create deployment for ChatGPT model

az cognitiveservices account deployment create -n $aiServiceName -g $rgName \
--deployment-name $llmDeploymentName \
--model-name $llmDeploymentName \
--model-version $llmModelVersion \
--model-format OpenAI \
--sku-capacity "1" \
--sku-name "GlobalStandard"

# # Create an embedding model deployment

az cognitiveservices account deployment create -n $aiServiceName -g $rgName \
--deployment-name $embeddingModelName \
--model-name $embeddingModelName \
--model-version "1" \
--model-format OpenAI \
--sku-capacity "1" \
--sku-name "Standard"

## Create a hub and project
hubName=hub-rag-05
projectName=project-rag-05

az ml workspace create --kind hub -g $rgName -n $hubName

hubID=$(az ml workspace show -g $rgName -n $hubName --query id -o tsv)
az ml workspace create --kind project --hub-id $hubID -g $rgName -n $projectName

## Create a connection.yml file to connect AI Services to the Hub
# Link: https://learn.microsoft.com/en-us/azure/machine-learning/reference-yaml-connection-azure-openai?view=azureml-api-2
endpoint=$(az cognitiveservices account show -n $aiServiceName -g $rgName --query properties.endpoint)
api_key=$(az cognitiveservices account keys list -n $aiServiceName -g $rgName --query key1)
openai_resource_id=$(az cognitiveservices account show -n $aiServiceName -g $rgName --query id)

cat <<EOF > connection.yml
name: ai-service-connection
type: azure_open_ai
azure_endpoint: $endpoint
api_key: $api_key
open_ai_resource_id: $openai_resource_id
EOF

az ml connection create --f connection.yml -g $rgName --workspace-name $hubName

# Create the .env file
cat <<EOF > ../.env
AZURE_OPENAI_ENDPOINT=$endpoint
AZURE_OPENAI_API_KEY=$api_key
AZURE_OPENAI_CHAT_COMPLETIONS_DEPLOYMENT_NAME="$llmDeploymentName"

AZURE_OPENAI_EMBEDDING_MODEL=$embeddingModelName
EMBEDDING_VECTOR_DIMENSIONS=3072

AZURE_SEARCH_SERVICE_ENDPOINT=$(az search service show -n $aiSearchName -g $rgName --query endpoint -o tsv)
AZURE_SEARCH_SERVICE_ADMIN_KEY=$(az search admin-key show -g $rgName --service-name $aiSearchName --query primaryKey -o tsv)
SEARCH_INDEX_NAME=index-doc
EOF