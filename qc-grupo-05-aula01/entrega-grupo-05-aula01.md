# Entrega Aula 01 — Grupo 05

**Disciplina:** Cloud & Cognitive Environments — FIAP MBA AI Engineering & Multi-Agents
**Turma:** 1AIE
**Data de entrega:** 15/08/2026

## Grupo

| # | Nome completo | GitHub | E-mail FIAP |
|---|---------------|--------|-------------|
| 1 | Paulo Edvaldo de Lima | https://github.com/Pauulloolima | rm372769@fiap.com.br |
| 2 | Daniel Luconi Spinelli | https://github.com/dluconi | rm373285@fiap.com.br |


## Distribuição do trabalho

| Membro | Nível assumido | Item específico |
|--------|----------------|-----------------|
| Paulo Edvaldo de Lima | 🟢 N1 | Exercícios 1.1, 1.2, 1.3 |
| Daniel Luconi Spinelli | 🟡 N2 | Exercício 2.1 — Arquitetura QC |
| Daniel Luconi Spinelli | 🟡 N2 | Exercício 2.2 — Comparativo |
| Paulo Edvaldo de Lima | 🔴 N3 (bônus) | Exercício 3.1 — IaC avançado |
| Daniel Luconi Spinelli | 🟢 N1 (apoio) | Revisão das respostas N1 |

> Regra: cada membro deve ter pelo menos uma contribuição. O **rodízio entre aulas** (quem fez N1 antes faz N2 depois) é incentivado e vale o ponto do Critério 4 (ver [rubrica.md](rubrica.md)).

---

## 🟢 Nível 1 — Respostas

### Exercício 1.1 — Mapeamento de modelos de serviço

| Serviço | Modelo (IaaS/PaaS/SaaS/FaaS) | Justificativa |
|---------|------------------------------|---------------|
| Gmail | SaaS | Todo o serviço é gerenciado pelo provedor de e-mail |
| Azure Virtual Machines | IaaS | Infra (computação virtualizada sob demanda), mas o usuário gerencia SO e aplicações |
| Azure App Service (hospedar uma API) | PaaS | Plataforma gerenciada pronta para hospedar o código de aplicações ou APIs |
| AWS Lambda | FaaS | Executa funções de código sob demanda sem necessidade de gerenciar servidores |
| Azure SQL Database | PaaS | Banco de dados relacional gerenciado pelo provedor da nuvem |
| Salesforce CRM | SaaS | Software completo de CRM, preparado para o usuário final |
| Google Kubernetes Engine (GKE) | PaaS/IaaS | PaaS: plataforma de orquestração gerenciada, IaaS: Provisão servidor virtual |
| Azure Blob Storage | IaaS | Infraestrutura básica para armazenamento de objetos e dados não estruturados |
| Azure OpenAI Service | PaaS | Plataforma que fornece APIs gerenciadas de inteligência artificial para desenvolvedores |

### Exercício 1.2 — Os 6 Rs na prática

Leia cada cenário e escolha o R de migração mais adequado (Rehost, Replatform, Refactor, Repurchase, Retire, Retain). Justifique.

**Cenário A: Empresa de logística tem sistema de rastreamento de frotas em servidor físico próprio. Código de 2008, sem documentação, só uma pessoa sabe mexer. Quer migrar rápido para ganhar elasticidade.**
Rehost, subindo o servidor da forma como está para nuvem, pois neste contexto de código antigo, um único responsável e sem documentação fica muito complexo para ser executado em curto espaço de tempo. A solução atende por um período de tempo até que seja executado um Replataform (pequenas otimizações para adaptar a nuvem) ou um Refactor (reescrita da aplicação de forma nativa para nuvem).

**Cenário B: Banco regional usa ERP local de RH. Análise mostra: menos de 5 usuários ativos por mês, dados raramente consultados.**
Retire, além de poucos usuários o dado é raramente acessado, o custo de um Refactor não se justifica. Por segurança, podemos armazenar os dados em um armazenamento frio que tem um baixo custo. 

