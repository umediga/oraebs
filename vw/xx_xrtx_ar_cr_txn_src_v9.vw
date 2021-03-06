DROP VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V9;

/* Formatted on 6/6/2016 4:57:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V9
(
   CONCURRENT_PROGRAM_NAME,
   YEAR,
   IMPORT_TOTAL_CNT,
   IMPORT_UNID_CNT,
   IMPORT_UNAPP_CNT,
   IMPORT_APP_CNT
)
AS
   SELECT A.CONCURRENT_PROGRAM_NAME,
          A.year,
          NVL (a.total_count, 0) Import_Total_Cnt,
          NVL (b.UNID_count, 0) Import_UNID_Cnt,
          NVL (c.unapp_count, 0) Import_unapp_cnt,
          NVL (d.app_count, 0) Import_app_cnt
     FROM xx_xrtx_ar_cr_txn_src_v1 A,
          xx_xrtx_ar_cr_txn_src_v2 b,
          xx_xrtx_ar_cr_txn_src_v3 c,
          xx_xrtx_ar_cr_txn_src_v4 d
    WHERE     A.CONCURRENT_PROGRAM_NAME = b.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = b.year(+)
          AND A.CONCURRENT_PROGRAM_NAME = c.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = c.year(+)
          AND A.CONCURRENT_PROGRAM_NAME = d.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = d.year(+);
