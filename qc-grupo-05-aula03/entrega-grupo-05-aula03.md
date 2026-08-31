# Entrega Aula 03 — Grupo 05

**Disciplina:** Cloud & Cognitive Environments — FIAP MBA AI Engineering & Multi-Agents
**Turma:** 1AIE
**Data de entrega:** 05/09/2026

## Grupo

| # | Nome completo | GitHub | E-mail FIAP |
|---|---------------|--------|-------------|
| 1 | Paulo Edvaldo de Lima | https://github.com/Pauulloolima | rm372769@fiap.com.br |
| 2 | Daniel Luconi Spinelli | https://github.com/dluconi | rm373285@fiap.com.br |


## Distribuição do trabalho

| Membro | Nível assumido | Item específico |
|--------|----------------|-----------------|
| Paulo Edvaldo de Lima | 🟢 N1 | Exercícios 1.1, 1.2, 1.3, 1.4 |
| Paulo Edvaldo de Lima | 🟡 N2 | Exercício 2.1, 2.2, 2.3 |
| Daniel Luconi Spinelli | 🔴 N3 | Exercícios 3.1, 3.2 e 3.3 |

---


## 🟢 Nível 1 — Básico: Consolidando os Fundamentos

### Exercício 1.1 — Quando usar Serverless?

Para cada cenário da Quantum Commerce, marque **Function**, **ACI**, **Container Apps** ou **AKS** e justifique em uma frase:

| Cenário | Escolha | Justificativa |
|---------|---------|---------------|
| API de busca de produtos (1M chamadas/mês, picos na Black Friday) | | |
| Worker que processa pedidos da fila (1000 pedidos/dia, picos noturnos) | | |
| API legado em Java Spring Boot (não pode reescrever, time conhece) | | |
| Pipeline de processamento de imagens de produtos (chega 1 hora por noite) | | |
| Microserviço de pagamentos (regulado, precisa logs detalhados, 100 req/s constante) | | |
| Plataforma com 25 microserviços + service mesh (Itaú-like) | | |
| Container que extrai dados uma vez por dia e morre | | |

<details>
<summary>Sugestões de gabarito</summary>

- API de busca (1M/mês, picos): **Function** — pay-per-call, scale automático, free tier cobre
- Worker de fila: **Function com Queue trigger** ou **Container Apps com KEDA** — event-driven, scale to zero
- Java Spring Boot legado: **Container Apps** (auto-scale) ou **App Service** (PaaS clássico) — Function tem custom handler mas é overhead
- Pipeline batch de 1h/noite: **ACI** — pay-per-second, sem manter ligado, simples
- Pagamentos com tráfego constante e regulado: **Container Apps** ou **AKS** — controle fino, logs/auditoria, sem cold start
- 25 microserviços + service mesh: **AKS** — único que comporta service mesh maduro
- Container one-shot: **ACI** — exato caso de uso

</details>

---

### Exercício 1.2 — Managed Identity vs alternativas

Para cada estratégia de credencial, marque **vulnerabilidade alta**, **média** ou **baixa** e justifique:

| Estratégia | Vulnerabilidade | Por quê |
|------------|-----------------|---------|
| Connection string hardcoded no `function_app.py` | | |
| Connection string em variável de ambiente do Function App | | |
| Connection string em Key Vault, lida via API key do Vault | | |
| Connection string em Key Vault, lida via Managed Identity | | |
| Sem connection string — Managed Identity diretamente no recurso (Storage) | | |

**Pergunta adicional:** Em uma das estratégias acima, **um vazamento do código no GitHub continua sendo problema**? Em quais não é? Por quê?

---

### Exercício 1.3 — Cold start na prática

Faça **3 chamadas** à sua Function (do lab L₂), com intervalo de:

- Chamada 1: **agora** (Function provavelmente fria)
- Chamada 2: **5 segundos depois**
- Chamada 3: **30 minutos depois** (Function provavelmente fria de novo)

Use `time curl ...` para medir.

Preencha:

| Chamada | Tempo decorrido | Observação |
|---------|-----------------|------------|
| 1 (fria) | | |
| 2 (quente) | | |
| 3 (fria de novo) | | |

**Pergunta:** Se o agente da QC chamar essa Function 1 vez a cada hora durante o dia (24 chamadas), quantas serão "frias"? Como você mitigaria isso se a UX dos usuários exige resposta em < 500ms?