**Cenário C: Fintech tem API de pagamentos monolítica. Decide aproveitar a migração para refatorar em microserviços com K8s e event-driven.**
Refactor: Reescrever a aplicação de forma nativa em nuvem, dada a complexidade e a necessidade de alta disponibilidade de uma Fintech, esta abordagem não é a mais rápida quanto a execução, mas irá extrair o melhor da nuvem quando finalizada.

**Cenário D: Varejo usa CRM desenvolvido internamente há 15 anos. SaaS de mercado atenderia 90% das necessidades por menor custo.**
Repurchase: Se o SaaS de mercado já atende em 90%, utilizar uma solução pronta costuma ser melhor do que refatorar uma solução tão antiga, um Rehost poderia gerar um alto custo de manutenção no sistema antigo.

**Cenário E: Instituição financeira tem mainframe com dados de clientes que precisa ficar on-premise por exigência do Banco Central.**
Retain, tratando-se do BACEN, a exigência do on-premise é de cunho legal, justificado pela alta criticidade dos dados, não há o que se falar em termos de nuvem pública. 

### Exercício 1.3 — Calculando o impacto do SLA

Sistema de e-commerce com SLA de 99,9%.

**a) Quantas horas de downtime por ano?** 
Downtime anual = 8.760 × (1 - 99,9/100) = 8.760 × (1 - 0,999) = 8.760 × 0,001 = 8,76 horas/ano

**b) Se processa R$ 50.000/hora em vendas, qual o impacto financeiro máximo por ano?** 
Considerando que o sistema processa R$ 50.000/hora em vendas:
Impacto financeiro = Downtime anual (h) × Valor por hora
Impacto financeiro = 8,76 h × R$ 50.000/h = R$ 438.000/ano
Resposta: R$ 438.000,00 por ano (impacto financeiro máximo).

**c) Para reduzir o impacto para menos de R$ 50.000/ano, qual SLA mínimo seria necessário?**
Primeiro, precisamos calcular o máximo de downtime permitido para atingir esse limite:

Downtime máximo (h) = Impacto desejado / Valor por hora = R$ 50.000 / R$ 50.000/h = 1 hora/ano
O SLA necessário:
Downtime anual = 8.760 × (1 - SLA/100) < 1

Isolando o SLA:

1 - SLA/100 < 1 / 8.760 ≈ 0,000114155
SLA/100 > 1 - 0,000114155 = 0,999885845
SLA > 99,9885845%

Resposta: Para obter menos de R$ 50.000/ano de impacto, seria necessário um SLA mínimo de aproximadamente 99,989%.

### Exercício 1.4 — RBAC na prática

Você é o responsável de segurança da Quantum Commerce. Para cada perfil abaixo, escolha a role built-in do Azure mais adequada e justifique:

| Perfil | Role Azure mais adequada | Justificativa |
|--------|--------------------------|---------------|
| Agente de IA que LÊ produtos do Storage para responder ao cliente | Storage Blob Data Reader | Garante apenas a leitura dos dados, bloqueando alterações indevidas |
| Engenheiro de dados que CARREGA novos catálogos no Blob | Storage Blob Data Contributor | ermite gravar catálogos sem dar controle sobre a infraestrutura |
| Time de FinOps que precisa VER custos sem alterar recursos | Reader | Libera visualização de custos e configurações, bloqueando qualquer edição |
| Auditor externo que precisa LER configurações de toda a assinatura | Reader | isibilidade da arquitetura para auditoria, sem acesso aos dados ou modificações |
| Sistema de CI/CD que provisiona infraestrutura via Terraform | Contributor | Provisiona e altera infraestrutura, mas sem poder para gerenciar permissões |

---

## 🟡 Nível 2 — Respostas + Implementação

### Exercício 2.1 — Arquitetura de alto nível: Quantum Commerce

