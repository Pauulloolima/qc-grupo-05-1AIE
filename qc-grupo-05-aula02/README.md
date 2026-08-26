# 🧠 Quantum Commerce – Infraestrutura e Scripts de Dados (Aula 02)

## 📂 Estrutura do Projeto

```text
qc-grupo-05-aula02/
├── entrega-grupo-05-aula02.md    # Documento principal da entrega
├── README.md                     # Este guia de execução
├── diagramas/
│   └── arquitetura-qc-aula02.png # Diagrama da arquitetura de dados
├── terraform/                    # Arquivos Terraform (.tf)
│   ├── main.tf
│   ├── variables.tf
│   ├── storage.tf
│   ├── sql.tf
│   ├── cosmos.tf
│   ├── search.tf
│   ├── keyvault.tf
│   └── outputs.tf
└── scripts/                      # Scripts Python
    ├── popular_produtos.py
    ├── popular_reviews.py
    └── indexar_produtos.py
```

---

## ☁️ 1. Provisionamento da Infraestrutura com Terraform

### 🔧 Pré-requisitos
* Conta ativa no Microsoft Azure
* Azure CLI instalada e autenticada (`az login`)
* Terraform instalado (`v1.5+`)
* Permissões de *Contributor* na assinatura

### 🚀 Passo a Passo

1. **Acesse a pasta do projeto**
   ```bash
   cd qc-grupo-05-aula02/terraform
   ```

2. **Inicialize o Terraform**
   ```bash
   terraform init
   ```

3. **Planeje a execução**
   ```bash
   terraform plan
   ```

4. **Aplique a infraestrutura**
   ```bash
   terraform apply
   ```
   > Confirme com `yes` quando solicitado.

5. **Verifique os outputs**
   Ao final, o Terraform exibirá:
   * Nome do grupo de recursos
   * Endpoints do SQL, Cosmos DB e AI Search
   * Nome do Key Vault e Storage
   * Strings de conexão (sensíveis)

   *Estes valores serão usados pelos scripts Python.*

---

## 🐍 2. Execução dos Scripts Python

### 📦 Instale as dependências
Na raiz do projeto, instale os pacotes necessários via pip:
```bash
pip install --user azure-identity azure-keyvault-secrets azure-storage-blob azure-search-documents sentence-transformers "pymongo<4.0" pyodbc

### 🔑 Configure variáveis de ambiente
Defina os nomes e endpoints gerados pelo Terraform:
```bash
export KEY_VAULT_NAME="kv-qc-xxxx"
export SQL_SERVER_NAME="sql-qc-xxxx"
export COSMOS_ACCOUNT_NAME="cosmos-qc-xxxx"
export SEARCH_SERVICE_NAME="srch-qc-xxxx"
```

### 🧩 Scripts e suas funções

| Script | Função | Serviço Azure |
| :--- | :--- | :--- |
| `popular_produtos.py` | Insere catálogo de produtos no banco relacional | Azure SQL Database |
| `popular_reviews.py` | Armazena avaliações e comentários dos clientes | Azure Cosmos DB (MongoDB API) |
| `indexar_produtos.py` | Cria índices vetoriais e semânticos para busca inteligente | Azure AI Search |

### ▶️ Execução dos scripts
```bash
python scripts/popular_produtos.py
python scripts/popular_reviews.py
python scripts/indexar_produtos.py
```

*Cada script buscará suas credenciais no Azure Key Vault, garantindo segurança e isolamento de segredos.*

---

## 🔍 3. Validação e Testes

Após rodar os scripts:
1. Verifique no Azure Portal se os dados foram populados.
2. Teste consultas SQL e buscas semânticas conforme o Exercício 3.
3. Compare resultados entre `LIKE` e *Semantic Search* e registre no `entrega-grupo-05-aula02.md`.
