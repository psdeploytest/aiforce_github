from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp, to_timestamp

# Initialize Spark session
spark = SparkSession.builder 
    .appName("DataStage to PySpark Transformation") 
    .getOrCreate()

# Read data from Oracle tables
df_EWM_IP_IDV_V = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_IDV_V") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE'")

df_EWM_IP_ORG_V = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_ORG_V") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE'")

df_EWM_AR_X_IP_R = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_AR_X_IP_R") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE' AND AR_X_IP_RLTNP_TP_CL_CD = 'IP_CST_PD_AR' AND RANK=1")

df_EWM_IP_ALT_IDENTN_VORTEX = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_ALT_IDENTN_M") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE' AND IP_IDENTN_TP_CL_CD='LCL_VORTEX_ID'")

df_EWM_IP_ALT_IDENTN_GRID = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_ALT_IDENTN_M") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE' AND IP_IDENTN_TP_CL_CD = 'GRID_ID'")

df_EWM_IP_X_CL_R = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_X_CL_R") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE'")

df_EWM_IP_X_CL_LC_ST_R = spark.read 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_IP_X_CL_LC_ST_R") 
    .option("user", "username") 
    .option("password", "password") 
    .load() 
    .filter("VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS AND SRC_DL='DL_DE'")

# Perform joins
df_joined = df_EWM_IP_IDV_V.alias("a") 
    .join(df_EWM_IP_ORG_V.alias("b"), (col("a.IP_ID") == col("b.IP_ID")) & (col("a.SRC_DL") == col("b.SRC_DL")), "inner") 
    .join(df_EWM_AR_X_IP_R.alias("c"), (col("a.IP_ID") == col("c.IP_ID")) & (col("a.SRC_DL") == col("c.SRC_DL")), "inner") 
    .join(df_EWM_IP_ALT_IDENTN_VORTEX.alias("d"), (col("a.IP_ID") == col("d.IP_ID")) & (col("a.SRC_DL") == col("d.SRC_DL")), "inner") 
    .join(df_EWM_IP_X_CL_R.alias("e"), (col("a.IP_ID") == col("e.IP_ID")) & (col("a.SRC_DL") == col("e.SRC_DL")), "inner") 
    .join(df_EWM_IP_X_CL_LC_ST_R.alias("f"), (col("a.IP_ID") == col("f.IP_ID")) & (col("a.SRC_DL") == col("f.SRC_DL")), "inner")

# Select and transform columns
df_transformed = df_joined.select(
    col("a.SRC_DL"),
    col("a.MSTR_SRC_STM_KEY").alias("CST_ID"),
    col("a.VLD_FROM_TMS").alias("DATE_FROM"),
    col("d.IP_ID_NM").alias("GRID"),
    col("d.IP_ID_NM").alias("CST_VORTEX_ID"),
    col("e.EFF_DT").alias("RLTNP_STRT_DT"),
    col("f.null").alias("CNTPR_AC_NBR"),
    col("a.VLD_TO_TMS").alias("DATE_TO"),
    col("a.MSTR_SRC_STM_CD").alias("SRC_ID"),
    (col("a.MSTR_SRC_STM_CD") + '|' + col("a.MSTR_SRC_STM_KEY")).alias("CST_RK"),
    current_timestamp().alias("SYS_INRT_TMS"),
    to_timestamp(lit('20240516000000'), 'yyyyMMddHHmmss').alias("DATA_DT")
)

# Write data to target Oracle table
df_transformed.write 
    .format("jdbc") 
    .option("url", "jdbc:oracle:thin:@//hostname:port/service_name") 
    .option("dbtable", "EWM_MDM_STAGE_CUSTOMER") 
    .option("user", "username") 
    .option("password", "password") 
    .mode("append") 
    .save()

# Stop Spark session
spark.stop()
