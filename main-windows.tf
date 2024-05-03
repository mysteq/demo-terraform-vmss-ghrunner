data "azurerm_client_config" "core" {}

resource "random_password" "pw" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-vmss-ghrunner-noeast"
  location = "Norway East"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.252.0.0/24"]
}

resource "azurerm_subnet" "snet" {
  name                 = "snet-test"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.252.0.0/25"]
}

resource "azurerm_subnet" "snet_bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.252.0.128/26"]
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                 = "vmss-demo-ghrunner-noeast"
  computer_name_prefix = "vm-ghr"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  sku                  = "Standard_D2s_v5"
  instances            = 1
  admin_username       = "runner"
  admin_password       = var.password
  upgrade_mode         = "Automatic"
  overprovision        = false

  plan {
    publisher = "amestofortytwoas1653635920536"
    product   = "self_hosted_runner_ado"
    name      = "windows-latest"
  }

  source_image_reference {
    publisher = "amestofortytwoas1653635920536"
    offer     = "self_hosted_runner_ado"
    sku       = "windows-latest"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic-vmss-ghrunner"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.snet.id
    }
  }

  boot_diagnostics {
    storage_account_uri = null

  }

  # automatic_instance_repair {
  #   enabled      = true
  #   grace_period = "PT10M"
  # }

  # termination_notification {
  #   enabled = true
  #   timeout = "PT5M"
  # }

  # extension {
  #   name                 = "CustomScript"
  #   publisher            = "Microsoft.Azure.Extensions"
  #   type                 = "CustomScript"
  #   type_handler_version = "2.1"

  #   protected_settings = <<SETTINGS
  #   {
  #       "fileUris": [
  #         "https://raw.githubusercontent.com/amestofortytwo/terraform-azurerm-selfhostedrunnervmss/main/scripts/script.sh"
  #         ],
  #       "commandToExecute": "RUNNER_CFG_PAT=${var.github_key} bash script.sh -s ${var.github_org} -u runner -l label -f"
  #   }
  #   SETTINGS
  # }

  extension {
    name                 = "CustomScript"
    publisher            = "Microsoft.Compute"
    type                 = "CustomScriptExtension"
    type_handler_version = "1.10"

    protected_settings = <<SETTINGS
    {
        "fileUris": [
          "https://raw.githubusercontent.com/amestofortytwo/terraform-azurerm-selfhostedrunnervmss/feat/ghdomain/scripts/invoke-ghrunner.ps1"
          ],
        "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command .\\invoke-ghrunner.ps1 -runnerscope ${var.github_org} -githubpat ${var.github_key} -user runner -userpassword ${var.password} -label label"
    }
    SETTINGS
  }

  # extension {
  #   name                 = "HealthExtension"
  #   publisher            = "Microsoft.ManagedServices"
  #   type                 = "ApplicationHealthLinux"
  #   type_handler_version = "1.0"

  #   settings = <<SETTINGS
  #   {
  #     "protocol": "tcp",
  #     "port": 22,
  #     "intervalInSeconds": 5,
  #     "numberOfProbes": 1
  #   }
  #   SETTINGS
  # }
}



resource "azurerm_public_ip" "publicip_bastion" {
  name                = "pip-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"

}

# Create network security group for Bastion
resource "azurerm_network_security_group" "nsg_bastion" {
  name                = "nsg-bastion"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    # Ingress traffic from Internet on 443 is enabled
    name                       = "AllowIB_HTTPS443_Internet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    # Ingress traffic for control plane activity that is GatewayManger to be able to talk to Azure Bastion
    name                       = "AllowIB_TCP443_GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    # Ingress traffic for health probes, enabled AzureLB to detect connectivity
    name                       = "AllowIB_TCP443_AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }
  security_rule {
    # Ingress traffic for data plane activity that is VirtualNetwork service tag
    name                       = "AllowIB_BastionHost_Commn8080"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    # Deny all other Ingress traffic 
    name                       = "DenyIB_any_other_traffic"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # * * * * * * OUT-BOUND Traffic * * * * * * #

  # Egress traffic to the target VM subnets over ports 3389 and 22
  security_rule {
    name                       = "AllowOB_SSHRDP_VirtualNetwork"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_ranges    = ["3389", "22"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }
  # Egress traffic to AzureCloud over 443
  security_rule {
    name                       = "AllowOB_AzureCloud"
    priority                   = 105
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
  # Egress traffic for data plane communication between the Bastion and VNets service tags
  security_rule {
    name                       = "AllowOB_BastionHost_Comn"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8080", "5701"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  # Egress traffic for SessionInformation
  security_rule {
    name                       = "AllowOB_GetSessionInformation"
    priority                   = 120
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

# Create Azure Bastion host
resource "azurerm_bastion_host" "bastion" {
  name                = "bas-vmss-server"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  ip_connect_enabled  = true
  tunneling_enabled   = true

  ip_configuration {
    name                 = "bas-ip-configuration"
    public_ip_address_id = azurerm_public_ip.publicip_bastion.id
    subnet_id            = azurerm_subnet.snet_bastion.id
  }
}
