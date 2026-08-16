variable "location" {
  type        = string
  default     = "eastus2"
  description = "Regiao do Azure onde os recursos serao criados"
}

variable "resource_group_name" {
  type        = string
  default     = "rg-lab-tf-aula01"
  description = "Nome do Resource Group para o ambiente de lab"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Tamanho da VM Linux"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Usuario administrador da VM"
}

variable "ssh_public_key_path" {
  type        = string
  default     = "~/.ssh/id_rsa.pub"
  description = "Caminho local para a chave publica SSH"
}

variable "meu_ip" {
  type        = string
  description = "IP publico de origem liberado para acesso SSH (ex: 187.12.34.56)"
}
