from pyspark.sql import SparkSession
from pyspark.sql.functions import col, current_timestamp, to_date

# Initialize Spark session
spark = SparkSession.builder 
    .appName("DataStage to PySpark Transformation") 
    .getOrCreate()

# Read source tables
df_ewm_ar_x_ar_r = spark.read.table("DM_MPSCR.EWM_AR_X_AR_R")
df_ewm_ev_txn_v = spark.read.table("DM_MPSCR.EWM_EV_TXN_V")

# Apply filters
df_filtered_ewm_ar_x_ar_r = df_ewm_ar_x_ar_r.where(
    (col("SRC_DL") == "DL_DE") &
    (col("vld_from_tms") <= to_date("20240516000000", "yyyymmddhh24miss")) &
    (to_date("20240516000000", "yyyymmddhh24miss") < col("vld_to_tms"))
)

df_filtered_ewm_ev_txn_v = df_ewm_ev_txn_v.where(
    (col("SRC_DL") == "DL_DE") &
    (col("TXN_RSN_TP_CL_CD").isin(
        'FEE_CMSN_PYMT', 'INT_PYMT', 'PNP_PYMT', 'PST_RSL_PYMT', 'TCNQL_PYMT', 'FNC_SVC_PYMT', 'ADL_WRKOUT_COST',
        'ADMIN_RCVR_COST', 'EXT_COST', 'FEE_CMSN_CHRG', 'INT_CHRG', 'LGL_COST', 'LQD_COST', 'PST_RSL_COST',
        'TCNQL_ADVNC_PYMT', 'PNP_ADVNC', 'FNC_SVC_CHRG', 'WRT_OFF', 'FNC_CLM', 'AGRM_NET_SALE'
    )) &
    (col("VLD_FROM_TMS") <= to_date("20240516000000", "YYYYMMDDHH24MISS")) &
    (to_date("20240516000000", "YYYYMMDDHH24MISS") < col("VLD_TO_TMS"))
)

# Select required columns
df_selected_ewm_ar_x_ar_r = df_filtered_ewm_ar_x_ar_r.select("SRC_DL", "OBJ_AR_ID", "SUBJ_AR_ID")
df_selected_ewm_ev_txn_v = df_filtered_ewm_ev_txn_v.select(
    "SRC_DL", "EV_ID", "MSTR_SRC_STM_CD", "MSTR_SRC_STM_KEY", "VLD_FROM_TMS", "VLD_TO_TMS", "PRIM_AR_ID",
    "TXN_BOOK_DT", "TXN_CCY_AMT", "TXN_CCY_CL_CD", "TXN_RSN_TP_CL_CD", "LDGR_CCY_AMT", "LDGR_CCY_CL_CD"
)

# Join dataframes
df_joined = df_selected_ewm_ar_x_ar_r.join(df_selected_ewm_ev_txn_v, on=["SRC_DL"], how="inner")

# Deduplicate rows
from pyspark.sql.window import Window
from pyspark.sql.functions import row_number

window_spec = Window.partitionBy("SRC_DL", "PRIM_AR_ID", "FCY_RK", "MSTR_SRC_STM_KEY").orderBy("SRC_DL")
df_deduplicated = df_joined.withColumn("row_num", row_number().over(window_spec)).where(col("row_num") == 1).drop("row_num")

# Add derived column
df_final = df_deduplicated.withColumn("SYS_INRT_TMS", current_timestamp())

# Write to target table
df_final.write.mode("append").saveAsTable("DM_MPSCR.EWM_MDM_STAGE_TXN_FCY_RK_AGRMT")

# Stop Spark session
spark.stop()
