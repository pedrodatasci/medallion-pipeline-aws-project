import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import current_timestamp
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame

# Captura argumentos
args = getResolvedOptions(sys.argv, ["JOB_NAME", "S3_BUCKET"])
bucket = args["S3_BUCKET"]

# Inicializa contextos
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

print(f"📦 Bronze: lendo do bucket {bucket}")
input_path = f"s3://{bucket}/raw/"
output_path = f"s3://{bucket}/bronze/"

# Leitura da camada Raw
df_raw = spark.read.json(input_path)

# Adiciona coluna de ingestão
df_bronze = df_raw.withColumn("data_ingestao", current_timestamp())

# Converte para DynamicFrame e salva
dynamic_frame = DynamicFrame.fromDF(df_bronze, glueContext, "bronze_df")
glueContext.write_dynamic_frame.from_options(
    frame=dynamic_frame,
    connection_type="s3",
    format="parquet",
    connection_options={"path": output_path},
)

print(f"✅ Bronze salvo em: {output_path}")
job.commit()
