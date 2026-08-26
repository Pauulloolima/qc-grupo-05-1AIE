# Entrega Aula 02 — Grupo 05

**Disciplina:** Cloud & Cognitive Environments — FIAP MBA AI Engineering & Multi-Agents
**Turma:** 1AIE
**Data de entrega:** 26/08/2026

## Grupo

| # | Nome completo | GitHub | E-mail FIAP |
|---|---------------|--------|-------------|
| 1 | Paulo Edvaldo de Lima | https://github.com/Pauulloolima | rm372769@fiap.com.br |
| 2 | Daniel Luconi Spinelli | https://github.com/dluconi | rm373285@fiap.com.br |

## Distribuição do trabalho

| Membro | Nível assumido | Item específico |
|--------|----------------|-----------------|
| Daniel Luconi Spinelli | 🟢 N1 | Exercícios 1.1, 1.2, 1.3, 1.4 |
| Daniel Luconi Spinelli | 🟡 N2 | Exercício 2.1, 2.2, 2.3 |
| Paulo Edvaldo de Lima | 🔴 N3 (bônus) | Exercício 3.1, 3.2, 3.3 |

> Regra: cada membro deve ter pelo menos uma contribuição. O **rodízio entre aulas** (quem fez N1 antes faz N2 depois) é incentivado e vale o ponto do Critério 4 (ver rubrica.md).

---

## 🟢 Nível 1 — Respostas

### Exercício 1.1 — Tipos de Storage

Para cada cenário, escolha **Object Storage**, **File Storage** ou **Block Storage** e justifique em uma frase.

| Cenário | Tipo | Justificativa |
|---------|:----:|---------------|
| **Imagens de produtos (5M SKUs)** | **Object** (Blob) | Alto volume não estruturado, acesso HTTP via CDN. |
| **Disco do SO de VM de banco** | **Block** (Disk) | Latência sub-ms, alto IOPS e atrelado a uma VM. |
| **Pasta compartilhada (10 VMs DevOps)** | **File** (Files) | Montável em múltiplos nós simultâneos via SMB/NFS. |
| **Backup mensal (retenção 7 anos)** | **Object** (Archive) | Custo mínimo (~$0,002/GB), acesso raro, compliance. |
| **Modelos `.pkl` para serving ML** | **Object** (Blob) | Binários versionados baixados via HTTP por containers. |
| **Dump diário de logs para análise** | **Object** (ADLS) | Ingestão append-only, lifecycle e query serverless. |

---

### Exercício 1.2 — Tiers de Acesso (Cálculo)

A Quantum Commerce armazena **2 TB de logs de compras**. Os primeiros 30 dias os logs são consultados para detecção de fraude (Hot). Depois disso, viram dados arquivados de compliance LGPD (Archive, retenção 5 anos).

**a) Quanto custaria 1 mês desses logs se mantidos 100% em Hot tier? (Use ~$0,018/GB/mês)**
**b) Quanto custaria 1 mês desses logs com lifecycle: 30 dias Hot + Archive depois? (Archive ~$0,002/GB/mês)**
**c) Economia anual com a lifecycle policy?**

| Cenário de Armazenamento | Custo Mensal | Custo Anual | Economia |
|--------------------------|:------------:|:-----------:|:--------:|
| **a) 100% Hot Tier** | $36,86 | $442,32 | - |
| **b) Lifecycle Policy (30d Hot + Arch)** | $6,79 | $81,48 | 81,58% |
| **c) Economia Anual Líquida** | **-$30,07** | **-$360,84**| **$360,84/ano** |

**Detalhamento dos Cálculos:**
- **Hot Puro:** $2.048\text{ GB} \times \$0,018 = \mathbf{\$36,86/\text{mês}}$
- **Com Lifecycle (Steady-State Anual):**
  - Parcela Hot (30 dias): $2.048 \times (30/365) \times \$0,018 = \$3,03/\text{mês}$
  - Parcela Archive (335 dias): $2.048 \times (335/365) \times \$0,002 = \$3,76/\text{mês}$
  - Total Mensal Ponderado: $\$3,03 + \$3,76 = \mathbf{\$6,79/\text{mês}}$
- **Economia Anual:** $\$442,32 - \$81,48 = \mathbf{\$360,84/\text{ano}}$ (em 200 TB históricos acumulados, economia $> \mathbf{\$36.000,00/\text{ano}}$).

---

### Exercício 1.3 — Relacional vs NoSQL vs Vector Search

