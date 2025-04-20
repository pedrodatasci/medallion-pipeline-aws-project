import requests
import json
import boto3
import os
from datetime import datetime

API_URL = "https://api.openbrewerydb.org/v1/breweries"
S3_BUCKET = os.getenv("S3_BUCKET")
S3_FOLDER = "raw"

if not S3_BUCKET:
    raise Exception("Variável de ambiente S3_BUCKET não está definida!")

def fetch_data():
    print("Buscando dados da API Open Brewery DB...")
    response = requests.get(API_URL)
    response.raise_for_status()
    return response.json()

def save_to_s3(data, bucket, folder):
    s3 = boto3.client("s3")
    now = datetime.utcnow().strftime("%Y-%m-%dT%H-%M-%S")
    key = f"{folder}/brewery_data_{now}.json"
    body = json.dumps(data)

    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body.encode("utf-8")
    )
    print(f"Arquivo salvo com sucesso em s3://{bucket}/{key}")

if __name__ == "__main__":
    brewery_data = fetch_data()
    save_to_s3(brewery_data, S3_BUCKET, S3_FOLDER)