Contexto: A Quantum Commerce é um gigante do e-commerce com 12 países, 5M de SKUs, e quer transformar a experiência de compra com IA conversacional.

Sua tarefa (em grupo): Proponha uma arquitetura de alto nível em cloud para a QC. Identifique:

**1. Camadas da arquitetura — quantas e o que cada uma faz (ex: frontend, API, dados, AI/ML, observabilidade)**

Para suportar a operação da Quantum Commerce e orquestrar sistemas multi-agentes com eficiência, a arquitetura de alto nível deve ser estruturada em 5 camadas principais.

Primeira camada Frontend: atua como o ponto de entrada da aplicação, responsável por absorver o tráfego inicial, distribuir conteúdo estático rapidamente via CDN e proteger a infraestrutura. 

Segunda camada API: onde residem os microsserviços e orquestradores que executam as regras de negócio, gerenciam o estado e coordenam o ciclo de vida dos agentes de IA. 

Terceira camada Dados: focada na persistência segmentada da informação, dividindo-se estrategicamente em bancos relacionais para garantir as transações financeiras e de pedidos, bancos NoSQL para suportar esquemas dinâmicos como avaliações de clientes, e Object Storage para o arquivamento massivo de imagens e arquivos de catálogo. 

Quarta camada IA: Busca Semântica, o motor do sistema RAG, que combina um banco de dados vetorial para armazenar os embeddings dos produtos e realizar buscas por similaridade de significado, operando em conjunto com os Large Language Models (LLMs) para gerar as respostas conversacionais. 

Quinta camada Governança e Observabilidade: atua de forma transversal para garantir a proteção de credenciais em cofres de chaves, gerenciar acessos através de identidades seguras e centralizar a coleta de logs e métricas para o monitoramento contínuo da saúde e dos custos da infraestrutura.

**2. Provedor principal — qual escolheria (Azure, AWS, GCP) e por quê**

Escolhemos Azure, após análisar os principais provedores segundo o quadrande mágico da Gartner, a AWS é a lider global, porém o Azure, no cenário da Quantum Commerce, se destaca por conta da maturidade do ecossistema de IA e RAG, entregando nativamente o Azure AI Search com busca híbrida e reordenação semântica, garantindo maior relevância nas respostas dos agentes conversacionais sem a complexidade de orquestração de múltiplos serviços exigida na AWS. 
Além disso, o Azure lidera o segmento enterprise, atende grandes players do segmento de varejo, ao conectar perfeitamente a computação aos bancos de dados com governança nativa via Managed Identity e Key Vault, garantindo que as credenciais dos agentes nunca fiquem expostas no código.

**3. Serviços por categoria — preencha a tabela:**

| Categoria | Serviço Azure | Alternativa AWS | Alternativa GCP |
|-----------|---------------|-----------------|-----------------|
| Compute (backend) | Azure Functions / Azure Kubernetes Service (AKS) | AWS Lambda / Elastic Kubernetes Service (EKS) | Cloud Functions / Google Kubernetes Engine (GKE) |
| Storage (catálogo, imagens) | Azure Blob Storage | Amazon Simple Storage Service (S3) | Google Cloud Storage |
| Banco relacional | Azure SQL | Amazon RDS / Aurora | Cloud SQL |
| Banco NoSQL | Azure Cosmos DB | Amazon DynamoDB | Cloud Firestore |
| Vector Database | Azure AI Search | Amazon OpenSearch / Pinecone | Vertex AI Search / Pinecone |
| Serviços de IA cognitivos | Azure AI Services (OpenAI) | Amazon Bedrock / SageMaker | Google Vertex AI |
| CDN | Azure Front Door / CDN | Amazon CloudFront | Google Cloud CDN |
| Mensageria/Filas | Azure Service Bus / Event Grid | Amazon SQS / SNS | Google Cloud Pub/Sub |
| Observabilidade (logs/métricas) | Azure Monitor / Application Insights | Amazon CloudWatch | Google Cloud Operations |

