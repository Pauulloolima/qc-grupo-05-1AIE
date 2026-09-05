# ☁️ Quantum Commerce - Deploy & Execução (Aula 03)

Este repositório contém a infraestrutura e os códigos da **Entrega 03** da disciplina de *Cloud & Cognitive Environments* (MBA AI Engineering & Multi-Agents - FIAP). O objetivo deste projeto é provisionar a camada de compute (Serverless e Containers) da Quantum Commerce na Azure.

---

## 📂 Estrutura do Diretório

A estrutura de pastas reflete a arquitetura e a separação de responsabilidades da entrega:

```text
.
├── entrega-grupo-05-aula03.md    # Documento principal com a resolução dos exercícios (N1, N2 e N3)
├── README.md                     # Este arquivo de instruções de execução
├── terraform/                    # Arquivos IaC para provisionamento no Azure (App, ACR, ACI, Storage, App Insights)
├── function/                     # Código Python das rotas Serverless (Catálogo de Produtos e Cálculo de Frete)
├── docker/                       # Dockerfile e código FastAPI (versão containerizada da API)
└── diagramas/                    # Diagramas de arquitetura e prints de observabilidade (ex: Live Metrics)
```

---

## 🛠️ Pré-requisitos

Para executar este laboratório, você precisará do **Azure Cloud Shell** (recomendado, pois dispensa instalações locais) ou das seguintes ferramentas configuradas localmente:
- **Azure CLI** (autenticado com `az login`)
- **Terraform** (versão 1.x+)
- **Azure Functions Core Tools** (`func`)

---

## 🚀 Passo a Passo de Execução

O deploy é dividido em 3 grandes fases: Provisionamento Base, Deploy da Function e Habilitação do Container (ACI).

### Fase 1: Provisionamento Base da Infraestrutura (Terraform)
Nesta fase, criamos o Resource Group, Storage Account (com upload automático do arquivo de catálogo `produtos.csv`), Azure Container Registry (ACR), Azure Function App e o Application Insights.

1. Acesse o diretório do Terraform:
   ```bash
   cd terraform
   ```
2. Inicialize o Terraform e aplique o plano básico (sem habilitar o ACI ainda):
   ```bash
   terraform init
   terraform apply -auto-approve
   ```
3. Anote os valores exibidos nos `Outputs` ao final da execução. Você precisará deles nos próximos passos:
   - `function_app_name`
   - `function_app_default_hostname`
   - `acr_name`

### Fase 2: Deploy da Azure Function (Serverless)
Com a infraestrutura base criada, faremos o deploy do código Python para a Azure Function. Nossa aplicação contempla as rotas de busca de produtos no Storage Blob via Managed Identity e cálculo de frete.

1. Navegue até a pasta da Function (versão final `v2-blob`):
   ```bash
   cd ../function/v2-blob
   ```
2. Colete o nome da Function gerado no Terraform e execute o deploy:
   ```bash
   FUNC_NAME=$(cd ../../terraform && terraform output -raw function_app_name)
   func azure functionapp publish "$FUNC_NAME" --python
   ```

### Fase 3: Deploy do Azure Container Instances (ACI)
Para o serviço de container, utilizaremos a imagem da API FastAPI que foi publicada no GitHub Container Registry (GHCR).

1. Importe a imagem para o seu Azure Container Registry (ACR):
   ```bash
   ACR_NAME=$(cd ../../terraform && terraform output -raw acr_name)
   az acr import \
     --name "$ACR_NAME" \
     --source ghcr.io/isaiasbritto/produtos-api:v1 \
     --image produtos-api:v1 \
     --force
   ```
2. Com a imagem disponível no seu registro, habilite o Azure Container Instances (ACI) via Terraform:
   ```bash
   cd ../../terraform
   terraform apply -auto-approve -var="aci_enabled=true"
   ```
3. Colete a URL gerada para o ACI nos outputs:
   ```bash
   terraform output -raw aci_fqdn
   ```
   *(Aguarde cerca de 1 minuto para que a Managed Identity se propague antes de testar).*

---

## 🧪 Como Testar as APIs

### 1. Testando a Azure Function (Serverless)
A Azure Function contém dois serviços integrados: Busca de Produtos e Cálculo de Frete.

**Busca de Produtos (Catálogo no Storage):**
```bash
HOSTNAME=$(cd terraform && terraform output -raw function_app_default_hostname)

# Filtrando por categoria
curl -s "https://$HOSTNAME/api/produtos?categoria=moveis" | python3 -m json.tool

# Filtrando por nome
curl -s "https://$HOSTNAME/api/produtos?nome=cadeira" | python3 -m json.tool
```

**Cálculo de Frete (Tool Adicional - Exercício 2.1):**
```bash
# Rota para estimativa de frete (determinística)
curl -s "https://$HOSTNAME/api/frete?cep_origem=01000-000&cep_destino=02000-000&peso=5" | python3 -m json.tool
```

### 2. Testando o Container (ACI)
O ACI roda uma versão equivalente da API de catálogo via FastAPI.
```bash
ACI_FQDN=$(cd terraform && terraform output -raw aci_fqdn)

# Healthcheck
curl "http://$ACI_FQDN:8080/health"

# Busca de Produtos
curl "http://$ACI_FQDN:8080/produtos?categoria=moveis"
```

---

## 📊 Observabilidade (Application Insights)
A integração com o Application Insights foi habilitada via Terraform no bloco da Azure Function (Exercício 2.2). 
Para visualizar os logs e a árvore de rastreamento:
1. Acesse o [Portal do Azure](https://portal.azure.com).
2. Busque por **Application Insights**.
3. Acesse a aba **Live Metrics** e realize as requisições de teste para acompanhar os picos de tráfego e latência (p95) em tempo real, cujos prints encontram-se na pasta `diagramas/`.

---

## 🧹 Limpeza do Ambiente (Custo Zero)
Para garantir que não haja cobranças por ociosidade (especialmente do ACI), destrua os recursos ao final dos testes. Todos os recursos, incluindo o Storage Account de catálogo provisionado por este projeto, serão removidos.

```bash
cd terraform
terraform destroy -auto-approve -var="aci_enabled=true"
```
