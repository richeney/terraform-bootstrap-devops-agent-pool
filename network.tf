data "azurerm_client_config" "current" {}

data "azurerm_subscription" "terraform" {
  subscription_id = var.subscription_id
}

data "azurerm_resource_group" "terraform" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "terraform" {
  name                = var.storage_account_name
  resource_group_name = data.azurerm_resource_group.terraform.name
}

# data "http" "source_address" {
#   url = "https://ipinfo.io/ip"

#   request_headers = {
#     Accept = "application/json"
#   }
# }

locals {
  uniq                    = substr(sha1(data.azurerm_resource_group.terraform.id), 0, 8)
  container_registry_name = "terraformacr${local.uniq}"
  virtual_network_name    = "agent-pool-vnet"
}

# resource "azurerm_storage_container" "terraform" {
#   name                  = "tfstate"
#   storage_account_name  = azurerm_storage_account.terraform.name
#   container_access_type = "private"

#   depends_on = [
#     azurerm_storage_account.terraform
#   ]
# }

# resource "azurerm_user_assigned_identity" "terraform" {
#   name                = var.managed_identity_name
#   resource_group_name = data.azurerm_resource_group.terraform.name
#   location            = data.azurerm_resource_group.terraform.location
#   tags                = var.tags

#   lifecycle {
#     ignore_changes = [tags]
#   }
# }

# resource "azurerm_role_assignment" "contributor" {
#   // Make this a default, but allow it to be overridden with an array of objects containing scope and role_definition_name
#   scope                = "/subscriptions/${var.subscription_id}"
#   role_definition_name = "Contributor"
#   principal_id         = azurerm_user_assigned_identity.terraform.principal_id
# }

# resource "azurerm_role_assignment" "state" {
#   scope                = azurerm_storage_account.terraform.id
#   role_definition_name = "Storage Blob Data Contributor"
#   principal_id         = azurerm_user_assigned_identity.terraform.principal_id

# }

//===================================================================

// Resources for host pool

resource "azurerm_virtual_network" "agentpool" {
  name                = var.agent_pool_virtual_network_name
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name
  address_space       = var.agent_pool_virtual_network_address_space
}

resource "azurerm_public_ip" "agentpool" {
  name                = "${var.agent_pool_virtual_network_name}-pip"
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "agentpool" {
  name                = "${var.agent_pool_virtual_network_name}-natgw"
  location            = data.azurerm_resource_group.terraform.location
  resource_group_name = data.azurerm_resource_group.terraform.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "agentpool" {
  nat_gateway_id       = azurerm_nat_gateway.agentpool.id
  public_ip_address_id = azurerm_public_ip.agentpool.id
}

resource "azurerm_subnet" "container_instances" {
  name                              = "container_instances"
  resource_group_name               = data.azurerm_resource_group.terraform.name
  virtual_network_name              = azurerm_virtual_network.agentpool.name
  address_prefixes                  = [cidrsubnet(var.agent_pool_virtual_network_address_space[0], 2, 0)]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"

  delegation {
    name = "container_instance_delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet_nat_gateway_association" "container_instances" {
  subnet_id      = azurerm_subnet.container_instances.id
  nat_gateway_id = azurerm_nat_gateway.agentpool.id
}

resource "azurerm_subnet" "storage" {
  name                              = "storage"
  resource_group_name               = data.azurerm_resource_group.terraform.name
  virtual_network_name              = azurerm_virtual_network.agentpool.name
  address_prefixes                  = [cidrsubnet(var.agent_pool_virtual_network_address_space[0], 2, 1)]
  default_outbound_access_enabled   = false
  private_endpoint_network_policies = "Enabled"
}

resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.terraform.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "storage_private_dns_zone_link"
  resource_group_name   = data.azurerm_resource_group.terraform.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = azurerm_virtual_network.agentpool.id
}

resource "azurerm_private_endpoint" "storage" {
  name                = "${data.azurerm_storage_account.terraform.name}-pe"
  resource_group_name = data.azurerm_resource_group.terraform.name
  location            = data.azurerm_resource_group.terraform.location
  subnet_id           = azurerm_subnet.storage.id

  custom_network_interface_name = "${data.azurerm_storage_account.terraform.name}-pe-nic"

  private_service_connection {
    name                           = "blob_storage_private_service_connection"
    private_connection_resource_id = data.azurerm_storage_account.terraform.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "blob_storage"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }
}