**4. Diagrama — feito no Excalidraw (excalidraw.com), draw.io (diagrams.net) ou à mão fotografado. Tudo sem instalação.**
(O diagrama encontra-se anexado na pasta do ZIP em diagramas/arquitetura-qc-aula01.png)

### Exercício 2.2 — Comparativo de custos: 3 provedores

Você precisa recomendar infraestrutura para um projeto de AI Engineering. Use as calculadoras para comparar:

2 VMs com 2 vCPUs e 8 GB RAM (Linux, 24/7)
500 GB de object storage
1 banco gerenciado com 2 vCPUs / 8 GB RAM / 100 GB
10 milhões de requisições/mês para função serverless

| Item | Azure | AWS | GCP | Notas |
|------|-------|-----|-----|-------|
| 2 × VM (2vCPU/8GB) | $ 140,16 | $ 140,16 | $ 134,02 | Azure: D2 v3. AWS: m6i.large. GCP: N4. (Todas x86, dedicada) |
| 500 GB storage | $ 11,44 | $ 11,50 | $ 9,90 | Standard|
| Banco gerenciado | $ 141,44 | $ $129,76 | $ 118,18 | Azure: PostgreSQL. AWS: RDS SQL Server Express. GCP: Cloud SQL MySQL |
| 10M req serverless | $ 1,80 | $ 1,80 | $ 14,97 | Azure: Functions. AWS: Lambda. GCP: Cloud Run |
| Total mensal | $ 294,84 | $283,22 | $ 277,07 ||
| Total anual | $ 3.538,08 | $3.398,64 | $ 3.324,84 ||



Análise:

**a) Qual provedor ficou mais barato? A diferença é significativa?** 
O Google Cloud é o fornecedor mais barato, cerca de 6% em relação ao mais caro (Azure).
Apesar da diferença, em um grande projeto envolveria muito dinheiro, mas considerando uma cotação inicial os preços são próximos, pequenos ajustes teriam maior potêncial na redução do custo. A diferença não justifica um redirecionamento do provedor mais aderente.


**b) Aplicando Reserved Instances de 1 ano no mais caro, o resultado muda?** 
Sim, muda consideravelmente, o provedor Azure, que foi o mais caro, possui saving plans ou a reserva de 1 ano, que reduzem em 30% e 40% o custo total. Para as configurações escolhidas, aplicando a redução seria o provedor mais barato, sendo este portanto um fator muito mais decisivo no tocante ao custo. Custo mensal total de $ 199,45

**c) Além de preço, que outros fatores você consideraria para um projeto de IA?**
Aceleradores e Hardware: Acesso sob demanda e escalável a GPUs/TPUs de alta performance.

O custo é relevante, mas para arquiteturas de IA vários fatores são considerados, pois o desenvolvimento de agentes requer processamento massivo, baixa latência, ecossistema com suporte nativo, etc.. 

Consideramos fatores como:
* Orquestração e MLOps: Suporte nativo a frameworks (como LangChain), CI/CD e versionamento de modelos.
* Latência e Governança: Processamento de IA próximo aos dados para evitar custos e atrasos.
* Compatibilidade de Stack: Facilidade de gestão para ambientes Linux (Ubuntu) e dependências Python
* Observabilidade: Monitoramento contínuo de métricas, logs e desvios (drift) em produção.
* Segurança e Compliance: Conformidade com leis (LGPD), criptografia e controle rigoroso de acesso.
* Resiliência (SLAs): Alta disponibilidade, backups e tolerância a falhas.
* Portabilidade (Evitar Lock-in): Facilidade arquitetural para migrar cargas de trabalho entre diferentes nuvens.
* Ecossistema Especializado: Disponibilidade de ferramentas integradas, como bancos vetoriais e feature stores.
* Otimização Financeira: Auto-scaling eficiente e gestão granular de custos.

### Exercício 2.3 — Estratégia de migração para sua empresa

Pense no seu contexto profissional atual (ou empresa que conhece bem).

