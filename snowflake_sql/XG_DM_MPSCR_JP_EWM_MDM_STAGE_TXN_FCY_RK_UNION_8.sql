WITH
-- CTE for the first source table
source_table_1 AS (
    SELECT
        EV_ID,
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        FCY_RK,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD,
        SRC_DL,
        DATA_DT
    FROM
        #XG_PS_RDB_DM_MPSCR_DATABASE.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_MDM_STAGE_TXN_FCY_RK_MASTER
    WHERE
        SRC_DL = 'DL_DE'
        AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),

-- CTE for the second source table
source_table_2 AS (
    SELECT
        EV_ID,
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        FCY_RK,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD,
        SRC_DL,
        DATA_DT
    FROM
        #XG_PS_RDB_DM_MPSCR_DATABASE.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_MDM_STAGE_TXN_FCY_RK_DIRECT
    WHERE
        SRC_DL = 'DL_DE'
        AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),

-- CTE for the third source table
source_table_3 AS (
    SELECT
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        FCY_RK,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD,
        SRC_DL,
        DATA_DT
    FROM
        #XG_PS_RDB_DM_MPSCR_DATABASE.$XG_RDB_DM_SCHEMA_MPSCR#.EWM_MDM_STAGE_TXN_FCY_RK_AGRMT
    WHERE
        SRC_DL = 'DL_DE'
        AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),

-- CTE for the union operation
union_table AS (
    SELECT * FROM source_table_1
    UNION ALL
    SELECT * FROM source_table_2
    UNION ALL
    SELECT * FROM source_table_3
),

-- CTE for the deduplication operation
deduplicated_table AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY SRC_DL, PRIM_AR_ID, FCY_RK, MSTR_SRC_STM_KEY ORDER BY SRC_DL, PRIM_AR_ID, FCY_RK, MSTR_SRC_STM_KEY) AS row_num
    FROM
        union_table
    QUALIFY
        row_num = 1
),

-- CTE for the transformation operation
transformed_table AS (
    SELECT
        EV_ID,
        MSTR_SRC_STM_CD,
        MSTR_SRC_STM_KEY,
        VLD_FROM_TMS,
        VLD_TO_TMS,
        PRIM_AR_ID,
        FCY_RK,
        TXN_BOOK_DT,
        TXN_CCY_AMT,
        TXN_CCY_CL_CD,
        TXN_RSN_TP_CL_CD,
        LDGR_CCY_AMT,
        LDGR_CCY_CL_CD,
        SRC_DL,
        DATA_DT,
        CURRENT_TIMESTAMP() AS SYS_INRT_TMS
    FROM
        deduplicated_table
)

-- Final SELECT statement
SELECT
    EV_ID,
    MSTR_SRC_STM_CD,
    MSTR_SRC_STM_KEY,
    VLD_FROM_TMS,
    VLD_TO_TMS,
    PRIM_AR_ID,
    FCY_RK,
    TXN_BOOK_DT,
    TXN_CCY_AMT,
    TXN_CCY_CL_CD,
    TXN_RSN_TP_CL_CD,
    LDGR_CCY_AMT,
    LDGR_CCY_CL_CD,
    SRC_DL,
    DATA_DT,
    SYS_INRT_TMS
FROM
    transformed_table;