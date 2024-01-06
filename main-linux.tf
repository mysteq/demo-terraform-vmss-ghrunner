# data "azurerm_client_config" "core" {}

# resource "random_password" "pw" {
#   length           = 16
#   special          = true
#   override_special = "_%@"
# }

# resource "azurerm_resource_group" "rg" {
#   name     = "rg-vmss-ghrunner-noeast"
#   location = "Norway East"
# }

# resource "azurerm_virtual_network" "vnet" {
#   name                = "vnet-vmss"
#   resource_group_name = azurerm_resource_group.rg.name
#   location            = azurerm_resource_group.rg.location
#   address_space       = ["10.252.0.0/24"]
# }

# resource "azurerm_subnet" "snet" {
#   name                 = "snet-test"
#   resource_group_name  = azurerm_resource_group.rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.252.0.0/25"]
# }

# resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
#   name                            = "vmss-demo-ghrunner-noeast"
#   resource_group_name             = azurerm_resource_group.rg.name
#   location                        = azurerm_resource_group.rg.location
#   sku                             = "Standard_D2s_v5"
#   instances                       = 1
#   admin_username                  = "runner"
#   admin_password                  = var.password
#   upgrade_mode                    = "Automatic"
#   disable_password_authentication = false
#   overprovision                   = false

#   plan {
#     publisher = "amestofortytwoas1653635920536"
#     product   = "self_hosted_runner_ado-preview"
#     name      = "ubuntu-latest"
#   }

#   source_image_reference {
#     publisher = "amestofortytwoas1653635920536"
#     offer     = "self_hosted_runner_ado-preview"
#     sku       = "ubuntu-latest"
#     version   = "latest"
#   }

#   os_disk {
#     storage_account_type = "Standard_LRS"
#     caching              = "ReadWrite"
#   }

#   network_interface {
#     name    = "nic-vmss-ghrunner"
#     primary = true

#     ip_configuration {
#       name      = "internal"
#       primary   = true
#       subnet_id = azurerm_subnet.snet.id
#     }
#   }

#   boot_diagnostics {
#     storage_account_uri = null

#   }

#   automatic_instance_repair {
#     enabled      = true
#     grace_period = "PT10M"
#   }

#   termination_notification {
#     enabled = true
#     timeout = "PT5M"
#   }

#   # extension {
#   #   name                 = "CustomScript"
#   #   publisher            = "Microsoft.Azure.Extensions"
#   #   type                 = "CustomScript"
#   #   type_handler_version = "2.1"

#   #   protected_settings = <<SETTINGS
#   #   {
#   #       "fileUris": [
#   #         "https://raw.githubusercontent.com/amestofortytwo/terraform-azurerm-selfhostedrunnervmss/main/scripts/script.sh"
#   #         ],
#   #       "commandToExecute": "RUNNER_CFG_PAT=${var.github_key} bash script.sh -s ${var.github_org} -u runner -l label -f"
#   #   }
#   #   SETTINGS
#   # }

#     extension {
#     name                 = "CustomScript"
#     publisher            = "Microsoft.Azure.Extensions"
#     type                 = "CustomScript"
#     type_handler_version = "2.1"

#     protected_settings = <<SETTINGS
#     {
#         "fileUris": [
#           "https://raw.githubusercontent.com/amestofortytwo/terraform-azurerm-selfhostedrunnervmss/main/scripts/script.sh"
#           ],
#         "commandToExecute": "sh script.sh ${var.github_org} ${var.github_key} runner label"
#     }
#     SETTINGS
#   }

#   extension {
#     name                 = "HealthExtension"
#     publisher            = "Microsoft.ManagedServices"
#     type                 = "ApplicationHealthLinux"
#     type_handler_version = "1.0"

#     settings = <<SETTINGS
#     {
#       "protocol": "tcp",
#       "port": 22,
#       "intervalInSeconds": 5,
#       "numberOfProbes": 1
#     }
#     SETTINGS
#   }
# }