**a) Descreva um sistema/workload (sem dados confidenciais — pode ser genérico)** 

O workload é um Sistema Analítico de Monitoramento de Pricing para uma rede de varejo. O fluxo atual consiste na ingestão de dados brutos via arquivos Parquet (8 cargas diárias), que passam por um processo de ETL desenvolvido em Python. Após o processamento e a aplicação das regras de negócio, os dados são armazenados em um banco de dados Microsoft SQL Server e, finalmente, consumidos pelas áreas de negócio através de planilhas Excel ou visões em power bi.
Atualmente o pipeline apresenta falhas frequentes de integração (cargas parciais) e alta latência de processamento. Além disso, as regras de negócio implementadas no código Python estão defasadas, gerando inconsistências nos dados que levam a área de negócio a questionar frequentemente a confiabilidade do indicador. Apesar disso, o sistema é de missão crítica e não pode ser descontinuado.

**b) Qual dos 6 Rs você aplicaria? Justifique custo, risco, ganho, prazo** 

O R adotado neste caso será o Refactor, não seria viável fazer um Rehost, visto que a codificação já requer alteração, este trabalho de ajustar as regras de negócio e analisar o código já está previsto. Dada a importância do dado não é possível excluir.
Existe um risco de refatorar mudando regras de negócio ao mesmo tempo, pode gerar questionamento das áreas de negócio, contudo isto já seria feito, o risco pode ser mitigado com uma validação mais profunda dos critérios durante o desenvolvimento, além disso é necessário acompanhar a questão dos dados carregados parcialmente e rever o fluxo etl, os ganhos são altos pois é um processo mais automatizado, recuperaria a confiança acerca do indicador, o dado seria disponibilizado com maior velocidade e exatidão. O prazo seria de aproximadamente 3 meses devido à necessidade de mapear, reescrever e homologar as regras de negócio junto aos stakeholders.


**c) Que serviço Azure usaria? Estimativa mensal?** 

* Azure Data Lake Storage Gen2: Mantemos como a landing zone dos arquivos Parquet. É o armazenamento mais barato da nuvem (alguns centavos por GB).
* Azure Data Factory (ADF): Para a orquestração e monitoramento das falhas. O custo do ADF é baseado em execuções (você paga por atividade rodada).
* Azure Container Instances (ACI) ou Azure Functions: Em vez de usar um cluster caro como um Databricks, podemos "empacotar" o código Python atual em um container Docker e executá-lo via ACI, orquestrado pelo Data Factory e pagando apenas pelos segundos em que o código estiver processando o dado, sem custo de cluster ocioso ou taxas de licenciamento de software.
* Azure Database for PostgreSQL (Flexible Server): Substitui o Microsoft SQL Server. O PostgreSQL é um banco de dados relacional de código aberto, robusto e com excelente integração com Power BI. Ao usar a versão gerenciada no Azure, você paga apenas pelo hardware (computação e armazenamento), zerando o custo de licença de software que o SQL Server exige.

Estimativa de custo entre US$ 80 e US$ 230, que seria melhor definida após avaliar com mais profundidade as configurações necessarias para estesdados:
* Data Lake + Data Factory: US$ 10 a US$ 30/mês
* Container Instances (Python ETL): US$ 20 a US$ 50/mês (assumindo algumas horas de processamento diário para as 8 cargas).
* PostgreSQL Flexible Server (Camada Burstable ou General Purpose inicial): US$ 50 a US$ 150/mês.


**d) Maior obstáculo técnico ou organizacional? Como endereçaria?**

A baixa observabilidade e a quebra de confiança nos dados incentivam o Shadow IT no Excel. Tecnicamente, o pipeline lida com cargas parciais silenciosas. Na operação, a área de pricing espera atualizações em tempo real, gerando atritos e falsos alarmes, pois a arquitetura real depende estritamente das 8 janelas de micro-batch diárias enviadas pelo fornecedor.

Como endereçaria:

