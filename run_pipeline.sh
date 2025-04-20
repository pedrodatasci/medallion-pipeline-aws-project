#!/bin/bash

set -e

# 🧭 Entra na pasta do Terraform
cd "$(dirname "$0")/terraform"

# 🔧 Obtém os valores de output do Terraform
S3_BUCKET=$(terraform output -raw bucket_name)
BRONZE_JOB=$(terraform output -raw bronze_job_name)
SILVER_JOB=$(terraform output -raw silver_job_name)
SECRET_NAME=$(terraform output -raw redshift_read_user_secret_name)

if [[ -z "$S3_BUCKET" || "$S3_BUCKET" == *"Warning:"* ]]; then
  echo "❌ Falha ao obter nome do S3_BUCKET"
  exit 1
fi

echo "📦 S3_BUCKET: $S3_BUCKET"

# 🔙 Volta para a raiz do projeto
cd ..

# 🐍 Ambiente virtual
echo "🐍 Criando ambiente virtual..."
if [ ! -d ".venv" ]; then
  python -m venv .venv
fi

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
  source .venv/Scripts/activate
else
  source .venv/bin/activate
fi

# 📦 Instala dependências Python
echo "📦 Instalando dependências..."
pip install -r requirements.txt

# 🌦️ Coleta os dados da API
echo "🌦️ Coletando dados da API..."
S3_BUCKET="$S3_BUCKET" python ingestion/api_collector.py

# ⬆️ Envia scripts Glue para o S3
echo "⬆️ Enviando scripts para o S3..."
aws s3 cp etl/bronze_glue.py s3://$S3_BUCKET/scripts/bronze_glue.py
aws s3 cp etl/silver_glue.py s3://$S3_BUCKET/scripts/silver_glue.py

# 🔥 Executa o job Bronze
echo "🔥 Executando job Bronze ($BRONZE_JOB)..."
BRONZE_RUN_ID=$(aws glue start-job-run \
  --job-name "$BRONZE_JOB" \
  --arguments "{\"--S3_BUCKET\":\"$S3_BUCKET\"}" \
  --query "JobRunId" \
  --output text)

echo "⏳ Aguardando Bronze ($BRONZE_RUN_ID)..."
STATUS="RUNNING"
while [[ "$STATUS" == "RUNNING" || "$STATUS" == "STARTING" ]]; do
  sleep 10
  STATUS=$(aws glue get-job-run \
    --job-name "$BRONZE_JOB" \
    --run-id "$BRONZE_RUN_ID" \
    --query "JobRun.JobRunState" \
    --output text)
  echo "⏱ Status Bronze: $STATUS"
done

if [[ "$STATUS" != "SUCCEEDED" ]]; then
  echo "❌ Job Bronze falhou com status: $STATUS"
  exit 1
fi
echo "✅ Bronze finalizado com sucesso!"

# ✨ Executa o job Silver
echo "✨ Executando job Silver ($SILVER_JOB)..."
SILVER_RUN_ID=$(aws glue start-job-run \
  --job-name "$SILVER_JOB" \
  --arguments "{\"--S3_BUCKET\":\"$S3_BUCKET\"}" \
  --query "JobRunId" \
  --output text)

echo "⏳ Aguardando Silver ($SILVER_RUN_ID)..."
STATUS="RUNNING"
while [[ "$STATUS" == "RUNNING" || "$STATUS" == "STARTING" ]]; do
  sleep 10
  STATUS=$(aws glue get-job-run \
    --job-name "$SILVER_JOB" \
    --run-id "$SILVER_RUN_ID" \
    --query "JobRun.JobRunState" \
    --output text)
  echo "⏱ Status Silver: $STATUS"
done

if [[ "$STATUS" != "SUCCEEDED" ]]; then
  echo "❌ Job Silver falhou com status: $STATUS"
  exit 1
fi

echo "✅ Silver finalizado com sucesso!"
echo "🚀 Pipeline Glue executada com sucesso!"

# ========================
# 🚀 Carga no Redshift
# ========================

echo "🔗 Carregando dados no Redshift..."

REDSHIFT_WORKGROUP=$(terraform -chdir=terraform output -raw redshift_workgroup_name)
REDSHIFT_DATABASE=$(terraform -chdir=terraform output -raw redshift_database_name)
REDSHIFT_COPY_ROLE_ARN=$(terraform -chdir=terraform output -raw redshift_copy_role_arn)
TABLE_NAME="public.breweries_silver"
SILVER_PATH="s3://$S3_BUCKET/silver/"

echo "🛠️ Criando tabela no Redshift (se necessário)..."
aws redshift-data execute-statement \
  --workgroup-name "$REDSHIFT_WORKGROUP" \
  --database "$REDSHIFT_DATABASE" \
  --sql "CREATE TABLE IF NOT EXISTS $TABLE_NAME (
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
  );"

echo "📥 Executando COPY da camada Silver para Redshift..."
aws redshift-data execute-statement \
  --workgroup-name "$REDSHIFT_WORKGROUP" \
  --database "$REDSHIFT_DATABASE" \
  --sql "COPY $TABLE_NAME
         FROM '$SILVER_PATH'
         IAM_ROLE '$REDSHIFT_COPY_ROLE_ARN'
         FORMAT AS PARQUET;"

# ========================
# 👤 Criação de usuário de leitura no Redshift
# ========================

echo "👤 Criando usuário de leitura no Redshift..."

SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id $SECRET_NAME \
  --query SecretString \
  --output text)

REDSHIFT_USER=$(echo "$SECRET_JSON" | python -c "import sys, json; print(json.load(sys.stdin)['username'])")
REDSHIFT_PASS=$(echo "$SECRET_JSON" | python -c "import sys, json; print(json.load(sys.stdin)['password'])")

# Verifica se o usuário já existe
USER_EXISTS=$(aws redshift-data execute-statement \
  --workgroup-name "$REDSHIFT_WORKGROUP" \
  --database "$REDSHIFT_DATABASE" \
  --sql "SELECT COUNT(*) FROM pg_user WHERE usename = '$REDSHIFT_USER';" \
  --output text --query "Records[0][0].longValue")

if [[ "$USER_EXISTS" -eq 0 ]]; then
  echo "🔧 Criando usuário $REDSHIFT_USER no Redshift..."
  aws redshift-data execute-statement \
    --workgroup-name "$REDSHIFT_WORKGROUP" \
    --database "$REDSHIFT_DATABASE" \
    --sql "CREATE USER $REDSHIFT_USER PASSWORD '$REDSHIFT_PASS';"
else
  echo "✅ Usuário $REDSHIFT_USER já existe. Pulando criação."
fi

# Aplica permissões
echo "🔐 Garantindo permissões..."
aws redshift-data execute-statement \
  --workgroup-name "$REDSHIFT_WORKGROUP" \
  --database "$REDSHIFT_DATABASE" \
  --sql "GRANT USAGE ON SCHEMA public TO $REDSHIFT_USER;
         GRANT SELECT ON public.breweries_silver TO $REDSHIFT_USER;"

echo "✅ Usuário de leitura garantido!"