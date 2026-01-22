WITH
-- CTE for the first source table
source_table_1 AS (
    SELECT
        SRC_DL,
        EV_ID,
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD
    FROM
        #XG_PS_RDB_DM_MPSCR_DATABASE.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_EV_TXN_V
    WHERE
        SRC_DL = 'DL_DE'
        AND TXN_RSN_TP_CL_CD IN (
            'FEE_CMSN_PYMT', 'INT_PYMT', 'PNP_PYMT', 'PST_RSL_PYMT', 'TCNQL_PYMT', 'FNC_SVC_PYMT',
            'ADL_WRKOUT_COST', 'ADMIN_RCVR_COST', 'EXT_COST', 'FEE_CMSN_CHRG', 'INT_CHRG',
            'LGL_COST', 'LQD_COST', 'PST_RSL_COST', 'TCNQL_ADVNC_PYMT', 'PNP_ADVNC', 'FNC_SVC_CHRG',
            'WRT_OFF', 'FNC_CLM', 'AGRM_NET_SALE'
        )
        AND VLD_FROM_TMS <= TO_DATE('20240516000000', 'YYYYMMDDHH24MISS')
        AND TO_DATE('20240516000000', 'YYYYMMDDHH24MISS') < VLD_TO_TMS
),

-- CTE for the second source table
source_table_2 AS (
    SELECT
        SRC_DL,
        AR_ID AS SUBJ_AR_ID,
        FCY_RK,
        DATA_DT
    FROM
        #XG_PS_RDB_DM_MPSCR_Database.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_MDM_STAGE_TRANSACTION_FCY
    WHERE
        DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
        AND SRC_DL = 'DL_DE'
),

-- CTE for the third source table
source_table_3 AS (
    SELECT
        OBJ_AR_ID,
        SRC_DL,
        SUBJ_AR_ID
    FROM
        #XG_PS_RDB_DM_MPSCR_Database.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_AR_X_AR_R
    WHERE
        SRC_DL = 'DL_DE'
        AND vld_from_tms <= to_date('20240516000000', 'yyyymmddhh24miss')
        AND to_date('20240516000000', 'yyyymmddhh24miss') < vld_to_tms
),

-- CTE for the join operation
joined_table AS (
    SELECT
        t1.SRC_DL,
        t1.EV_ID,
        t1.MSTR_SRC_STM_CD,
        t1.MSTR_SRC_STM_KEY,
        t1.VLD_FROM_TMS,
        t1.VLD_TO_TMS,
        t1.PRIM_AR_ID,
        t1.TXN_BOOK_DT,
        t1.TXN_CCY_AMT,
        t1.TXN_CCY_CL_CD,
        t1.TXN_RSN_TP_CL_CD,
        t1.LDGR_CCY_AMT,
        t1.LDGR_CCY_CL_CD,
        t2.FCY_RK,
        t2.DATA_DT
    FROM
        source_table_1 t1
    INNER JOIN
        source_table_2 t2
    ON
        t1.SRC_DL = t2.SRC_DL
    INNER JOIN
        source_table_3 t3
    ON
        t1.PRIM_AR_ID = t3.SUBJ_AR_ID
),

-- CTE for the deduplication operation
deduplicated_table AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY SRC_DL, PRIM_AR_ID, FCY_RK, MSTR_SRC_STM_KEY ORDER BY SRC_DL, PRIM_AR_ID, FCY_RK, MSTR_SRC_STM_KEY) AS row_num
    FROM
        joined_table
    QUALIFY
        row_num = 1
),

-- CTE for the transformation operation
transformed_table AS (
    SELECT
        SRC_DL,
        EV_ID,
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD,
        FCY_RK,
        DATA_DT,
        CURRENT_TIMESTAMP() AS SYS_INRT_TMS
    FROM
        deduplicated_table
)

-- Final SELECT statement
SELECT
    SRC_DL,
    EV_ID,
    MSTR_SRC_STM_CD,
    MSTR_SRC_STM_KEY,
    VLD_FROM_TMS,
    VLD_TO_TMS,
    PRIM_AR_ID,
    TXN_BOOK_DT,
    TXN_CCY_AMT,
    TXN_CCY_CL_CD,
    TXN_RSN_TP_CL_CD,
    LDGR_CCY_AMT,
    LDGR_CCY_CL_CD,
    FCY_RK,
    SYS_INRT_TMS,
    DATA_DT
FROM
    transformed_table;