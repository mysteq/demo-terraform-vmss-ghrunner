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

resource "azurerm_linux_virtual_machine_scale_set" "vmss" {
  name                            = "example-vmss"
  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  sku                             = "Standard_D2s_v3"
  instances                       = 2
  admin_username                  = "admin42"
  admin_password                  = random_password.pw.result
  upgrade_mode                    = "Automatic"
  disable_password_authentication = false

  source_image_reference {
    publisher = "amestofortytwoas1653635920536"
    offer     = "self_hosted_runner_github-preview"
    sku       = "ubuntu_latest"
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

  extension {
    name                 = "CustomScript"
    publisher            = "Microsoft.Azure.Extensions"
    type                 = "CustomScript"
    type_handler_version = "2.1"

    protected_settings = <<SETTINGS
    {
        "fileUris": "https://raw.githubusercontent.com/mysteq/demo-terraform-vmss-ghrunner/script.sh",
        "commandToExecute": "sh script.sh https://github.com/mysteq/demo-terraform-vmss-ghrunner x label"
    }
    SETTINGS
  }
}