Para cada caso de uso da Quantum Commerce, marque qual tipo de banco é mais adequado e justifique:

| Caso de uso | Relacional (Azure SQL) | NoSQL (Cosmos) | Vector (AI Search) | Justificativa |
|:------------|:----------:|:--------------:|:------------------:|:--------------|
| **Carrinho de compras ativo** | - | X | - | Esquema dinâmico, latência <10ms e expiração via TTL. |
| **Catálogo de produtos (SKU/estoque)** | X | - | - | Consistência ACID estrita para estoque e joins SQL. |
| **Reviews de clientes (texto/score)** | - | X | - | Documentos semiestruturados particionados por produto. |
| **Recomendação de produtos similares**| - | - | X | Busca semântica por embeddings vetoriais (HNSW). |
| **Histórico de pedidos (faturamento)**| X | - | - | Garantias ACID, integridade contábil e fiscal. |
| **Sessão de usuário (expira em 30m)** | - | X | - | Chave-valor em memória, auto-purge (Cosmos/Redis). |
| **Logs de navegação (clickstream)** | - | X | - | Ingestão append-only em escala (Cosmos DB ou ADLS). |

---

### Exercício 1.4 — Azure Key Vault e RBAC (Menor Privilégio)

Você acabou de provisionar o Key Vault da Aula 2. Para cada perfil, escolha a role built-in e justifique:

| Perfil | Role no Key Vault | Justificativa |
|---------------------|-------------------|---------------|
| **Você (Dev / Ops / Admin)** | **Key Vault Secrets Officer** | CRUD completo em segredos sem precisar de `Owner`. |
| **Azure Function (backend QC)** | **Key Vault Secrets User** | Apenas leitura (`get/list`) via Managed Identity. |
| **Auditor de Segurança** | **Key Vault Reader** | Lê metadados no plano de controle sem ver segredos. |
| **Pipeline CI/CD (GitHub Actions)**| **Key Vault Secrets Officer** | Injeção e rotação automatizada com escopo restrito. |
| **Time de FinOps** | **Cost Management Reader** | Acompanha faturamento no portal de custos sem cofre. |

---

## 🟡 Nível 2 — Respostas + Implementação

### Exercício 2.1 — Modelagem de Dados da Quantum Commerce

A Quantum Commerce tem os seguintes domínios: Produtos, Clientes, Pedidos, Carrinhos, Reviews, Busca de produtos, Sessões, Histórico de navegação e Modelos de ML.
**Sua tarefa:** Preencha a matriz de decisão abaixo:

| Domínio | Serviço Azure | SKU / Configuração | Justificativa Arquitetural |
|---------|---------------|--------------------|----------------------------|
| **Produtos** (5M SKUs) | Azure SQL Database | Serverless (0.5 - 4 vCores) | Integridade ACID para estoque e joins relacionais. |
| **Clientes** (50M) | Azure Cosmos DB | Autoscale (PK: `/cliente_id`) | Escala horizontal, schema flexível e latência < 10ms. |
| **Pedidos** (10M/mês) | Azure SQL Database | Hyperscale (vCore-based) | Alta criticidade transacional, faturamento fiscal. |
| **Carrinhos** (500k) | Azure Cosmos DB | Serverless (TTL: 86400s) | Leitura/escrita ultra-rápida e auto-purge em 24h. |
| **Reviews** (30M) | Azure Cosmos DB | Autoscale (PK: `/produto_id`) | Suporta texto livre e agregações agrupadas por SKU. |
| **Busca de Produtos** | Azure AI Search | Standard S1 (HNSW + Semantic) | Busca híbrida e vetorial para RAG dos agentes. |
| **Sessões** (1M) | Cache for Redis | Standard C2 (TTL: 1800s) | Lookup em memória RAM sub-ms com expiração em 30m. |
| **Histórico Click** | ADLS Gen2 + Synapse| Parquet + SQL Serverless | Storage econômico com consultas pagas por TB. |
| **Modelos de ML** | Azure Blob Storage | Standard LRS + ML Registry | Repositório centralizado e versionado de `.pkl`/ONNX. |

**Bonus: Desenhe o diagrama da camada de dados completa da QC**

(O diagrama encontra-se anexado na pasta do ZIP em diagramas/arquitetura-qc-aula02.png)

---

### Exercício 2.2 — Plano de Migração de Dados (12 Meses)

A Quantum Commerce hoje tem: 

