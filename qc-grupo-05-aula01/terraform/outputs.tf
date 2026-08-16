output "public_ip_address" {
  value       = azurerm_public_ip.pip.ip_address
  description = "IP publico estatico da VM criada"
}

output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "ID do recurso da VM no Azure"
}

output "subnet_app_id" {
  value       = azurerm_subnet.subnet_app.id
  description = "ID da subnet-app para futura integracao"
}