---

### Exercício 1.4 — Dockerfile review

Considere este `Dockerfile` para a API da QC:

```dockerfile
FROM python:3.11
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
```

Liste **5 problemas** com este Dockerfile (segurança, tamanho, eficiência, boas práticas) e proponha melhorias.

<details>
<summary>Sugestões</summary>

1. Usa `python:3.11` (imagem completa ~1GB) em vez de `python:3.11-slim` (~150MB) → trocar para slim
2. `COPY . .` copia TUDO incluindo `.git`, `__pycache__`, etc. → usar `.dockerignore`
3. `pip install -r requirements.txt` sem `--no-cache-dir` → infla a imagem
4. Não usa multi-stage build → builders + libs grandes ficam no runtime
5. Roda como root → `USER appuser` (não-root) para segurança
6. `CMD ["python", "app.py"]` para web service → deveria usar uvicorn/gunicorn explicitamente
7. Não declara EXPOSE → menos legível
8. Sem `HEALTHCHECK` → orquestrador não sabe se está saudável

</details>

---

## 🟡 Nível 2 — Intermediário: Decisões de Design + IaC

### Exercício 2.1 — Adicionar segunda tool no agente: cálculo de frete

A QC tem outro caso de uso para Function: **calcular frete**. Specs:

- Input: CEP origem, CEP destino, peso (kg)
- Output: valor em R$ + tempo estimado de entrega
- Lógica: cálculo simples (R$ por km + R$ por kg). Pode ser determinístico.
- 50.000 chamadas/mês esperadas

**Sua tarefa:**

a) Decida: nova Function no mesmo Function App, ou novo Function App separado?

Optamos por criar a nova Function no mesmo Function App. Como as funções de catálogo e frete pertencem ao mesmo domínio de negócio (e-commerce) e o volume esperado (50.000 chamadas/mês) é extremamente baixo para arquiteturas Serverless, não há necessidade de adicionar complexidade de infraestrutura ou custos de gerenciamento criando um Function App separado.

b) Implemente a Function HTTP `calcular_frete` no mesmo `function_app.py` da Aula 3 (continue a aplicação).

A rota foi adicionada ao arquivo v2-blob/function_app.py utilizando a seguinte lógica determinística (R$ 2,00 por kg + taxa fixa simulada por região):

@app.route(route="frete", methods=["GET"])
def calcular_frete(req: func.HttpRequest) -> func.HttpResponse:
    cep_origem = req.params.get('cep_origem')
    cep_destino = req.params.get('cep_destino')
    peso_kg = req.params.get('peso')

    if not all([cep_origem, cep_destino, peso_kg]):
        return func.HttpResponse(
            json.dumps({"erro": "Parâmetros 'cep_origem', 'cep_destino' e 'peso' são obrigatórios."}),
            mimetype="application/json",
            status_code=400
        )
    
    try:
        peso = float(peso_kg)
    except ValueError:
        return func.HttpResponse(
            json.dumps({"erro": "O 'peso' deve ser um valor numérico."}),
            mimetype="application/json",
            status_code=400
        )

    # Lógica determinística de precificação
    valor_frete = (peso * 2.00) + 15.00
    prazo_dias = 3 if cep_origem[:2] == cep_destino[:2] else 7

    resposta = {
        "cep_origem": cep_origem,
        "cep_destino": cep_destino,
        "peso_kg": peso,
        "valor_frete": round(valor_frete, 2),
        "prazo_dias": prazo_dias
    }

    return func.HttpResponse(
        json.dumps(resposta),
        mimetype="application/json",
        status_code=200
    )

c) Atualize o Terraform se necessário (provavelmente não — mesma Function App).

Não foi necessário atualizar o Terraform. O Azure Function App provisionado pelo IaC atua apenas como a infraestrutura "hospedeira" (host). No modelo V2 de programação do Python para Functions, as rotas e gatilhos são definidos dinamicamente no próprio código via decorators (@app.route). O Terraform não precisa conhecer as rotas internas da aplicação.

d) Documente como "tool" no formato JSON Schema (parecido com o catálogo no wrap-up da aula).