- Banco Oracle on-premise com 8 TB (produtos + pedidos + clientes)
- 50 TB de imagens em servidor NAS local
- ~200 TB de logs históricos em fitas magnéticas (compliance fiscal)

**Sua tarefa:** Proponha um plano de migração de 12 meses considerando:

**a) Quais dos 6 Rs você usaria para cada repositório atual?**

| Repositório Legado | Volume | 6 Rs | Serviço Destino | Estratégia de Migração |
|--------------------|:------:|:----:|-----------------|------------------------|
| **Oracle On-Premise** | 8 TB | **Replatform/Refact** | Azure SQL Hyperscale + Cosmos| Azure DMS com replicação contínua CDC (Zero Downtime).|
| **NAS Local (Imagens)** | 50 TB | **Rehost** | Blob Storage (Hot) + CDN | Carga via Azure Data Box (100 TB) + sync via AzCopy. |
| **Fitas Magnéticas** | 200 TB | **Retain/Replatform** | Blob Storage (Archive Tier) | Carga via Data Box Heavy; WORM policy para LGPD. |

**b) Quais serviços Azure ficariam com cada um, considerando custo + criticidade?**

- **Crítico (Pedidos/Produtos):** Azure SQL Hyperscale (SLA 99.99%, escalabilidade elástica, backup contínuo).
- **Imagens (50 TB):** Blob Hot + Front Door CDN (caching na borda, redução de payload e carregamento rápido).
- **Logs de Compliance (200 TB):** Blob Archive Tier (custo fixo reduzido a ~$400/mês para 200 TB).

**c) Como migrar sem downtime?**

- **Oracle -> Azure SQL/Cosmos:** Snapshot inicial via **Azure Database Migration Service (DMS)** + sincronização contínua de deltas via **Change Data Capture (CDC)**; cutover final em janela de 5 minutos.
- **NAS -> Blob:** Dispositivo físico **Azure Data Box (100 TB)** para carga inicial + `azcopy sync` incremental final.
- **Fitas -> Archive:** Ingestão massiva via **Azure Data Box Heavy** (1 PB).

**d) Estimativa de custo de egress para os 50 TB de imagens:**

- **Ingress (Entrada na Azure):** **$0,00 (Gratuito)**.
- **Appliance Data Box:** ~$300 por importação de 100 TB.
- **Egress de Produção:** Caching via Front Door / CDN mantendo custo de saída entre **$0,02 e $0,05 por GB**.

**e) Como manter compliance LGPD — onde os dados de brasileiros podem ficar?**

- **Localidade:** Dados de clientes brasileiros alocados obrigatoriamente na região **Brazil South (São Paulo)**.
- **Segurança:** Criptografia TLS 1.3 em trânsito, Customer-Managed Keys (CMK) via Key Vault e Dynamic Data Masking.

---

### Exercício 2.3 — Particionamento no Azure Cosmos DB

No lab da Aula 2, o container `reviews` foi particionado por `produto_id`. Responda:

**a) Por que NÃO seria boa partitioning key: 
    id da review? (3 razões)
    score (1-5)? (2 razões)
    data_da_review (timestamp)? (2 razões)**

| Chave Avaliada | Veredito | Principal Problema Identificado |
|----------------|:--------:|---------------------------------|
| **`id` da review** | Inadequada | Cardinalidade unitária; toda consulta por produto vira cross-partition. |
| **`score` (1 a 5)** | Inadequada | Apenas 5 partições; estoura limite de 20 GB e cria hot partitions. |
| **`data_da_review`** | Inadequada | Hot partition temporal: escritas afunilam na partição do dia atual. |

**b) Por que `produto_id` funciona razoavelmente bem mas pode ter um problema. Qual problema?**

- **Vantagem:** Consultas comuns ("reviews do produto X") rodam como *single-partition query* de custo mínimo.
- **Risco:** Hot partition em produtos best-sellers com volume desproporcional de acessos.

**c) Se a QC quisesse otimizar para "todas as reviews de um cliente específico", como seria a estratégia? (Pesquise sobre "hierarchical partition keys" do Cosmos)**

- **Padrão Materialized View via Change Feed:** O container primário particionado por `/produto_id` alimenta, via **Azure Function**, um container secundário particionado por `/cliente_id`.
- **Hierarchical Partition Keys:** Sub-particionamento nativo em múltiplos níveis: `['/cliente_id', '/produto_id']`.

**d) Estime: se um produto tiver 50.000 reviews, qual o tamanho aproximado da partição? Quanto isso é da quota de 20 GB por partição lógica do Cosmos?**

