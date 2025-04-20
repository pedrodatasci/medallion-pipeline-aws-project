import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import col
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Argumentos esperados
args = getResolvedOptions(sys.argv, ["JOB_NAME", "S3_BUCKET"])
bucket = args["S3_BUCKET"]

# Inicializa Glue
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

print(f"📦 Silver: lendo dados do bucket {bucket}")
input_path = f"s3://{bucket}/bronze/"
output_path = f"s3://{bucket}/silver/"

# Leitura dos dados Bronze
df_bronze = spark.read.parquet(input_path)

# Seleção e padronização das colunas

df_silver = df_bronze.select(
    col("id"),
    col("name"),
    col("brewery_type"),
    col("city"),
    col("state"),
    col("country"),
    col("latitude").cast("double"),
    col("longitude").cast("double"),
    col("website_url"),
    col("data_ingestao")
)

# Converte para DynamicFrame
dynamic_frame = DynamicFrame.fromDF(df_silver, glueContext, "silver_df")

# Salva como Parquet na camada Silver
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": output_path},
)

print(f"✅ Silver finalizado com sucesso: {output_path}")
job.commit()