* Data Contracts (Circuit Breakers): Validar a qualidade dos dados antes de gravá-los. Arquivos Parquet parciais ou corrompidos pausam automaticamente o pipeline e alertam a equipe, protegendo a produção.
* Centralização Semântica: Consolidar as regras de negócio no banco de dados e no Power BI, criando a visão única e viabilizando o phase-out seguro das planilhas.
* Gestão de SLOs: Inserir indicadores de Data Freshness no próprio dashboard para educar o usuário e alinhar expectativas.
* CI/CD via Git: Versionar rigorosamente os scripts Python e instruções SQL. Mudanças nas lógicas de pricing passam a exigir Pull Requests, garantindo rastreabilidade histórica, revisão em pares e reduzindo drasticamente os questionamentos.

---

## 🔴 Nível 3 — Bônus (se aplicável)

### Exercício 3.1 — Terraform: Endurecimento de segurança de rede da VM

Para atender à exigência de segurança e isolamento de rede, efetuamos duas alterações principais no código HCL do lab:

1. **Restrição de SSH via Variável (`var.meu_ip`)**:
   - Ajustamos o bloco `security_rule` da regra `SSH` no `azurerm_network_security_group` (`vm-lab-aula01-nsg`), alterando a origem de `*` para `${var.meu_ip}/32`.
   - Adicionamos a variável `meu_ip` em `variables.tf` para que o IP do operador/desenvolvedor seja injetado dinamicamente no `plan`/`apply` (via `curl -s ifconfig.me`).

2. **Criação da Segunda Subnet (`subnet-app`)**:
   - Adicionamos o recurso `azurerm_subnet.subnet_app` com o bloco CIDR `10.0.2.0/24` vinculado à VNet `10.0.0.0/16`.
   - Isso garante o isolamento da futura camada de microserviços/aplicação da Quantum Commerce em uma subnet dedicada.

3. **Validação do Diff no `terraform plan`**:
   - Ao rodar o `terraform plan -var="meu_ip=$MEU_IP"`, o Terraform identificou alterações *in-place* no recurso `azurerm_network_security_group.nsg` (modificação do `source_address_prefix`) e a adição da `azurerm_subnet.subnet_app`.
   - **A VM não foi recriada**, garantindo que o ajuste de segurança ocorra sem *downtime* no servidor.
   - O `outputs.tf` foi mantido expondo o IP público estático da VM (`azurerm_public_ip.pip.ip_address`).

*Os arquivos completos estão salvos na pasta `terraform/` (`main.tf`, `variables.tf`, `outputs.tf`).*

---

### Exercício 3.2 — Bicep equivalente

Traduzimos a topologia do lab para Azure Bicep no arquivo `main.bicep`.

**Comparativo entre os Artefatos IaC**

| Critério | ARM Template (`template.json`) | Terraform (`main.tf`) | Azure Bicep (`main.bicep`) |
|:---|:---:|:---:|:---:|
| **Tamanho (Linhas)** | ~320 linhas | ~140 linhas | ~165 linhas |
| **Sintaxe / Formato** | JSON puro com strings de funções ARM | HCL (HashiCorp Configuration Language) | DSL declarativa nativa da Microsoft |
| **Gerenciamento de Estado** | Sem estado local (estado na API do Azure) | Requer `.tfstate` (local ou remote backend) | Sem estado local (estado mantido na API do Azure) |
| **Legibilidade** | Baixa (muitas aspas, chaves e concatenações) | Alta (estruturado por blocos e variáveis) | Muito Alta (sintaxe concisa e autocompletion) |

**Em que cenário escolheria Bicep sobre Terraform?**
Optaríamos pelo Bicep em cenários onde a infraestrutura é **100% hospedada no Azure** e não há plano de adotar uma estratégia multi-cloud. O Bicep elimina a complexidade de gerenciar e proteger o arquivo de estado `.tfstate` (evitando riscos de lock ou vazamento de segredos), oferece suporte no dia zero para todas as novas APIs do Azure e integra nativamente com a `az CLI` em pipelines de CI/CD do Azure DevOps ou GitHub Actions.