| Métrica | Valor Estimado |
|---------|:--------------:|
| **Tamanho médio por documento JSON** | ~1,5 KB |
| **Tamanho total (50.000 reviews)** | ~75 MB (0,075 GB) |
| **Quota da partição lógica (Cosmos)**| 20 GB |
| **Ocupação percentual da quota** | **0,375%** |
> **Conclusão:** 50.000 avaliações consomem menos de 0,4% do limite de 20 GB por partição, confirmando que a partição por `produto_id` é plenamente segura.

---

## 🔴 Nível 3 — Bônus (se aplicável)

### Exercício 3.1 — Vector search verdadeira no AI Search

#### Parte A — Execução e Comparativo (Vector Search vs. Semantic Search)

**Resultados da execução das 3 queries (Vector Search com `all-MiniLM-L6-v2`):**

1. **Query:** *"preciso de uma cadeira boa para minha coluna"*
   * **Resultado do modelo:** Camiseta Polo Masculina (Score: 0.6665).
2. **Query:** *"algo para acompanhar séries"*
   * **Resultado do modelo:** Retornos desconexos e mal classificados devido à barreira do idioma.
3. **Query:** *"presente para um amigo que ama café"*
   * **Resultado do modelo:** Cadeira Gamer Vermelha (Score: 0.6133).

**Comparativo: Qual deu resultados mais relevantes? Onde cada um falha?**

* **Mais relevante:** A **Busca Semântica (Semantic Search)** do Azure AI Search entrega resultados infinitamente superiores para este cenário. Ela mapeia corretamente a intenção do usuário brasileiro e retorna produtos condizentes.
* **Onde a Busca Vetorial falha:** Falha catastroficamente quando o modelo de embeddings escolhido (como o `all-MiniLM-L6-v2`) não é treinado para o idioma principal da loja (português). A intenção semântica se perde e os vetores agrupam itens completamente irrelevantes.
* **Onde a Busca Semântica falha:** Pode ser menos eficiente em buscas de correspondência estritamente exata (ex: um cliente buscando um código numérico de peça `SKU-99887`), onde o motor semântico pode tentar trazer produtos "semanticamente parecidos", diluindo a precisão em vez de focar apenas no ID exato.

---

#### Parte B — Reflexão

**1. Por que o modelo `all-MiniLM-L6-v2` é uma má escolha para produção da Quantum Commerce? (Dica: língua portuguesa, latência, qualidade)**

O uso deste modelo em produção para um catálogo de 5 milhões de SKUs apresenta falhas críticas em três frentes:
* **Qualidade e Idioma (Português):** O modelo é otimizado para inglês e possui semântica fraca em português. Nos testes práticos, a busca *"cadeira boa para minha coluna"* recomendou inadequadamente uma **Camiseta Polo Masculina** (score 0.6665), e a query *"presente para um amigo que ama café"* trouxe uma **Cadeira Gamer Vermelha** (score 0.6133). Na Quantum Commerce, isso destruiria a precisão da busca e a conversão de vendas.
* **Baixa Dimensionalidade:** Ele gera vetores curtos, de apenas 384 dimensões. Para um volume massivo de SKUs, esse espaço matemático é muito pequeno para classificar e separar produtos adequadamente, resultando em falsos positivos (itens sobrepostos).
* **Latência e Complexidade (Ops):** Como é um modelo local, processar a busca do cliente (texto → vetor) exigiria manter e escalar um cluster próprio de servidores de inferência. Isso aumenta a latência no e-commerce e a complexidade operacional, em oposição a consumir um serviço escalável gerenciado em nuvem.

**2. Que serviço da Azure você usaria para gerar embeddings em produção? (Dica: Azure OpenAI text-embedding-3-large)**

Para a operação em larga escala da Quantum Commerce, a escolha ideal seria o **Azure OpenAI Service**, utilizando especificamente o modelo **`text-embedding-3-large`**. A escolha se justifica pelos seguintes pilares:
* **Desempenho Multilíngue (Português):** Diferente dos modelos open-source menores, a família de modelos da OpenAI é treinada com um vasto corpus multilíngue. Ele entende as nuances, gírias e o contexto do português brasileiro.
* **Alta Dimensionalidade e Precisão:** O modelo gera vetores robustos de até 3072 dimensões, fornecendo o "espaço" matemático necessário para separar e classificar categorias complexas.
* **Infraestrutura Totalmente Gerenciada (Zero Ops):** Não precisa provisionar clusters de GPU para inferência. A API escala automaticamente entregando latência de milissegundos.
* **Segurança e Conformidade Corporativa:** Os dados enviados para gerar os embeddings pertencem exclusivamente à empresa e não são utilizados para treinar os modelos públicos da OpenAI.

