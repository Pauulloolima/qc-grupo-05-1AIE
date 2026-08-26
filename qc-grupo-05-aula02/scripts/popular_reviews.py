import os
from pymongo import MongoClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import datetime

# ---------------------------------------------------------
# Variáveis do Ambiente (Geradas pelo seu Terraform)
# ---------------------------------------------------------
KEY_VAULT_NAME = "kv-qc-fvlnjg"
DATABASE_NAME  = "qc_ecommerce"
COLLECTION_NAME= "reviews"

def main():
    print("1. Autenticando com credenciais nativas do Cloud Shell...")
    credential = DefaultAzureCredential()

    print(f"2. Buscando Connection String no Key Vault ({KEY_VAULT_NAME})...")
    kv_url = f"https://{KEY_VAULT_NAME}.vault.azure.net"
    secret_client = SecretClient(vault_url=kv_url, credential=credential)
    
    # O nome do segredo foi criado pelo Terraform como 'cosmos-connection'
    cosmos_conn = secret_client.get_secret("cosmos-connection-string").value

    print("3. Conectando ao Azure Cosmos DB (API MongoDB)...")
    client = MongoClient(cosmos_conn)
    db = client[DATABASE_NAME]
    collection = db[COLLECTION_NAME]

    print("4. Inserindo avaliações (reviews) dos clientes...")
    reviews = [
        {
            "produto_id": "PROD-001", 
            "cliente": "Maria Silva", 
            "score": 5, 
            "texto": "Cadeira excelente! Minha dor lombar sumiu em uma semana.", 
            "data": datetime.datetime.now()
        },
        {
            "produto_id": "PROD-001", 
            "cliente": "João Pedro", 
            "score": 4, 
            "texto": "Muito boa, mas a montagem foi um pouco difícil.", 
            "data": datetime.datetime.now()
        },
        {
            "produto_id": "PROD-004", 
            "cliente": "Ana Costa", 
            "score": 5, 
            "texto": "O café sai perfeito. Recomendo muito!", 
            "data": datetime.datetime.now()
        },
        {
            "produto_id": "PROD-006", 
            "cliente": "Lucas Almeida", 
            "score": 2, 
            "texto": "Bonita, mas a espuma é muito dura. Não achei confortável.", 
            "data": datetime.datetime.now()
        }
    ]

    # Inserindo os documentos (JSONs) na coleção
    collection.insert_many(reviews)
    
    print(f"✓ Sucesso! {len(reviews)} reviews integrados ao Azure Cosmos DB.")

if __name__ == "__main__":
    main()