---

### Exercício 3.3 — Desafio de arquitetura: Multi-cloud para a Quantum Commerce

**a) Proposta de Arquitetura Multi-Cloud**
Para evitar aprisionamento tecnológico (*vendor lock-in*) e aumentar a resiliência global da Quantum Commerce, propomos uma arquitetura dividida estrategicamente entre dois provedores principais:

1. **Azure (Nuvem Primária de Aplicação & IA Conversacional)**:
   - **Hospedagem & IA**: Azure App Service / AKS para as APIs do e-commerce + **Azure OpenAI Service** para os agentes inteligentes de atendimento e recomendações baseados em GPT-4.
   - **Justificativa**: A integração nativa e governança enterprise dos modelos da OpenAI fazem do Azure a melhor opção para a camada cognitiva.

2. **AWS (Nuvem de Dados, Storage & Disaster Recovery)**:
   - **Armazenamento de Mídia & DR**: **AWS S3** para hospedagem do catálogo global de imagens/vídeos de produtos + **AWS DynamoDB** para réplicas de leitura de alto rendimento durante datas de pico (ex: Black Friday).
   - **Justificativa**: Alta durabilidade mundial do S3 e facilidade de distribuição de mídias pesadas combinadas com resiliência entre nuvens.

---

**b) 4 Desafios Principais da Arquitetura Multi-Cloud**

1. **Latência de Comunicação Cross-Cloud**:
   - *Problema*: Chamadas de API entre microsserviços no Azure e bancos de dados na AWS adicionam latência de rede).
   - *Mitigação*: Manter acoplamento fraco assíncrono via mensageria (event-driven) e evitar chamadas síncronas bloqueantes entre nuvens.

2. **Identidade e Governança Unificada (IAM)**:
   - *Problema*: Gerenciar credenciais, roles e políticas de acesso separadas no Entra ID (Azure) e no AWS IAM aumenta a superfície de ataque.
   - *Mitigação*: Implementar Federação de Identidade baseada em SAML 2.0 / OIDC usando um Identity Provider centralizado (ex: Entra ID como IdP federado no AWS IAM).

3. **Custos de Saída de Dados (Egress Fees)**:
   - *Problema*: Transferir volumes massivos de dados entre Azure e AWS gera cobranças recorrentes por GB de tráfego de saída.
   - *Mitigação*: Arquitetar o fluxo de dados para que os payloads transmitidos entre nuvens sejam pequenos (ex: eventos JSON via webhook) e sincronizar mídias pesadas apenas em batch.

4. **Observabilidade e Monitoramento Centralizado**:
   - *Problema*: Logs e métricas fragmentados entre Azure Monitor / Log Analytics e AWS CloudWatch dificultam a identificação da causa raiz de falhas.
   - *Mitigação*: Utilizar uma ferramenta de observabilidade neutra de mercado (ex: Datadog, Dynatrace ou pilha Grafana/Prometheus/Loki) agregando dados de ambas as nuvens em um único dashboard.

---

**c) Comparativo IaC Multi-Cloud: Terraform vs. Pulumi**

| Característica | HashiCorp Terraform | Pulumi |
|:---|:---|:---|
| **Linguagem** | HCL (Linguagem Declarativa Proprietária) | Linguagens de programação reais (TypeScript, Python, Go, C#) |
| **Modelo de Estado** | Mantido em arquivo `.tfstate` (local ou remoto) | Mantido no Pulumi Service (SaaS gratuito/pago) ou backend próprio |
| **Suporte aos Provedores** | Excelente e consolidado (Providers AzureRM, AWS, GCP mantidos pelas nuvens) | Excelente (gera providers a partir dos schemas do Terraform ou nativos) |
| **Licenciamento / Preço** | BSL (Business Source License) / Grátis comunidade | Código aberto (Apache 2.0) / Plano SaaS freemium por recursos gerenciados |
| **Quando escolher?** | Quando o time busca uma sintaxe simples, padronizada e puramente declarativa, ideal para sysadmins e DevOps. | Quando a equipe é composta por desenvolvedores que preferem usar loops, classes, testes unitários (Jest/PyTest) e abstrações orientadas a objetos no próprio código IaC. |

---

**d) Estimativa de Custo de Egress: 10 TB/mês (Azure Brazil South ➔ AWS us-east-1)**