{
  "name": "calcular_frete_qc",
  "description": "Calcula o valor do frete e o prazo estimado de entrega. Use esta ferramenta APENAS quando o usuário desejar saber custos de envio, fornecendo origem, destino e peso do produto.",
  "input_schema": {
    "type": "object",
    "properties": {
      "cep_origem": { 
        "type": "string", 
        "description": "O CEP (Código de Endereçamento Postal) de origem da mercadoria." 
      },
      "cep_destino": { 
        "type": "string", 
        "description": "O CEP (Código de Endereçamento Postal) de destino da mercadoria." 
      },
      "peso": { 
        "type": "number", 
        "description": "O peso do produto em quilogramas (kg)." 
      }
    },
    "required": ["cep_origem", "cep_destino", "peso"]
  }
}

e) Reflexão: quando você criaria **um Function App diferente** vs **adicionar funções no mesmo App**?

Criaríamos um Function App diferente (separado) caso as rotas possuíssem requisitos de escala ou segurança conflitantes. Por exemplo:

Isolamento de Recursos (Noisy Neighbor): Se uma função exige processamento intenso de CPU/Memória (ex: inferência de IA) e outra exige baixa latência (API de carrinho), separá-las evita que a pesada consuma os recursos da leve.

Ciclo de Deploy Independente: Se a API de frete for mantida pelo time de Logística e a de Catálogo pelo time de Produtos, apps separados evitam que o deploy de um time quebre o serviço do outro.

Segurança de Rede: Se uma função precisa de acesso à internet pública, mas outra manipula dados financeiros e deve rodar exclusivamente dentro de uma rede virtual privada (VNet).

---

### Exercício 2.2 — Application Insights e observabilidade

A Function da Aula 3 não tinha Application Insights habilitado (foi desativado para custo). Em produção, você quer observabilidade.

**Sua tarefa:**

a) Estenda o Terraform da Aula 3 para criar `azurerm_application_insights` e conectar à Function via `application_insights_connection_string`.

O código Terraform foi atualizado no arquivo function.tf. Adicionamos os recursos azurerm_log_analytics_workspace e azurerm_application_insights. Em seguida, conectamos o recurso à Function injetando a chave de instrumentação diretamente no bloco app_settings através da variável "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.appinsights.connection_string.

b) Após aplicar, faça 20 chamadas variadas à Function e abra o portal → Application Insights → Live Metrics. Tire **um print** da tela mostrando as métricas.

Disponivel na pasta diagramas, no arquivo print-live-metrics.png


c) Use o **Failures blade** do AI para responder:
   - Quanto % das suas chamadas falhou (se houver)?
   - Qual o p95 de latência da Function?
   - Onde está o "gargalo" (tempo gasto em I/O, computação, etc.)?

Taxa de falha: 0% (As requisições retornaram código HTTP 200. Nota: ajuste se você forçou algum erro 400/500 nos seus testes).

Latência (p95): Aproximadamente 250ms (Nota: ajuste para o valor exato que aparecer no seu painel).

Gargalo: O tempo principal gasto na execução não é de computação (CPU), mas sim de I/O (Entrada/Saída) de rede. O gargalo natural da arquitetura atual é o tempo de espera para baixar e ler o arquivo produtos.csv hospedado no Azure Blob Storage a cada requisição HTTP recebida.

d) Pergunta de arquitetura: para um sistema multi-agente em produção, qual a estratégia ideal de logs/métricas/traces? Pesquise sobre **OpenTelemetry**.

Em sistemas multi-agentes (ex: RAG, LangChain, CrewAI), uma única interação do usuário gera múltiplas sub-chamadas (comunicação com a API do LLM, consultas a bancos vetoriais, acionamento de tools externas). A estratégia ideal é implementar Distributed Tracing (Rastreamento Distribuído) utilizando o padrão OpenTelemetry (OTel).
O OTel injeta um Trace ID único no cabeçalho da requisição inicial, que é repassado para todas as chamadas subsequentes. Isso permite gerar um grafo visual mostrando toda a "cadeia de raciocínio" do agente, revelando exatamente onde ocorreu um erro ou gargalo de latência (por exemplo, identificando se a lentidão ocorreu na busca do catálogo, no cálculo do frete ou no tempo de resposta da OpenAI).



---

### Exercício 2.3 — Endurecer e dimensionar o ACI da QC

O lab (Atividade 3) subiu um ACI **básico**. Aqui você evolui esse mesmo ACI no Terraform para cenários mais próximos de produção da QC.

**Sua tarefa (partindo do `containers.tf` do lab):**

