# Quantum Commerce - API e Compute (Aula 3)

Este repositório contém a infraestrutura e a API da Quantum Commerce, focando em arquiteturas Serverless (Azure Functions) e Containers (Azure Container Instances).

## Como executar este projeto

1. **Infraestrutura (Terraform):**
   - Navegue até a pasta `terraform/`.
   - Execute `terraform init` e `terraform apply -auto-approve`.
   - Isso provisionará a Function App, o Storage Account (com o catálogo) e o Container Registry.

2. **Deploy da API (Function):**
   - O deploy é automatizado via GitHub Actions (veja `.github/workflows/deploy-function.yml`).
   - A cada push na branch `main` que altere a pasta `function/`, o código é testado com `pytest`, formatado com `ruff` e publicado via OIDC em um slot de staging, seguido de um swap para produção.

3. **Container (ACI):**
   - A imagem Docker pode ser importada via `az acr import` utilizando os arquivos da pasta `docker/`.
   - Após a importação, aplique a fase 2 do terraform (`terraform apply -var="aci_enabled=true"`) para provisionar o ACI.