**3. Como você manteria os embeddings atualizados quando produtos novos chegam? (Pipeline incremental)**

A estratégia ideal é evitar o reprocessamento custoso de todo o catálogo e adotar uma arquitetura de **processamento incremental** baseada em *Change Data Capture (CDC)* ou eventos (*Event-driven*).
* **1. Captura (CDC/Eventos):** Monitorar as inserções e atualizações na base transacional (ex: tabela `T_PRODUTOS` no Azure SQL).
* **2. Orquestração:** Utilizar uma DAG no Apache Airflow ou Azure Functions para coletar apenas os registros que sofreram alteração (delta).
* **3. Inferência Pontual:** O pipeline envia apenas o texto desses produtos novos/atualizados para a API do Azure OpenAI.
* **4. Atualização (Upsert):** Os novos vetores são injetados no Azure AI Search utilizando a operação de *Upsert* (*mergeOrUpload*).

**4. Quanto custaria gerar embeddings para 5M de produtos da QC com Azure OpenAI? (Pesquise os preços)**

Aplicando uma estimativa de tokens por sku de 100 tokens (texto curto e-commerce), considerando que o valor é pago por milhão de tokens, custaria aproximadamente **US$ 65,00**.
* **Premissa de tamanho:** `nome + descricao` = 100 tokens médios.
* **Volume total:** 5.000.000 SKUs × 100 tokens = 500.000.000 de tokens.
* **Preço do modelo:** `text-embedding-3-large` ~ **US$ 0,13 / 1M tokens**.
* **Cálculo final:** 500 × US$ 0,13 = **US$ 65,00**.

---

### Exercício 3.2 — Synapse Serverless: query sobre Blob

A QC armazenou os `logs de compras` em formato Parquet no Blob. Em vez de carregar tudo num DWH, vamos usar **Synapse Serverless SQL Pool** para queryar direto no Blob (zero ETL).

**Reporte de Execução:**
* **Total de dados processados na query:** 1 Megabyte (conforme validado na aba "Messages" do Synapse Studio).

#### Reflexão

**1. Por que Synapse Serverless faz sentido para a QC em vez de Synapse Dedicated Pool?**

O modelo *Serverless* cobra apenas pela quantidade de dados processados (Data Scanned) por query, sem custos fixos mensais de infraestrutura ociosa. Para a Quantum Commerce, que precisa analisar logs esporadicamente ou fazer consultas ad-hoc no Data Lake (Blob Storage), essa abordagem é incrivelmente mais barata do que manter um *Dedicated Pool* (que cobra por hora, independentemente de estar rodando queries ou não).

**2. Qual o custo de query: 5 TB processados/mês a $5 por TB?**

O cálculo é direto: 5 TB × US$ 5,00 = **US$ 25,00 por mês**. Um valor irrisório para processar 5.000 Gigabytes de logs analíticos.

**3. Como reduzir custo por query? (Dica: Parquet + partições)**

Para baratear ainda mais as consultas no Serverless, a QC deve abandonar o formato CSV e adotar duas práticas:
* **Formato Parquet:** Sendo um formato colunar, o Parquet permite que o motor do Synapse leia apenas as colunas especificadas no `SELECT` (em vez de ler a linha inteira como no CSV), reduzindo drasticamente os bytes processados.
* **Particionamento:** Organizar os arquivos em pastas lógicas no Data Lake (ex: `ano=2026/mes=01/`). Assim, ao filtrar por data na cláusula `WHERE`, o Synapse aplica o *partition pruning*, ignorando arquivos de outros meses e não cobrando pela leitura deles.

---

### Exercício 3.3 — Benchmark: Cosmos vs SQL vs AI Search

Para a query "buscar produto que melhor responde à pergunta `cadeira ergonômica para dor lombar`", você tem 3 opções na QC: Azure SQL, Cosmos DB ou Azure AI Search.

**Tarefa: Implemente as 3 versões, meça latência média, compare qualidade, compare custo projetado e recomende qual usar.**

