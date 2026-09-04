# QC — Aula 3: Serverless + Containers (Quantum Commerce)

Entrega do **Grupo 05** (turma 1AIE) para a Aula 3 da disciplina Cloud & Cognitive Environments (FIAP MBA AI Engineering & Multi-Agents): provisionamento via **Terraform** da camada de compute da Quantum Commerce, com uma **Azure Function (Flex Consumption)** e um **container FastAPI** publicado no **Azure Container Registry (ACR)** e executado em **Azure Container Instances (ACI)**, ambos lendo o catálogo de produtos de um **Storage Account** dedicado, sem credenciais hardcoded (Managed Identity) — mais um **pipeline de CI/CD** (GitHub Actions) para deploy contínuo da Function.

| Membro | GitHub | Nível assumido |
|---|---|---|
| Paulo Edvaldo de Lima | [@Pauulloolima](https://github.com/Pauulloolima) | 🟢 N1 (1.1–1.4) + 🟡 N2 (2.1–2.3) |
| Daniel Luconi Spinelli | [@dluconi](https://github.com/dluconi) | 🔴 N3 (3.1–3.3) |

> 📄 Para o relatório completo da entrega (respostas dos níveis N1/N2/N3, benchmark de carga, evidências), veja [`entrega-grupo-05-aula03.md`](entrega-grupo-05-aula03.md).

Este é o **único README** do projeto — as instruções que antes viviam em `function/README.md`, `docker/README.md` e `terraform/README.md` foram todas consolidadas aqui.

---

## Sumário

- [Arquitetura](#arquitetura)
- [Estrutura de pastas](#estrutura-de-pastas)
- [Pré-requisitos](#pré-requisitos)
- [Fase 1 — Provisionar infraestrutura base](#fase-1--provisionar-infraestrutura-base-terraform)
- [Fase 2 — Deploy da Azure Function](#fase-2--deploy-da-azure-function)
- [Fase 3 — Importar a imagem no ACR e habilitar o ACI](#fase-3--importar-a-imagem-no-acr-e-habilitar-o-aci)
- [Testando os endpoints](#testando-os-endpoints)
- [Pipeline CI/CD (GitHub Actions)](#pipeline-cicd-github-actions)
- [Gerando o ZIP de entrega](#gerando-o-zip-de-entrega)
- [Outputs do Terraform](#outputs-do-terraform)
- [Observabilidade (Application Insights)](#observabilidade-application-insights)
- [Destruindo o ambiente (custo zero)](#destruindo-o-ambiente-custo-zero)
- [Troubleshooting](#troubleshooting)
- [⚠️ Informações que faltam / a confirmar](#️-informações-que-faltam--a-confirmar)

---

## Arquitetura

A camada de compute desta aula é composta por dois caminhos de acesso ao catálogo de produtos, ambos autenticando via **Managed Identity** (sem chaves/segredos no código):

```
                         ┌─────────────────────────┐
                         │   Storage Account        │
                         │   "catálogo" (Aula 3)     │
                         │   container: catalogo     │
                         │   blob: produtos.csv      │
                         └───────────▲──────────────┘
                                     │ Storage Blob Data Reader
                    ┌────────────────┴────────────────┐
                    │                                  │
        ┌───────────┴───────────┐          ┌───────────┴────────────┐
        │  Azure Function App    │          │  Azure Container       │
        │  (Flex Consumption)    │          │  Instances (ACI)        │
        │  Managed Identity:     │          │  Managed Identity:      │
        │  SystemAssigned        │          │  UserAssigned (id-aci)  │
        └────────────────────────┘          └────────────▲─────────┘
                                                            │ pull da imagem
                                              ┌─────────────┴─────────────┐
                                              │  Azure Container Registry  │
                                              │  (Basic SKU)               │
                                              │  produtos-api:v1           │
                                              └─────────────────────────────┘

        Application Insights + Log Analytics Workspace → observabilidade da Function
        GitHub Actions (OIDC) → publica a Function a cada push em main
```

Veja o diagrama completo em [`diagramas/arquitetura-qc-aula03.png`](diagramas/arquitetura-qc-aula03.png).

**Componentes provisionados pelo Terraform:**

| Recurso | Arquivo | Observação |
|---|---|---|
| Resource Group | `main.tf` | `rg-qc-aula03-<sufixo>` |
| Service Plan (FC1 — Flex Consumption) | `main.tf` | Sucessor do Linux Consumption/Y1 (aposentado set/2028); **não suporta deployment slots** |
| Storage Account da Function | `storage.tf` | Guarda o pacote de deploy (`deployments`) |
| Storage Account do catálogo | `storage.tf` | Criado nesta aula; recebe `produtos.csv` automaticamente no `apply` |
| Function App (Flex Consumption) | `function.tf` | Python 3.12, Managed Identity SystemAssigned |
| Log Analytics Workspace + Application Insights | `function.tf` | Observabilidade da Function |
| Azure Container Registry | `containers.tf` | SKU Basic, admin habilitado (fins didáticos); imagem `produtos-api:v1` importada do GHCR via `az acr import` |
| Managed Identity (User-Assigned) | `containers.tf` | Usada pelo ACI |
| Azure Container Instances | `containers.tf` | Condicional via `var.aci_enabled` |
| Role Assignments (Storage Blob Data Reader) | `function.tf`, `containers.tf` | Function e ACI leem o catálogo sem chaves |

---

## Estrutura de pastas

```
qc-grupo-05-1AIE/                       # repositório monorepo da disciplina
├── .github/
│   └── workflows/
│       └── deploy-function.yml         # CI/CD: lint + testes + deploy da Function via OIDC
├── qc-grupo-05-aula01/
├── qc-grupo-05-aula02/
└── qc-grupo-05-aula03/                 # ⭐ pasta desta entrega
    ├── entrega-grupo-05-aula03.md      # documento principal da entrega (respostas N1/N2/N3)
    ├── README.md                       # este arquivo — único README do projeto
    ├── .gitignore
    ├── data/
    │   └── produtos.csv                # catálogo de produtos, subido pelo Terraform
    ├── terraform/
    │   ├── main.tf                     # providers, RG, sufixo aleatório, locals, Service Plan FC1
    │   ├── storage.tf                  # Storage da Function + Storage do catálogo + upload do CSV
    │   ├── function.tf                 # Function App + Managed Identity + App Insights + role
    │   ├── containers.tf               # ACR + UAI + role + ACI (condicional)
    │   ├── variables.tf                # location, aci_enabled
    │   └── outputs.tf                  # outputs da infraestrutura
    ├── function/
    │   ├── v1-mock/                    # versão da Function com dados mockados (nível 1)
    │   │   ├── function_app.py
    │   │   ├── host.json
    │   │   └── requirements.txt        # azure-functions
    │   └── v2-blob/                    # versão real: catálogo via blob + Managed Identity + frete (nível 2)
    │       ├── function_app.py         # rotas /api/health, /api/produtos, /api/frete
    │       ├── host.json
    │       └── requirements.txt        # azure-functions, azure-identity, azure-storage-blob
    ├── docker/
    │   ├── app.py                      # API FastAPI (produtos-api) — endpoints /health e /produtos
    │   ├── Dockerfile                  # multi-stage build (python:3.11-slim), expõe a porta 8080
    │   └── requirements.txt            # fastapi, uvicorn[standard], azure-identity, azure-storage-blob
    └── diagramas/
        ├── arquitetura-qc-aula03.png   # diagrama da arquitetura desta aula
        └── print-live-metrics.png      # evidência de métricas ao vivo (App Insights)
```

> Esta estrutura assume que o grupo já ajustou o nome da pasta desta aula para `qc-grupo-05-aula03` de forma consistente em todo o repositório — incluindo no comando `git archive` e no `.github/workflows/deploy-function.yml` (ver seções [Pipeline CI/CD](#pipeline-cicd-github-actions) e [Gerando o ZIP de entrega](#gerando-o-zip-de-entrega)).

---

## Pré-requisitos

- Conta Azure ativa (ex.: Azure for Students) com permissão para criar Resource Groups, Storage, Function Apps, ACR e ACI
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) autenticado (`az login`)
- [Terraform](https://developer.hashicorp.com/terraform/install) `>= 1.x`, com provider `azurerm >= 4.4, < 5.0` (necessário para `azurerm_function_app_flex_consumption`)
- [Azure Functions Core Tools](https://learn.microsoft.com/azure/azure-functions/functions-run-local) v4, para publicar o código da Function
- Uma máquina/ambiente **com Docker** (ex.: GitHub Codespaces) para o build/push único da imagem no GHCR — o Cloud Shell **não** tem daemon Docker e, em contas Azure for Students, `az acr build` (ACR Tasks) costuma ser bloqueado
- Conta no GitHub com permissão para criar um Personal Access Token com escopo `write:packages` (publicar no GHCR) e para configurar Secrets/federated credentials do repositório (CI/CD)
- Recomendado: rodar os passos de Terraform/CLI no **Azure Cloud Shell**, que já vem com Azure CLI e Terraform pré-instalados

> 💡 A região padrão é `eastus2` (variável `location` em `terraform/variables.tf`). `Brazil South` costuma ser bloqueado pela política de "best available regions" de contas Azure for Students.

---

## Fase 1 — Provisionar infraestrutura base (Terraform)

Provisiona Resource Group, os dois Storage Accounts (Function + catálogo, já com `produtos.csv`), Function App, ACR, Managed Identities e role assignments. **O ACI ainda não é criado nesta fase** (a flag `aci_enabled` é `false` por padrão, pois a imagem precisa existir no ACR antes).

```bash
cd terraform

terraform init
terraform apply -auto-approve
```

Tempo estimado: **~3 minutos**.

Ao final, confira os outputs:

```bash
terraform output
```

---

## Fase 2 — Deploy da Azure Function

O repositório traz duas versões **self-contained** da Function em `function/` (programming model v2 do Azure Functions), cada uma com seu próprio `function_app.py` + `host.json` + `requirements.txt`:

| Pasta | Nível | Características | Dependências (`requirements.txt`) |
|---|---|---|---|
| [`v1-mock/`](function/v1-mock/) | 1 | 5 produtos hardcoded no código, sem dependências externas — bom para validar que o deploy funciona | `azure-functions` |
| [`v2-blob/`](function/v2-blob/) | 2 | Lê os 20 produtos reais do Storage do catálogo via **Managed Identity**, sem credenciais no código; inclui também a rota `/api/frete` (cálculo de frete, exercício 2.1) | `azure-functions`, `azure-identity`, `azure-storage-blob` |

Publique **as duas versões, em sequência**, usando o nome da Function App gerado pelo Terraform (cada `publish` substitui o código publicado anteriormente):

```bash
FUNC_NAME=$(terraform -chdir=terraform output -raw function_app_name)
echo "Function: $FUNC_NAME"

# 1) Deploy da v1 (mock) — valida a Function App isoladamente
cd function/v1-mock
func azure functionapp publish "$FUNC_NAME" --python

# 2) Deploy da v2 (Blob + Managed Identity + frete) — fluxo real desta aula
cd ../v2-blob
func azure functionapp publish "$FUNC_NAME" --python
```

A Function já recebe automaticamente, via `app_settings` no Terraform:

- `STORAGE_ACCOUNT_CATALOGO` — nome do Storage Account do catálogo
- `APPLICATIONINSIGHTS_CONNECTION_STRING` — conexão com o Application Insights

Não é necessário configurar nenhuma credencial adicional: a `v2-blob` lê o blob usando a Managed Identity SystemAssigned da Function (via `azure-identity` + `azure-storage-blob`), que já recebeu a role **Storage Blob Data Reader** no `apply` da Fase 1.

> 💡 **Lição central da comparação v1 × v2:** a `v2-blob` lê o catálogo direto do Blob Storage e, em nenhum momento, aparece chave, senha, connection string ou secret no código — esse é o padrão que todos os componentes consumidos pelos agentes da QC devem seguir.

---

## Fase 3 — Importar a imagem no ACR e habilitar o ACI

A versão em container é uma API **FastAPI** (`docker/app.py`) com a mesma lógica de negócio da Function `v2-blob` — expõe `/health` e `/produtos`, autentica no Storage do catálogo via **Managed Identity** (`azure-identity` + `azure-storage-blob`) e roda com **Uvicorn** na porta `8080`. A imagem é multi-stage (`python:3.11-slim`), resultando em uma imagem final leve.

### 3.1. Por que importar do GHCR em vez de buildar direto no Cloud Shell

Em contas **Azure for Students**, dois obstáculos impedem o build direto na nuvem:

- **ACR Tasks é bloqueado** — `az acr build` falha com `TasksOperationsNotAllowed`
- **Cloud Shell não tem daemon Docker** — `docker build` não roda lá

Por isso, o fluxo adotado é: a imagem é **construída e publicada uma única vez no GHCR** (por quem tiver Docker disponível — ex.: GitHub Codespaces, que já roda `linux/amd64`), e depois **importada** para o ACR de cada grupo via `az acr import` (permitida mesmo sem Tasks e sem Docker local).

### 3.2. Build e publish da imagem no GHCR (uma vez, por quem tem Docker)

```bash
cd docker

# PAT do GitHub com escopo write:packages (Settings → Developer settings → Personal access tokens → Tokens classic)
export GHCR_PAT=ghp_seu_token_aqui
echo "$GHCR_PAT" | docker login ghcr.io -u <seu-usuario-github> --password-stdin

# IMPORTANTE: ACI roda linux/amd64 — force a plataforma (essencial em Mac ARM)
docker build --platform linux/amd64 -t ghcr.io/<seu-usuario-github>/produtos-api:v1 .
docker push ghcr.io/<seu-usuario-github>/produtos-api:v1
```

Depois, torne o package **público** no GitHub (Packages → `produtos-api` → Package settings → Danger Zone → Change visibility → Public) — todo package novo no GHCR nasce privado, e o `az acr import` anônimo do passo seguinte falharia com `403 DENIED` se ficar privado. Alternativa: manter privado e passar `--username <usuario> --password <PAT com read:packages>` no `az acr import`.

> ⚠️ Ajuste `<seu-usuario-github>` para o owner real da imagem no GHCR — ver [Informações que faltam](#️-informações-que-faltam--a-confirmar).

### 3.3. Importar a imagem no ACR do grupo (Cloud Shell)

```bash
ACR_NAME=$(terraform -chdir=terraform output -raw acr_name)

az acr import \
  --name "$ACR_NAME" \
  --source ghcr.io/<seu-usuario-github>/produtos-api:v1 \
  --image produtos-api:v1 \
  --force

# Confirmar
az acr repository list -n "$ACR_NAME" -o table
```

### 3.4. Habilitar o ACI

Com a imagem `produtos-api:v1` já disponível no ACR:

```bash
terraform -chdir=terraform apply -auto-approve -var="aci_enabled=true"
```

O `azurerm_container_group` sobe com:

- 1 vCPU / 2 GB de memória
- Porta `8080` exposta publicamente (`ip_address_type = "Public"`, DNS label `qc-api-<sufixo>`)
- Managed Identity **user-assigned** (`id-aci-qc-<sufixo>`), já com role de leitura no Storage do catálogo
- `restart_policy = "OnFailure"`
- Variável de ambiente `STORAGE_ACCOUNT_CATALOGO` e variável segura `API_SECRET`

> **Nota:** ACI não tem HTTPS built-in. Em produção, colocar Front Door, Application Gateway ou Azure Container Apps na frente (ou usar Container Apps direto, que tem TLS gerenciado).

---

## Testando os endpoints

### Azure Function

```bash
HOSTNAME=$(terraform -chdir=terraform output -raw function_app_default_hostname)

curl -s "$HOSTNAME/api/health" | python3 -m json.tool
curl -s "$HOSTNAME/api/produtos?categoria=moveis" | python3 -m json.tool
curl -s "$HOSTNAME/api/produtos?nome=cadeira" | python3 -m json.tool
curl -s "$HOSTNAME/api/frete?cep_origem=01000000&cep_destino=20000000&peso=2.5" | python3 -m json.tool
```

| Rota | Método | Query params | Descrição |
|---|---|---|---|
| `/api/health` | `GET` | — | Health check da Function |
| `/api/produtos` | `GET` | `categoria` (opcional) | Filtra produtos por categoria (ex.: `moveis`) |
| `/api/produtos` | `GET` | `nome` (opcional) | Filtra produtos por nome/substring (ex.: `cadeira`) |
| `/api/frete` | `GET` | `cep_origem`, `cep_destino`, `peso` (todos obrigatórios) | Calcula frete: `R$ 2,00/kg + taxa fixa de R$ 15,00`; prazo 3 dias se os 2 primeiros dígitos do CEP coincidirem, senão 7 dias |

> **Cold start:** a primeira chamada após um período de inatividade leva de 1 a 3 segundos (Flex Consumption escalando de zero); chamadas seguintes respondem em milissegundos.

### Container no ACI

```bash
ACI_FQDN=$(terraform -chdir=terraform output -raw aci_fqdn)

sleep 60   # aguardar a Managed Identity propagar a role no Storage
curl "http://$ACI_FQDN:8080/health"
curl "http://$ACI_FQDN:8080/produtos?categoria=moveis"
```

| Rota | Método | Query params | Descrição |
|---|---|---|---|
| `/health` | `GET` | — | Health check da API |
| `/produtos` | `GET` | `categoria` (opcional) | Filtra produtos por categoria (ex.: `moveis`) |

> Diferente da Function, aqui **não há prefixo `/api`** — as rotas são servidas direto na raiz pelo FastAPI/Uvicorn. Note também que a rota de frete existe **apenas na Function**, não no container.

### Function × ACI — mesma lógica, runtimes diferentes

| Aspecto | Function `v2-blob` | ACI (container) |
|---|---|---|
| URL | `https://<func>.azurewebsites.net/api/produtos` | `http://<aci>:8080/produtos` |
| TLS | ✅ Built-in | ❌ Não (precisa de proxy/gateway na frente) |
| Cold start | 1–3s | Não há (sempre ligado) |
| Custo idle | $0 | $$ pay-per-second mesmo ocioso |
| Auto-scale | ✅ 0–200 instâncias | ❌ 1 réplica fixa |
| Linguagem/runtime | Python/.NET/JS/Java | Qualquer (aqui: Python 3.11 + FastAPI/Uvicorn) |
| Identidade | Managed Identity SystemAssigned | Managed Identity UserAssigned |

---

## Pipeline CI/CD (GitHub Actions)

O deploy da Function também acontece automaticamente via GitHub Actions, definido em `.github/workflows/deploy-function.yml` na **raiz do repositório** `qc-grupo-05-1AIE` (nível 3, exercício 3.3). O workflow roda em dois jobs sequenciais:

**`build-and-test`** (sempre executa primeiro):
1. Checkout do repositório
2. Setup do Python 3.11
3. Instala `ruff` + `pytest` + `requirements.txt`
4. `ruff check .` (lint)
5. `pytest` (testes)

**`deploy`** (só roda se `build-and-test` passar):
1. Checkout do repositório
2. Autentica no Azure via **OIDC** (`azure/login@v2`), sem secrets em texto plano — usa `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` e `AZURE_SUBSCRIPTION_ID` como GitHub Secrets, mais a permissão `id-token: write` do workflow
3. Instala o Azure Functions Core Tools
4. Publica direto em produção: `func azure functionapp publish <function-app> --python`

**Gatilho:** push na branch `main` que altere arquivos em `qc-grupo-05-aula03/function/**`.

> ⚠️ **Sem slot de staging.** O plano **Flex Consumption (FC1)** usado nesta aula **não suporta deployment slots** ([confirmado na documentação oficial](https://learn.microsoft.com/azure/azure-functions/functions-deployment-slots) — "Flex Consumption plan: Not currently supported"). O rascunho original do workflow publicava em `--slot staging` e depois fazia `az functionapp deployment slot swap`; esse step **precisa ser removido**, publicando direto na Function App de produção como acima. Para um fluxo de zero-downtime "de verdade" em Flex Consumption, a Microsoft recomenda estratégias de *site update* diferentes de slots (ex.: nova revisão + roteamento gradual), fora do escopo desta entrega.

### Configuração necessária no repositório GitHub

| Item | Onde configurar | Observação |
|---|---|---|
| `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` | Settings → Secrets and variables → Actions | Client ID de uma **federated credential** (App Registration) configurada para OIDC com `repo:Pauulloolima/qc-grupo-05-1AIE:ref:refs/heads/main` |
| `AZURE_FUNCTIONAPP_NAME` | `env` no próprio workflow | Ajuste para o output `function_app_name` do `terraform apply` atual |
| `paths` do gatilho e `cd` dentro dos steps | `.github/workflows/deploy-function.yml` | Use `qc-grupo-05-aula03/function/**` e `cd qc-grupo-05-aula03/function` (nome real da pasta no repositório) |

---

## Gerando o ZIP de entrega

Segundo o enunciado oficial da Entrega 03, o ZIP é gerado com `git archive`, extraindo a pasta desta aula do repositório e renomeando-a no processo:

```bash
cd ~/qc-grupo-05          # raiz do repositório clonado (qc-grupo-05-1AIE)
git pull origin main
git archive --format=zip --prefix=qc-grupo-05-aula03/ -o ~/entrega-grupo-05-aula03.zip HEAD:qc-grupo-05-aula03
```

Como o `.github/workflows/` fica na **raiz do repositório** (correto, para o Actions rodar), ele não é capturado pelo `git archive` acima — que só extrai o conteúdo de dentro de `qc-grupo-05-aula03/`. Copie o workflow manualmente para dentro do ZIP antes de subir:

```bash
mkdir -p qc-grupo-05-aula03/.github/workflows
cp .github/workflows/deploy-function.yml qc-grupo-05-aula03/.github/workflows/
zip -u ~/entrega-grupo-05-aula03.zip qc-grupo-05-aula03/.github/workflows/deploy-function.yml

# Conferir o conteúdo final antes de subir
unzip -l ~/entrega-grupo-05-aula03.zip
```

Upload do ZIP no **Portal FIAP**, tarefa "Entrega Aula 3" — apenas 1 membro do grupo faz o upload.

---

## Outputs do Terraform

| Output | Descrição |
|---|---|
| `resource_group_name` | Nome do Resource Group da Aula 3 |
| `catalogo_storage_account_name` | Storage Account do catálogo (com `produtos.csv`) |
| `function_app_name` | Nome da Function App (usar no `func azure functionapp publish`) |
| `function_app_default_hostname` | URL HTTPS da Function App |
| `acr_login_server` | Endereço do ACR (destino do `az acr import`/`docker push`) |
| `acr_name` | Nome curto do ACR (para `az acr` CLI) |
| `aci_fqdn` | FQDN do ACI quando `aci_enabled = true`; senão, mensagem informativa |

```bash
terraform -chdir=terraform output -raw function_app_name
terraform -chdir=terraform output -raw function_app_default_hostname
terraform -chdir=terraform output -raw acr_login_server
terraform -chdir=terraform output -raw acr_name
terraform -chdir=terraform output -raw aci_fqdn
```

---

## Observabilidade (Application Insights)

A Function App está conectada a um **Application Insights** (`appi-qc-aula03-<sufixo>`), alimentado por um **Log Analytics Workspace** (`law-qc-aula03-<sufixo>`, SKU `PerGB2018`, retenção de 30 dias).

Para acompanhar métricas ao vivo:

1. No Portal Azure, acesse o Resource Group da aula → o recurso `appi-qc-aula03-<sufixo>`
2. Abra **Live Metrics** durante uma chamada à Function para ver requisições em tempo real (ver evidência em [`diagramas/print-live-metrics.png`](diagramas/print-live-metrics.png))

Segundo o relatório da entrega: taxa de falha observada de 0%, p95 de latência em torno de 250ms, com o gargalo concentrado em I/O de rede (tempo de leitura do `produtos.csv` no Blob Storage a cada requisição).

---

## Destruindo o ambiente (custo zero)

**Regra de ouro:** sempre destrua o ambiente ao final para evitar custos residuais. Como o Storage do catálogo é criado nesta aula, ele também é removido no destroy.

```bash
cd terraform
terraform destroy -auto-approve -var="aci_enabled=true"
```

> Use `-var="aci_enabled=true"` mesmo no destroy se o ACI chegou a ser habilitado, para que o Terraform reconheça o recurso no state e o remova corretamente.

---

## Troubleshooting

| Sintoma | Causa provável | Solução |
|---|---|---|
| `terraform apply` falha ao criar o Storage Account | Nome de storage account já em uso globalmente (raro, pois usa sufixo aleatório) | Rode `terraform apply` novamente; o sufixo é regerado a cada `taint`/destroy completo |
| Erro de região/quota ao criar recursos | Conta Azure for Students bloqueando `Brazil South` ou sem quota na região padrão | Ajuste `-var="location=<região>"` para uma região liberada na sua assinatura |
| `func azure functionapp publish` falha com erro de runtime | Versão do Python local diferente da runtime da Function (3.12) | Use Python 3.12 no ambiente local ou publique via Cloud Shell |
| ACI não sobe / erro de imagem não encontrada | Imagem `produtos-api:v1` ainda não foi importada no ACR | Rode a Fase 3.3 (`az acr import`) antes de `-var="aci_enabled=true"` |
| `az acr build` falha com `TasksOperationsNotAllowed` | ACR Tasks bloqueado em contas Azure for Students | Use o fluxo GHCR → `az acr import` (Fase 3), não `az acr build` |
| `az acr import` falha com `403 DENIED` | Package no GHCR ainda está privado | Torne o package público (GitHub → Packages → Package settings → Change visibility) ou passe `--username`/`--password` no import |
| `curl` no ACI dá timeout/connection refused logo após o `apply` | Managed Identity ainda propagando a role de leitura no Storage | Aguarde ~60s (`sleep 60`) antes de testar |
| Function não consegue ler o blob | Role assignment ainda propagando (pode levar alguns minutos) | Aguarde alguns minutos após o `apply` e tente novamente |
| Workflow falha no step de `slot swap` / `--slot staging` | Flex Consumption **não suporta** deployment slots | Remova o step de swap e o `--slot staging`; publique direto em produção (ver [Pipeline CI/CD](#pipeline-cicd-github-actions)) |
| `azure/login@v2` falha com erro de credencial | Federated credential (OIDC) não configurada, ou secrets ausentes/errados | Configure a App Registration com federated credential para `repo:Pauulloolima/qc-grupo-05-1AIE:ref:refs/heads/main` e cadastre os 3 secrets |
| Job `build-and-test` falha sem nenhum teste coletado | Não existe nenhum arquivo de teste `pytest` em `function/` | Crie ao menos 1 arquivo `test_*.py` com um teste simples (ex.: da rota `/api/health`) |
| `git archive` gera ZIP vazio ou incompleto | Comando usa `HEAD:aula03` mas a pasta real se chama `qc-grupo-05-aula03` | Ajuste para `HEAD:qc-grupo-05-aula03` (ver [Gerando o ZIP de entrega](#gerando-o-zip-de-entrega)) |
| ZIP de entrega não contém `.github/workflows/` | `git archive` só extrai a subpasta da aula; o workflow vive na raiz do repo | Copie manualmente o `.yml` para dentro do ZIP após o archive (comando na seção acima) |

---

## ⚠️ Informações que faltam / a confirmar

Já incorporei o conteúdo de todos os arquivos enviados até aqui: `function/README.md`, `docker/README.md`, `Dockerfile`, `requirements.txt` de cada pasta, `entrega-grupo-05-aula03.md` (dados do grupo, rota `/api/frete`, métricas do App Insights), o `.github/workflows/deploy-function.yml`, o enunciado oficial da Entrega 03 (estrutura do ZIP + `git archive`) e a confirmação oficial de que Flex Consumption não suporta slots. Restam poucos pontos:

1. **Testes `pytest`** — o workflow roda `pytest` em `function/`, mas não recebi nenhum arquivo de teste. Sem pelo menos 1 teste, o job `build-and-test` falha. Posso escrever um teste básico se você enviar o `function_app.py` completo da `v2-blob`.
2. **Federated credential / App Registration** — não recebi os valores de `AZURE_CLIENT_ID`/`AZURE_TENANT_ID`/`AZURE_SUBSCRIPTION_ID` nem como a federated credential foi configurada. Posso documentar o passo a passo de criação se precisar.
3. **Nome hardcoded `func-qc-h7g8u7`** no workflow — confirme se ainda é o nome real gerado pelo `terraform apply` atual (o sufixo aleatório muda a cada `destroy`/`apply` do zero).
4. **Formato do `data/produtos.csv`** — não recebi o arquivo; se quiser, posso documentar o schema de colunas nesta seção.
5. **`host.json`** de `v1-mock`/`v2-blob` — não recebi o conteúdo; se houver `routePrefix` customizado (diferente do padrão `api`), os exemplos de `curl` da Function precisam ser ajustados.
6. **Owner real do GHCR** — o `docker/README.md` original usa `elthonf` como exemplo (usuário do professor); troquei por `<seu-usuario-github>` genérico. Confirme o usuário/organização real usado pelo grupo para publicar `produtos-api:v1` e se o package ficou público.

Nenhum desses itens bloqueia a entrega — são ajustes de precisão. O que **é bloqueante** é aplicar os pontos 3, 6, 9 e 10 do checklist no início desta conversa (remover slot do workflow, corrigir caminhos, corrigir `git archive`, copiar o workflow pro ZIP) antes de gerar o ZIP final.
