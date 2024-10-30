# output "client_id" {
#   value = azurerm_user_assigned_identity.terraform.client_id
# }

output "storage_account_name" {
  value = data.azurerm_storage_account.terraform.name
}

output "resource_group_name" {
  value = data.azurerm_resource_group.terraform.name
}

output "subscription_id" {
  value = var.subscription_id
}

output "tenant_id" {
  value = data.azurerm_subscription.terraform.tenant_id
}

output "url_azure" {
  value = "https://portal.azure.com/#@${data.azurerm_subscription.terraform.tenant_id}/resource${data.azurerm_resource_group.terraform.id}"
}

output "url_devops" {
  value = "${local.org_service_url}/_settings/agentpools?poolId=${azuredevops_agent_pool.terraform.id}&view=agents"
}