* **Volume de tráfego**: 10.000 GB / mês.
* **Origem**: Azure (Região Brazil South).
* **Estrutura de Preço de Saída no Azure**:
  - Primeiros 100 GB/mês: Gratuito.
  - De 100 GB até 10 TB na região LATAM / Brazil South: Média de **US$ 0,085 a US$ 0,12 por GB** (devido ao custo de tráfego local na América Latina).
* **Cálculo Estimado**:
  $$	ext{Volume tributável} = 10.000 	ext{ GB} - 100 	ext{ GB} = 9.900 	ext{ GB}$$
  $$	ext{Custo de Egress no Azure} pprox 9.900 	ext{ GB} 	imes 	ext{US\$ 0,087/GB} pprox \mathbf{	ext{US\$ 861,30 / mês}}$$
* **Impacto Anual**: Aproximadamente **US$ 10.335,00 / ano** apenas de taxa de tráfego de saída entre as nuvens.

---

**e) Visão Avançada: Aplicação do Azure Arc e AWS Outposts na Quantum Commerce**

* **Azure Arc**: Permitiria à QC estender a governança, políticas de segurança do Entra ID e serviços de dados do Azure (como Azure SQL Managed Instance ou PostgreSQL) para rodar em clusters Kubernetes hospedados na AWS ou no ambiente on-premise da empresa, mantendo o plano de controle centralizado no Azure.
* **AWS Outposts**: Oferece racks de infraestrutura gerenciada da AWS instalados dentro do datacenter físico da QC. Isso permitiria executar serviços nativos da AWS com latência de milissegundos ponta a ponta para sistemas legados locais antes de uma migração total.

---

## Reflexão coletiva

3-5 parágrafos respondendo:

1. O que o grupo aprendeu de mais importante nesta aula?
O maior aprendizado nesta aula foi entender a importância da Infraestrutura como Código (IaC). Subir recursos manualmente pelo portal do Azure parece rápido, mas perde totalmente a rastreabilidade e a reprodutibilidade. Ao trabalhar com o Terraform e o Bicep, vimos como o ciclo init → plan → apply traz previsibilidade, permitindo versionar cada mudança de rede e segurança no repositório do grupo.

2. Como isso se conecta com a arquitetura cloud de uma plataforma agentic?
Isso é fundamental pra trabalhar com agentes de IA. Como o agente depende de vários serviços rodando juntos (bancos de dados, filas, APIs dos modelos), qualquer alteração manual na infra pode fazer ele falhar ou ter comportamentos estranhos. Usando IaC, a gente garante que o ambiente onde o agente roda em dev seja 100% igual ao de produção, sem surpresas.

3. Que decisão arquitetural vocês fariam diferente se começassem o projeto QC hoje?
Desde o primeiro deploy, a gente já começaria com a parte de segurança e rede bem amarrada. Em vez de subir um NSG com a porta SSH aberta pra todo mundo e depois ter que refatorar, o ideal seria já criar a VNet com as subnets separadas (uma pra app e outra pro banco) e travando o acesso via SSH no nosso IP desde o início. Isso teria evitado retrabalho de refatoração depois.

---

## Artefatos do ZIP

- Diagrama: `diagramas/arquitetura-qc-aula01.png`
- Código IaC: `terraform/`
- Scripts: `scripts/`
- Endpoint ativo (se houver): URL pública sem credenciais — apenas para demonstração durante a janela de correção
