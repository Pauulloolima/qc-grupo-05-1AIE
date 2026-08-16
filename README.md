# Terraform — Lab Aula 01 (Endurecimento de Segurança)

Este diretório contém os arquivos Terraform prontos para deploy no Azure, cumprindo todos os requisitos do **Exercício 3.1 (Nível 3)**:

1. **Restrição de SSH** apenas para o seu IP público (`var.meu_ip`).
2. **Criação da segunda subnet** (`subnet-app` com CIDR `10.0.2.0/24`).
3. **Outputs** expondo o IP público estático da VM e ID dos recursos.

---

## 🚀 Como Executar (Passo a Passo)

### Opção 1: No Azure Cloud Shell (Recomendado — Sem Instalação)

1. Abra o [Azure Cloud Shell](https://shell.azure.com) no navegador (modo Bash).
2. Certifique-se de que possui uma chave SSH gerada (se não tiver, crie com):
   ```bash
   [ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
   ```
3. Navegue até a pasta do Terraform:
   ```bash
   cd terraform
   ```
4. Inicialize o Terraform:
   ```bash
   terraform init
   ```
5. Visualize o plano de execução (injetando seu IP automaticamente):
   ```bash
   terraform plan -var="meu_ip=$(curl -s ifconfig.me)"
   ```
6. Aplique as alterações no Azure:
   ```bash
   terraform apply -var="meu_ip=$(curl -s ifconfig.me)" -auto-approve
   ```
7. Para testar o acesso SSH na máquina recém-criada:
   ```bash
   ssh -i ~/.ssh/id_rsa azureuser@$(terraform output -raw public_ip_address)
   ```
8. Ao terminar os testes, **destrua os recursos** para não gerar custos:
   ```bash
   terraform destroy -var="meu_ip=$(curl -s ifconfig.me)" -auto-approve
   ```

---

### Opção 2: Localmente (Com Azure CLI e Terraform instalados)

1. Faça login na sua conta do Azure:
   ```bash
   az login
   ```
2. Defina a subscription ativa (se tiver mais de uma):
   ```bash
   az account set --subscription "<ID_DA_SUA_ASSINATURA>"
   ```
3. Crie seu arquivo `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```
   Edite o arquivo e preencha com seu IP público.
4. Execute:
   ```bash
   terraform init
   terraform apply
   ```

---

## 📁 Estrutura dos Arquivos

| Arquivo | Descrição |
|---|---|
| [`main.tf`](./main.tf) | Definição do Resource Group, VNet (2 subnets), NSG com SSH restrito, IP público, NIC e VM Linux (Ubuntu 24.04). |
| [`variables.tf`](./variables.tf) | Declaração de variáveis parametrizáveis (`meu_ip`, `location`, `vm_size`, etc.). |
| [`outputs.tf`](./outputs.tf) | Exposição dos dados pós-criação (`public_ip_address`, `vm_id`, `subnet_app_id`). |
| [`terraform.tfvars.example`](./terraform.tfvars.example) | Exemplo de preenchimento das variáveis. |
