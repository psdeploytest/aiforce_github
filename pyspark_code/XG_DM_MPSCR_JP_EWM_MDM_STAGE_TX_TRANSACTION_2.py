from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp, to_date

# Initialize Spark session
spark = SparkSession.builder 
    .appName("DataStage to PySpark Transformation") 
    .getOrCreate()

# Read source tables
df_ewm_ar_fwd_txn_v = spark.read.table("DM_MPSCR.EWM_AR_FWD_TXN_V")
df_ewm_ar_fx_txn_v = spark.read.table("DM_MPSCR.EWM_AR_FX_TXN_V")
df_ewm_ar_opt_txn_v = spark.read.table("DM_MPSCR.EWM_AR_OPT_TXN_V")
df_ewm_ar_rprch_agrm_txn_v = spark.read.table("DM_MPSCR.EWM_AR_RPRCH_AGRM_TXN_V")
df_ewm_ar_scr_trd_txn_v = spark.read.table("DM_MPSCR.EWM_AR_SCR_TRD_TXN_V")
df_ewm_ar_swap_txn_v = spark.read.table("DM_MPSCR.EWM_AR_SWAP_TXN_V")

# Union dataframes
df_union = df_ewm_ar_fwd_txn_v.union(df_ewm_ar_fx_txn_v).union(df_ewm_ar_opt_txn_v).union(
    df_ewm_ar_rprch_agrm_txn_v).union(df_ewm_ar_scr_trd_txn_v).union(df_ewm_ar_swap_txn_v)

# Apply filters
df_filtered = df_union.where(
    (col("SRC_DL") == "DL_DE") &
    (col("VLD_FROM_TMS") <= to_date("20240516000000", "YYYYMMDDHH24MISS")) &
    (to_date("20240516000000", "YYYYMMDDHH24MISS") < col("VLD_TO_TMS"))
)

# Select required columns
df_selected = df_filtered.select("SRC_DL", "AR_ID", "VLD_FROM_TMS")

# Add derived columns
df_with_data_dt = df_selected.withColumn("DATA_DT", to_date("20240516", "yyyyMMdd"))
df_final = df_with_data_dt.withColumn("SYS_INRT_TMS", current_timestamp())

# Write to target table
df_final.write.mode("append").saveAsTable("DM_MPSCR.EWM_MDM_STAGE_TX_TRANSACTION")

# Stop Spark session
spark.stop()
