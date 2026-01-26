from pyspark.context import SparkContext
from pyspark.sql.functions import col, lit, to_date, trim
from awsglue.context import GlueContext
from utils import get_option

# Creates spark session
sc = SparkContext.getOrCreate()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

# Initialize Glue parameters
valuation = get_option('valuation')
source_path = get_option('raw_path')
destination_path = get_option('curated_path')
database_name = get_option('curated_database')
# Reads Raw data from S3

partition_path = (
    f"{source_path}/year={valuation.year}/month={valuation.month}/"
)

dyf = glue_context.create_dynamic_frame.from_options(
    connection_type='s3',
    connection_options = {
        "paths": [partition_path]
    },
    format="csv",
    format_options={
        "withHeader": True
    }
)

df = dyf.toDF()
df.show(5)
