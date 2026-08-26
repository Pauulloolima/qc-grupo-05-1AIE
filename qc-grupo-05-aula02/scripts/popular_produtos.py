import os
import pyodbc
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# ---------------------------------------------------------
# Variáveis do Ambiente (Geradas pelo seu Terraform)
# ---------------------------------------------------------
KEY_VAULT_NAME = "kv-qc-fvlnjg"
SQL_SERVER     = "sql-qc-fvlnjg.database.windows.net"
SQL_DB         = "sqldb-qc"
SQL_USER       = "qcadmin"

def main():
    print("1. Autenticando com credenciais nativas do Cloud Shell...")
    credential = DefaultAzureCredential()

    print(f"2. Buscando senha segura no Key Vault ({KEY_VAULT_NAME})...")
    kv_url = f"https://{KEY_VAULT_NAME}.vault.azure.net"
    secret_client = SecretClient(vault_url=kv_url, credential=credential)
    sql_password = secret_client.get_secret("sql-admin-password").value

    print(f"3. Conectando ao banco relacional ({SQL_SERVER})...")
    conn_str = f"DRIVER={{ODBC Driver 18 for SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DB};UID={SQL_USER};PWD={sql_password};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()

    print("4. Garantindo que a tabela 'Produtos' exista...")
    cursor.execute("""
        IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Produtos' and xtype='U')
        CREATE TABLE Produtos (
            id VARCHAR(50) PRIMARY KEY,
            nome VARCHAR(100),
            descricao TEXT,
            categoria VARCHAR(50),
            preco DECIMAL(10,2),
            estoque INT
        )
    """)

    print("5. Inserindo catálogo da Quantum Commerce...")
    produtos = [
        ("PROD-001", "Cadeira Ergonômica Pro", "Cadeira ergonômica com suporte lombar ajustável para dores nas costas.", "Móveis", 1200.00, 50),
        ("PROD-002", "Monitor Ultrawide 34", "Monitor curvo ideal para produtividade e multitarefas.", "Eletrônicos", 2500.00, 30),
        ("PROD-003", "Teclado Mecânico RGB", "Teclado mecânico switch brown, silencioso e confortável.", "Acessórios", 450.00, 100),
        ("PROD-004", "Cafeteira Expresso Programável", "Cafeteira com timer, presente perfeito para quem ama café.", "Eletrodomésticos", 800.00, 20),
        ("PROD-005", "Camiseta Polo Masculina", "Camiseta polo 100% algodão, confortável e respirável.", "Vestuário", 89.90, 200),
        ("PROD-006", "Cadeira Gamer Vermelha", "Cadeira estilo racing com almofadas para pescoço e lombar.", "Móveis", 950.00, 45)
    ]

    # Usamos MERGE para não duplicar dados caso você rode o script duas vezes
    cursor.executemany("""
        MERGE INTO Produtos AS target
        USING (SELECT ? as id, ? as nome, ? as descricao, ? as categoria, ? as preco, ? as estoque) AS source
        ON target.id = source.id
        WHEN NOT MATCHED THEN
            INSERT (id, nome, descricao, categoria, preco, estoque)
            VALUES (source.id, source.nome, source.descricao, source.categoria, source.preco, source.estoque);
    """, produtos)

    conn.commit()
    print(f"✓ Sucesso! {len(produtos)} produtos integrados ao Azure SQL.")

if __name__ == "__main__":
    main()