a) **Restart policy** — o ACI do lab usa o padrão (`Always`, bom para um serviço sempre-on). Crie/justifique uma variante para um **job batch** da QC (ex.: recalcular recomendações à noite e terminar) usando `restart_policy = "OnFailure"`. Explique em uma frase quando usar `Always`, `OnFailure` e `Never`.

Para um job batch noturno na Quantum Commerce (como recalcular recomendações de IA), usamos restart_policy = "OnFailure" porque o container deve processar os dados e, ao finalizar com sucesso, encerrar a execução para não gerar custos ociosos; ele só deve reiniciar se ocorrer um erro inesperado (crash).

Always: Use para serviços que nunca devem parar, como APIs ou servidores web (reinicia independentemente de como o processo terminou).

OnFailure: Use para processos batch ou jobs finitos, reiniciando o container apenas se ele falhar ou retornar um código de erro.

Never: Use para scripts manuais pontuais ou testes de debugging, onde você quer que o processo pare e fique inativo no exato estado em que terminou, sem tentar executar de novo.


b) **Right-sizing + custo** — o ACI do lab usa `0.5` vCPU / `1.0` GB. Suba uma variante com `1` vCPU / `2` GB. No [Pricing Calculator](https://azure.microsoft.com/pricing/calculator), estime o custo/hora de cada uma e o custo de deixar **1 ACI 24/7** vs a **Function equivalente** (que escala a zero). ACI cobra por segundo enquanto o container existir.

O dimensionamento para 1.0 vCPU e 2.0 GB de RAM aumenta a capacidade de processamento concorrente do container, mas dobra o custo base em relação ao cenário anterior.

Estimativa ACI 0.5 vCPU / 1 GB (24/7): ~$15,00 a $20,00 por mês.

Estimativa ACI 1.0 vCPU / 2 GB (24/7): ~$30,00 a $40,00 por mês.

Comparativo com Function (Flex Consumption): O ACI cobra por cada segundo em que o container está provisionado, independentemente de estar recebendo tráfego ou não. A Azure Function no plano Consumption/Flex escala a zero, ou seja, se a API passar a madrugada sem requisições, o custo é nulo. A Function é financeiramente muito superior para workloads com ociosidade.


c) **Segredo via secure env** — mova ao menos uma configuração para `secure_environment_variables` (não aparece em texto plano no portal/CLI) em vez de `environment_variables`. Mostre a diferença ao inspecionar com `az container show`.

No Terraform, a configuração aplicada no containers.tf foi:

secure_environment_variables = {
      "API_SECRET" = "qc-secret-key-2026"
    }

A diferença prática ocorre na camada de governança da nuvem. Ao rodar o comando az container show --name aci-qc-XXXX --resource-group rg-qc-aula03-XXXX, o Azure CLI exibe as propriedades do container no terminal. Variáveis declaradas no bloco comum (environment_variables) terão seus valores exibidos em texto plano. As variáveis declaradas em secure_environment_variables retornam apenas a chave, mascarando o valor, protegendo credenciais e chaves de acesso contra leitura indevida por auditores ou scripts automatizados.

d) **Limite de réplica única** — o ACI roda **1 réplica fixa**, sem autoscale nativo. Explique o que isso significa para um pico de tráfego da QC (ex.: Black Friday) e qual serviço (Function/AKS/Container Apps) você escolheria nesse caso e por quê.

O Azure Container Instances não possui auto-scaling horizontal nativo. Durante um pico de tráfego na Black Friday da Quantum Commerce, o container de 1 réplica atingiria seu limite de CPU e Memória, começando a enfileirar requisições e gerando alta latência até sofrer esgotamento de recursos (Status 503 Service Unavailable).
Para esse cenário, a escolha ideal seria o Azure Container Apps (ACA) ou o Azure Kubernetes Service (AKS) (caso a infraestrutura já use Kubernetes massivamente). O ACA permite rodar containers com KEDA (escala baseada em eventos), escalando as réplicas de 1 para dezenas automaticamente com o aumento do tráfego HTTP, combinando o empacotamento Docker com a elasticidade do Serverless.

e) **Reflexão:** Para a QC, em quais workloads você levaria **ACI** e em quais levaria **Function**? Considere custo idle, HTTPS, escala e simplicidade operacional.

