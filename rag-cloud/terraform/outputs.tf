output "openai_endpoint" {
    value = azurerm_cognitive_account.openai.endpoint
}
output "openai_primary_key" {
    value = azurerm_cognitive_account.openai.primary_access_key
    sensitive = true
}
output "project_id_debug" {
    value = azurerm_ai_foundry_project.project.id
}