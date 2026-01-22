WITH master AS (
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
    FROM EWM_MDM_STAGE_TXN_FCY_RK_MASTER
    WHERE SRC_DL = 'DL_DE' AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),
direct AS (
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
    FROM EWM_MDM_STAGE_TXN_FCY_RK_DIRECT
    WHERE SRC_DL = 'DL_DE' AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),
agrmt AS (
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
    FROM EWM_MDM_STAGE_TXN_FCY_RK_AGRMT
    WHERE SRC_DL = 'DL_DE' AND DATA_DT = TO_DATE('20240516', 'YYYYMMDD')
),
joined AS (
    SELECT 
        master.EV_ID,
        master.MSTR_SRC_STM_CD,
        master.MSTR_SRC_STM_KEY,
        master.VLD_FROM_TMS,
        master.VLD_TO_TMS,
        master.PRIM_AR_ID,
        master.FCY_RK,
        master.TXN_BOOK_DT,
        master.TXN_CCY_AMT,
        master.TXN_CCY_CL_CD,
        master.TXN_RSN_TP_CL_CD,
        master.LDGR_CCY_AMT,
        master.LDGR_CCY_CL_CD,
        master.SRC_DL,
        master.DATA_DT
    FROM master
    INNER JOIN direct ON master.EV_ID = direct.EV_ID
    INNER JOIN agrmt ON master.EV_ID = agrmt.EV_ID
),
remdup AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY PRIM_AR_ID, FCY_RK, SRC_DL, MSTR_SRC_STM_KEY ORDER BY PRIM_AR_ID, FCY_RK, SRC_DL, MSTR_SRC_STM_KEY) AS row_num
    FROM joined
)
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
    current_timestamp() AS SYS_INRT_TMS
FROM remdup
QUALIFY row_num = 1;