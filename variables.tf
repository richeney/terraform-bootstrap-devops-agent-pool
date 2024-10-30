variable "agent_pool_name" {
  type        = string
  description = "The name of the Azure DevOps agent pool."
  default     = "agent-pool"

  validation {
    condition     = length(var.agent_pool_name) > 0
    error_message = "The agent_pool_name must be a valid string."
  }
}

variable "agent_pool_virtual_network_name" {
  type        = string
  description = "The name of the virtual network for the Azure DevOps agent pool."
  default     = "agent-pool-vnet"
}

variable "agent_pool_virtual_network_address_space" {
  type        = list(string)
  description = "The address space for the virtual network for the Azure DevOps agent pool."
  default     = ["10.0.0.0/24"]
}

//================================================================

variable "azure_devops_organization_name" {
  type        = string
  description = "value of the Azure DevOps organization name"
}

# variable "azure_devops_project_name" {
# type        = string
# description = "value of the Azure DevOps project name"
# }

variable "azure_devops_personal_access_token" {
  type        = string
  description = "value of the Azure DevOps fine grained personal access token"
}

# variable "azure_devops_variable_group_name" {
#   type        = string
#   description = "value of the Azure DevOps variable group name"
#   default     = "Terraform Backend"

#   validation {
#     condition     = length(var.azure_devops_variable_group_name) > 0
#     error_message = "The azure_devops_variable_group_name must be a valid string."
#   }
# }

# variable "azure_devops_service_connection_name" {
#   type        = string
#   description = "value of the Azure DevOps service connection name"

#   default = "Terraform"

#   validation {
#     condition     = length(var.azure_devops_service_connection_name) > 0
#     error_message = "The service_connection_name must be a valid string."
#   }
# }

# variable "azure_devops_create_pipeline" {
#   description = "Create a pipeline in Azure DevOps."
#   type        = bool
#   default     = true
# }

# variable "azure_devops_create_files" {
#   description = "Create a set of Terraform files in Azure DevOps."
#   type        = bool
#   default     = false
# }

# variable "azure_devops_self_hosted_agents" {
#   description = "Boolean to determine if self-hosted agents should be used."
#   type        = bool
#   default     = false
# }

variable "azure_devops_agents_token" {
  description = "Personal access token for Azure DevOps self-hosted agents (the token requires the 'Agent Pools - Read & Manage' scope and should have the maximum expiry)."
  type        = string
  sensitive   = true
  default     = ""

  validation {
    condition     = length(var.azure_devops_agents_token) > 0
    error_message = "The azure_devops_agents_token must be a valid string."
  }
}


//================================================================

variable "location" {
  type        = string
  description = "The Azure region to deploy resources."
  default     = "UK South"
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to resources."
  default     = null
}

//================================================================
// These should be found in the backend.auto.tfvars file created by the bootstrap.sh script

variable "subscription_id" {
  type        = string
  description = "The subscription guid for the terraform resource group."

  validation {
    condition     = length(var.subscription_id) == 36 && can(regex("^[a-z0-9-]+$", var.subscription_id))
    error_message = "Subscription ID must be a 36 character GUID."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The name of the (pre-existing) resource group to deploy resources."
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account. Must be globally unique."

  validation {
    condition     = (length(coalesce(var.storage_account_name, "abcefghijklmnopqrstuwxy")) <= 24 && length(coalesce(var.storage_account_name, "ab")) > 3 && can(regex("^[a-z0-9]+$", coalesce(var.storage_account_name, "A%"))))
    error_message = "Storage account name must be null or 3-24 of lowercase alphanumerical characters, and globally unique"
  }
}

# variable "container_name" {
#   type        = string
#   description = "The name of the storage container for the terraform state."
#   default     = "agent-pool"

#   validation {
#     condition     = length(var.container_name) > 0
#     error_message = "The container_name must be a valid string."
#   }
# }

# variable "terraform_state_key" {
#   type        = string
#   description = "The key (or blob name) for the terraform state file in the storage container."
#   default     = "terraform.tfstate"

#   validation {
#     condition     = length(var.terraform_state_key) > 0
#     error_message = "The terraform_state_key must be a valid string."
#   }
# }
