import os
import subprocess
from sentence_transformers import SentenceTransformer
from azure.search.documents.indexes import SearchIndexClient
from azure.search.documents.indexes.models import (
    SearchIndex, SimpleField, SearchableField, SearchField,
    SearchFieldDataType, VectorSearch, HnswAlgorithmConfiguration,
    VectorSearchProfile,
)
from azure.search.documents import SearchClient
from azure.core.credentials import AzureKeyCredential

# ---------------------------------------------------------
# Variáveis do Ambiente (Geradas pelo seu Terraform)
# ---------------------------------------------------------
SEARCH_ENDPOINT = "https://srch-qc-fvlnjg.search.windows.net"
SEARCH_SERVICE_NAME = "srch-qc-fvlnjg"
RESOURCE_GROUP = "rg-qc-aula02"
INDEX_NAME = "produtos-vector-index"
DIMENSION = 384  # all-MiniLM-L6-v2 produz vetores 384-dim

def get_admin_key():
    print("→ Buscando Admin Key do AI Search via Azure CLI...")
    cmd = f"az search admin-key show --resource-group {RESOURCE_GROUP} --service-name {SEARCH_SERVICE_NAME} --query primaryKey -o tsv"
    key = subprocess.check_output(cmd, shell=True).decode("utf-8").strip()
    return key

def main():
    admin_key = get_admin_key()
    credential = AzureKeyCredential(admin_key)

    print("2. Carregando modelo de embedding local (all-MiniLM-L6-v2)...")
    model = SentenceTransformer("all-MiniLM-L6-v2")

    print("3. Carregando catálogo de produtos (Mock)...")
    rows = [
        {"id": "PROD-001", "nome": "Cadeira Ergonômica Pro", "descricao": "Cadeira ergonômica com suporte lombar ajustável para dores nas costas.", "categoria": "Móveis"},
        {"id": "PROD-002", "nome": "Monitor Ultrawide 34", "descricao": "Monitor curvo ideal para produtividade e multitarefas.", "categoria": "Eletrônicos"},
        {"id": "PROD-003", "nome": "Teclado Mecânico RGB", "descricao": "Teclado mecânico switch brown, silencioso e confortável.", "categoria": "Acessórios"},
        {"id": "PROD-004", "nome": "Cafeteira Expresso Programável", "descricao": "Cafeteira com timer, presente perfeito para quem ama café.", "categoria": "Eletrodomésticos"},
        {"id": "PROD-005", "nome": "Camiseta Polo Masculina", "descricao": "Camiseta polo 100% algodão, confortável e respirável.", "categoria": "Vestuário"},
        {"id": "PROD-006", "nome": "Cadeira Gamer Vermelha", "descricao": "Cadeira estilo racing com almofadas para pescoço e lombar.", "categoria": "Móveis"}
    ]

    print(f"4. Gerando embeddings de {len(rows)} produtos...")
    textos = [f"{r['nome']}. {r['descricao']}" for r in rows]
    embeddings = model.encode(textos).tolist()
    print(f"✓ Embeddings gerados (dim={len(embeddings[0])})")

    print("5. Criando o índice vetorial no Azure AI Search...")
    index_client = SearchIndexClient(endpoint=SEARCH_ENDPOINT, credential=credential)
    index = SearchIndex(
        name=INDEX_NAME,
        fields=[
            SimpleField(name="id", type=SearchFieldDataType.String, key=True),
            SearchableField(name="nome", type=SearchFieldDataType.String),
            SearchableField(name="descricao", type=SearchFieldDataType.String),
            SimpleField(name="categoria", type=SearchFieldDataType.String, filterable=True),
            SearchField(
                name="content_vector",
                type=SearchFieldDataType.Collection(SearchFieldDataType.Single),
                searchable=True,
                vector_search_dimensions=DIMENSION,
                vector_search_profile_name="produtos-hnsw-profile",
            ),
        ],
        vector_search=VectorSearch(
            algorithms=[HnswAlgorithmConfiguration(name="produtos-hnsw")],
            profiles=[VectorSearchProfile(name="produtos-hnsw-profile", algorithm_configuration_name="produtos-hnsw")],
        ),
    )
    
    try: 
        index_client.delete_index(INDEX_NAME)
    except: 
        pass
    
    index_client.create_index(index)
    print("✓ Índice criado com sucesso!")

    print("6. Indexando produtos e seus vetores no AI Search...")
    search_client = SearchClient(endpoint=SEARCH_ENDPOINT, index_name=INDEX_NAME, credential=credential)
    docs = []
    for i, r in enumerate(rows):
        docs.append({
            "id": r["id"], "nome": r["nome"], "descricao": r["descricao"],
            "categoria": r["categoria"], "content_vector": embeddings[i],
        })
    search_client.upload_documents(docs)
    print(f"✓ {len(docs)} produtos indexados com vetores.")

    print("\n7. Executando testes de Vector Search...")
    queries = [
        "preciso de uma cadeira boa para minha coluna",
        "algo para acompanhar séries",
        "presente para um amigo que ama café",
    ]
    
    for q in queries:
        q_vec = model.encode(q).tolist()
        print(f"\n=== Busca Vetorial: '{q}' ===")
        
        # Usando a classe de busca vetorial direta da SDK atualizada
        results = search_client.search(
            search_text=None,
            vector_queries=[{
                "vector": q_vec,
                "k": 3,
                "fields": "content_vector",
                "kind": "vector"
            }]
        )
        
        for r in results:
            print(f"  [{r.get('@search.score', 0):.4f}] {r.get('nome')}")

if __name__ == "__main__":
    main()