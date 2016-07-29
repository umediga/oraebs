DROP VIEW APPS.XX_XRTX_AR_TXN_OU_SRC_V9;

/* Formatted on 6/6/2016 4:56:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_TXN_OU_SRC_V9
(
   OPERATING_UNIT,
   SOURCE_NAME,
   CREATION_DATE,
   TRANSACTION_NAME,
   TOTAL_CNT,
   OPEN_CNT,
   INCOMPLETE_CNT,
   CLOSE_CNT
)
AS
   SELECT A.operating_unit,
          a.source_name,
          A.creation_date,
          a.transaction_name,
          A.total_count TOTAL_CNT,
          NVL (c.open_ct, 0) OPEN_CNT,
          NVL (b.incomp_ct, 0) INCOMPLETE_CNT,
          NVL (d.close_ct, 0) CLOSE_CNT
     FROM xx_xrtx_ar_txn_ou_src_v1 A,
          xx_xrtx_ar_txn_ou_src_v2 b,
          xx_xrtx_ar_txn_ou_src_v3 c,
          xx_xrtx_ar_txn_ou_src_v4 d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND a.source_name = b.source_name(+)
          AND A.creation_date = b.creation_date(+)
          AND a.transaction_name = b.transaction_name(+)
          AND A.operating_unit = c.operating_unit(+)
          AND a.source_name = c.source_name(+)
          AND A.creation_date = c.creation_date(+)
          AND a.transaction_name = c.transaction_name(+)
          AND A.operating_unit = d.operating_unit(+)
          AND a.source_name = d.source_name(+)
          AND A.creation_date = d.creation_date(+)
          AND a.transaction_name = d.transaction_name(+);