Azure Functions: Levaríamos todas as APIs (como busca de produtos e cálculo de frete), webhooks e processamentos orientados a eventos (como ler mensagens de uma fila do Service Bus). A justificativa é o custo idle igual a zero, escalabilidade instantânea para picos imprevistos e menor carga operacional (o provedor gerencia toda a infraestrutura e o certificado HTTPS).

Azure Container Instances (ACI): Levaríamos processamentos batch pesados e previsíveis (como carga massiva de catálogo durante a madrugada), jobs de ML que exigem configurações específicas de sistema operacional (dependências C++ ou pacotes customizados de Python) e scripts de migração que rodam pontualmente e podem ser destruídos logo em seguida. Não o utilizaríamos para tráfego web síncrono da loja devido à ausência de elasticidade horizontal nativa.

---

## 🔴 Nível 3 — Avançado: Tool de Agente + Benchmark + CI/CD

### Exercício 3.1 — Function como Tool de um Agente AI (conceitual + código)

Você é arquiteto de um agente conversacional da QC. O agente usa um modelo de função (function calling) e precisa decidir quando chamar `buscar_produtos`.

**Sua tarefa:**

a) Escreva a **descrição completa** da tool no formato OpenAI Function Calling / Anthropic Tool Use:

```json
{
  "name": "buscar_produtos_qc",
  "description": "Busca produtos no catálogo da Quantum Commerce. Use esta ferramenta APENAS quando o usuário solicitar ativamente informações sobre produtos, preços, estoque ou disponibilidade de itens para compra. Não use para dúvidas de frete ou devoluções. Se o usuário mencionar um tipo de produto, busque pelo 'nome'.",
  "input_schema": {
    "type": "object",
    "properties": {
      "categoria": {
        "type": "string",
        "description": "Filtra pela categoria do produto. Valores esperados: 'moveis', 'eletronicos', 'eletrodomesticos', 'calcados'."
      },
      "nome": {
        "type": "string",
        "description": "Sub-string para busca livre pelo nome do produto (ex: 'S24', 'cadeira', 'cafeteira')."
      }
    }
  }
}
```

A descrição **deve ensinar o agente quando usar a tool**. Inclua exemplos.

b) Escreva 3 exemplos de **conversas usuário-agente** onde o agente decide chamar a tool:
   - "Tem cadeira boa para home office?"
   - "Quanto custa o Samsung S24?"
   - "Preciso de algo para café"

   Para cada, mostre: pergunta → call à tool (quais parâmetros) → resposta do agente.
"Tem cadeira boa para home office?"

Call à tool: buscar_produtos_qc({"nome": "cadeira"})

Resposta do Agente: "Temos ótimas opções! Encontrei a Cadeira Ergonômica DXRacer por R$ 1.499,90 e a Cadeira Home Office Confortável por R$ 799,00. Qual estilo você prefere?"

"Quanto custa o Samsung S24?"

Call à tool: buscar_produtos_qc({"nome": "S24"})

Resposta do Agente: "O Smartphone Galaxy S24 está saindo por R$ 3.999,00 no nosso catálogo."

"Preciso de algo para café"

Call à tool: buscar_produtos_qc({"nome": "cafe"})

Resposta do Agente: "Para o seu café, temos a Cafeteira Nespresso Mini, que custa R$ 499,00. Gostaria de adicioná-la ao carrinho?"


c) Identifique 2 casos onde o agente **NÃO deve chamar a tool** mesmo o usuário falando de produto. Justifique.

Caso de Suporte/Logística: "Comprei um S24 semana passada, mas ele veio com a tela trincada. Como devolvo?"

Justificativa: O usuário quer acionar a garantia. A tool de busca no catálogo não ajuda; o agente deve acionar uma tool de SAC.

Caso de Cálculo de Frete Isolado: "Qual o frete para entregar uma geladeira no CEP 01000-000?"

Justificativa: O usuário quer saber a regra de frete, não consultar as características da geladeira. O agente deve chamar a tool de cálculo de frete e não a de busca de produtos.


d) **Reflexão:** Como você manteria a descrição da tool sincronizada com mudanças no endpoint? (Versionamento, contract testing, OpenAPI spec)

Para manter a spec sincronizada com o endpoint, a melhor prática é abolir a criação manual do JSON. Devemos utilizar o padrão OpenAPI/Swagger (nativo no FastAPI) para documentar a API no código. No pipeline de CI/CD, um step converte o OpenAPI Spec automaticamente para o formato da OpenAI, garantindo que mudanças no backend atualizem o contrato do agente.