| Critério | Azure SQL Database (`LIKE`) | Cosmos DB (NoSQL Document) | Azure AI Search (Vector/Semantic) |
| :--- | :--- | :--- | :--- |
| **Mecanismo de Busca** | Comparação de substring (`LIKE '%cadeira%'`) e filtros exatos. | Leitura direta por ID ou partições (não possui motor nativo de full-text). | Busca vetorial (HNSW) e ranqueamento semântico nativo. |
| **Latência (Estimada)** | **Média/Alta:** O uso de `LIKE` com curingas nas duas pontas força um *Full Table Scan*, ignorando índices. | **Baixa:** < 10ms, porém **impossível** resolver a query sem scan na base inteira. | **Média:** ~50ms a 150ms. Processamento de inferência e cálculo de distância de vetores adiciona leve latência. |
| **Qualidade da Resposta** | **Muito Baixa:** Retorna qualquer produto com a palavra "cadeira", sem entender o contexto de "dor lombar" ou ergonomia. | **Nula:** Bancos documentais não resolvem busca semântica livre sem apoio externo. | **Altíssima:** O vetor entende a intenção clínica ("dor lombar") e traz cadeiras ortopédicas/ergonômicas no topo. |
| **Custo p/ 1M Queries/mês** | **Médio:** Exigiria aumentar a capacidade de vCores (*Compute*) para suportar os pesados *Table Scans*. | **Alto:** 1M de queries fazendo *cross-partition scan* consumiria milhares de RUs velozmente. | **Fixo:** Exigiria um tier pago (ex: *Basic* ou *Standard*), custando a partir de ~$75 a ~$250/mês de forma previsível. |

**Recomendação Arquitetural para a Quantum Commerce**
**Serviço Recomendado:** Azure AI Search (com Vector Search/Semantic Ranker).

**Justificativa Técnica e de Negócios:**
Tentativas de forçar o Azure SQL ou o Cosmos DB a atuarem como motores de busca de texto livre resultam em gargalos de performance (*table scans* ou *cross-partition queries*) e péssima experiência para o cliente final. 
Na realidade de um e-commerce de alto volume, a conversão de vendas morre se a barra de busca for "burra". Se o cliente digita um problema ("dor lombar") e a loja retorna resultados baseados apenas em um `LIKE` exato, ele abandona o carrinho. O Azure AI Search é o único componente dessa arquitetura desenhado especificamente para entender a intenção de compra, processar vetores em milissegundos e abstrair a complexidade de infraestrutura para o agente de IA da Quantum Commerce.

---

## Reflexão coletiva

Nesta aula, o aprendizado mais valioso do grupo foi compreender na prática que não existe uma "bala de prata" em bancos de dados na nuvem. A arquitetura de um e-commerce de alto volume exige a segregação das cargas de trabalho: garantir a consistência ACID no SQL para transações comerciais, absorver picos de dados não estruturados no Cosmos DB e processar intenções reais de compra no AI Search. Além disso, provisionar toda essa complexidade de forma modular via Terraform demonstrou como a infraestrutura como código é vital para a governança.

Essa arquitetura se conecta diretamente com a base de uma plataforma agentic. Agentes de IA são tão inteligentes quanto os dados aos quais têm acesso. Ao separarmos o catálogo no SQL e os reviews no Cosmos, fornecemos fontes estruturadas para as ferramentas (tools) dos agentes. Mais importante, o Azure AI Search com Vector Search atua como o motor de Retrieval-Augmented Generation (RAG), permitindo que os agentes "leiam" o catálogo através de similaridade semântica para responder a perguntas complexas de clientes com latência de milissegundos.

Se começássemos o projeto da Quantum Commerce hoje, nossa principal mudança arquitetural seria na ingestão do Data Lake. Em vez de iniciarmos com arquivos CSV para os logs de navegação e compras, já imporíamos desde o D-0 a padronização em formato Parquet com particionamento temporal (ano/mês/dia). Como vimos no teste do Synapse Serverless, otimizar o formato e o particionamento na raiz não apenas acelera as consultas dos agentes analíticos, mas reduz drasticamente o custo de *data scanned* na nuvem.

---

## Artefatos do ZIP

- **Documento Principal:** `entrega-grupo-aula02.md`
- **README do Projeto:** `README.md`
- **Diagrama da Camada de Dados:** `diagramas/arquitetura-qc-aula02.png`
- **Código Terraform Provisionado:** `terraform/main.tf`, `storage.tf`, `sql.tf`, `cosmos.tf`, `search.tf`, `keyvault.tf`, `variables.tf`, `outputs.tf`
- **Scripts de População e Teste:** `scripts/popular_produtos.py`, `popular_reviews.py`, `indexar_produtos.py`