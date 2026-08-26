# -------------------------------------------------------------------------
# Variáveis Globais de Infraestrutura
# -------------------------------------------------------------------------

variable "resource_group_name" {
  type        = string
  description = "O nome do Grupo de Recursos principal onde tudo será criado."
  default     = "rg-qc-aula02"
}

variable "location" {
  type        = string
  description = "A região do Azure onde os recursos serão provisionados."
  default     = "brazilsouth"
}

variable "tags" {
  type        = map(string)
  description = "Tags organizacionais para controle de custos e governança."
  default = {
    projeto      = "quantum-commerce"
    disciplina   = "cloud-cognitive"
    aula         = "2"
    provisionado = "terraform"
  }
}

# -------------------------------------------------------------------------
# Variáveis de Segurança e Acesso
# -------------------------------------------------------------------------

variable "sql_admin_password" {
  type        = string
  description = "Senha do administrador do banco de dados Azure SQL e Synapse."
  sensitive   = true 
}

variable "meu_ip" {
  type        = string
  description = "O seu endereço de IP público para liberação no firewall do Cosmos DB e SQL."
  default     = "0.0.0.0" # Substitua pelo seu IP real ao executar ou via linha de comando
}