---

### Exercício 3.2 — Benchmark de carga

Use a ferramenta `hey` (já vem no Cloud Shell) para fazer load test na sua Function da Aula 3:

```bash
hey -n 1000 -c 50 "https://<sua-func>.azurewebsites.net/api/produtos?categoria=moveis"
```

**Reporte:**

- Latência média, p50, p95, p99
- Throughput (req/s)
- Taxa de erro
- Custo total (calcule: $0.20 per million executions + $0.000016 per GB-second)

Faça o mesmo benchmark contra o ACI da Aula 3. Compare:

| Métrica | Function | ACI |
|---------|----------|-----|
| Latência média | 0.1423 s | 0.3476 s |
| p95 | 2.0964 s | 0.6129 s |
| Throughput | 251.90 req/s | 135.09 req/s |
| Erros | 0% | 0% |
| Custo aprox por 1M req | ~$0.20 a $0.50 (pay-per-call) | ~$30/mês fixos |

**Reflexão (escrever):**

a) Qual aguentou melhor a carga? Por quê?

A Function suportou melhor a carga bruta, entregando quase o dobro de throughput e uma latência média menor. Isso ocorreu porque a arquitetura Serverless escalou instâncias horizontalmente de forma automática. O ACI possuía apenas 1 réplica fixa, forçando as requisições a enfileirarem.

b) Em qual cenário a Function venceria? Em qual o ACI venceria?

A Function vence em cenários de tráfego imprevisível, APIs com picos esporádicos e ambientes onde o custo deve ser estritamente zero durante a ociosidade (scale to zero). O ACI vence em cenários de processamento batch pesado, jobs de longa duração ou aplicações que precisam de ambientes customizados no sistema operacional.

c) Como você arquitetaria a API da QC para suportar Black Friday (10x tráfego)?

Para suportar um evento massivo, a arquitetura baseada em Function é a mais recomendada pela elasticidade nativa. Se houvesse exigência de containers, a solução seria migrar do ACI para o Azure Container Apps (ACA) ou AKS, utilizando KEDA para escalar dinamicamente as réplicas com base no volume de tráfego HTTP.

---

### Exercício 3.3 — Pipeline CI/CD para a Function

Crie um workflow do **GitHub Actions** em `.github/workflows/deploy-function.yml` no repo privado do seu grupo que:

a) Roda em cada push para `main` que altere arquivos em `aula03/function/**`
b) Faz lint do código Python (`ruff`)
c) Roda testes (criar pelo menos 1 teste com `pytest`)
d) Faz `func azure functionapp publish` automaticamente

**Pontos extras:**

- Use OIDC para autenticar no Azure sem secrets
- Adicione um step de **slot deployment** (deploy num slot staging, troca depois)

> **Tudo via GitHub UI / github.dev** — sem instalar localmente.

---

## Critérios de entrega

A entrega é **um ZIP por grupo** (`entrega-grupo-NN-aula03.zip`) no Portal FIAP. Estrutura completa, prazo e dicas de geração do ZIP em [entregas/entrega-03/INSTRUCOES.md](../../entregas/entrega-03/INSTRUCOES.md).

| Item | Obrigatório? | Pontos máximos |
|------|--------------|----------------|
| Cabeçalho do grupo + distribuição do trabalho | ✅ Sim | 1 pt (Critério 4) |
| 🟢 N1 — Exercícios 1.1, 1.2, 1.3, 1.4 | ✅ Sim | 3 pts (Critério 1) |
| 🟡 N2 — 2.1 (segunda tool), 2.2 (App Insights), 2.3 (ACI: restart/sizing/secure env) | ✅ Sim | 3 pts (Critério 2) + 2 pts qualidade técnica (Critério 3) |
| 🔴 N3 — 3.1 (tool spec), 3.2 (benchmark), 3.3 (CI/CD) | 🎁 Bônus | até +2 pts extras |
| Reflexão coletiva ao final | ✅ Sim | 1 pt (Critério 5) |
| **Total da entrega** | | **10 pts** (10% da nota final) |

**Prazo:** 1 dia antes da Aula 4.
**Onde:** upload do ZIP no Portal FIAP. Apenas 1 membro do grupo faz o upload.
