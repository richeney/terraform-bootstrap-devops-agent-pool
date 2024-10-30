resource "azurerm_container_registry" "acr" {
  name                = local.container_registry_name
  resource_group_name = data.azurerm_resource_group.terraform.name
  location            = data.azurerm_resource_group.terraform.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_container_registry_task" "acr_task" {
  name                  = "agent-build"
  container_registry_id = azurerm_container_registry.acr.id

  platform {
    os           = "Linux"
    architecture = "amd64"
  }

  docker_step {
    context_access_token = var.azure_devops_agents_token // var.azure_devops_personal_access_token
    context_path         = "https://github.com/richeney/azure_devops_agent.git#main:."
    dockerfile_path      = "./dockerfile"
    image_names          = ["azp-agent:linux"]
    push_enabled         = true
    arguments            = null
  }

  base_image_trigger {
    name    = "base-image-trigger"
    type    = "Runtime"
    enabled = true
  }

#   source_trigger {
#     name           = "repo-update-trigger"
#     source_type    = "Github"
#     repository_url = "https://github.com/richeney/azure_devops_agent"
#     branch         = "main"
#     events         = ["commit", "pullrequest"]
#     enabled        = true
#  }
}

resource "azurerm_container_registry_task_schedule_run_now" "run_now" {
  container_registry_task_id = azurerm_container_registry_task.acr_task.id
}