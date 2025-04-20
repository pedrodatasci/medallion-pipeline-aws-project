# 🏗️ Medallion Architecture Pipeline com AWS Glue, S3 e Redshift

Este projeto implementa uma pipeline completa de dados baseada na arquitetura **Medallion** (Raw → Bronze → Silver → Redshift) utilizando apenas **serviços gerenciados da AWS**:

- Coleta de dados públicos da **API Open Brewery DB**
- Armazenamento em **S3 (Raw, Bronze, Silver)**
- Processamento com **AWS Glue**
- Carga final em **Redshift Serverless**

---

## 🔧 Tecnologias Utilizadas

- **AWS S3** — Armazenamento raw/bronze/silver
- **AWS Glue** — Execução de transformações ETL em PySpark
- **AWS Redshift Serverless** — Armazenamento analítico final
- **Terraform** — Infraestrutura como código
- **Bash + Python** — Orquestração da pipeline

---

## 📁 Estrutura do Projeto

```
medallion-pipeline-aws-project/
│
├── ingestion/
│   └── api_collector.py
│
├── etl/
│   ├── bronze_glue.py
│   └── silver_glue.py
│
├── terraform/
│   ├── main.tf
│   ├── iam.tf
│   ├── bucket.tf
│   ├── glue_jobs.tf
│   ├── redshift.tf
│   ├── outputs.tf
│   
│
├── docs/
│   └── flow.png
│
├── run_pipeline.sh
├── requirements.txt
├── README.md
└── .gitignore
```

---

## ⚙️ Pré-Requisitos

- Conta AWS com permissões para Glue, S3, Redshift e IAM
- AWS CLI configurada (`aws configure`)
- Terraform instalado (`>= 1.3.0`)
- Python 3 instalado

---

## 🚀 Como Executar

### 1. Clone o projeto e entre na pasta

```bash
git clone https://github.com/seu-user/medallion-pipeline-aws-project.git
cd medallion-pipeline-aws-project
```

### 2. Provisione a infraestrutura

```bash
cd terraform
terraform init
terraform apply
cd ..
```

> Isso criará:  
> - Bucket S3  
> - Jobs Glue Bronze e Silver  
> - Workgroup Redshift Serverless  
> - Role com permissões adequadas

### 3. Execute a pipeline completa

```bash
chmod +x run_pipeline.sh
./run_pipeline.sh
```

Este script:

- Coleta os dados da API e envia para o S3 (Raw)
- Executa os jobs Glue de Bronze e Silver
- Cria a tabela no Redshift (se não existir)
- Faz o COPY da camada Silver para o Redshift

---

## 🧪 Resultados Esperados

Após a execução completa, os dados estarão disponíveis:

- Em `s3://<bucket>/bronze/` no formato Parquet
- Em `s3://<bucket>/silver/` no formato Parquet
- Na tabela `analytics_db.public.breweries_silver` do Redshift Serverless

---

## 📊 Esquema da Tabela no Redshift

```sql
CREATE TABLE IF NOT EXISTS public.breweries_silver (
    id VARCHAR,
    name VARCHAR,
    brewery_type VARCHAR,
    city VARCHAR,
    state VARCHAR,
    country VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    website_url VARCHAR,
    data_ingestao TIMESTAMP
);
```

---

## 📌 Observações

- A role IAM utilizada no COPY precisa ser **associada manualmente** ao Redshift Workgroup no console AWS.
- O bucket S3 é nomeado automaticamente via Terraform (`openbrewery-data-<sufixo>`).
- Em produção, recomenda-se utilizar o Secrets Manager para a senha do Redshift.

---

## 📈 Diagrama da Pipeline

![Arquitetura](./docs/flowchart.png)

---

## 🧑‍💻 Autor

Pedro Sá — [LinkedIn](https://www.linkedin.com/in/pedro-sofiati-de-sa/)

---