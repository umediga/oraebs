DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V10;

/* Formatted on 6/6/2016 4:57:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V10
(
   OPERATING_UNIT,
   CONCURRENT_PROGRAM_NAME,
   YEAR,
   MANUAL_TOTAL_CNT,
   MANUAL_UNID_CNT,
   MANUAL_UNAPP_CNT,
   MANUAL_APP_CNT
)
AS
   SELECT A.operating_unit,
          a.CONCURRENT_PROGRAM_NAME,
          A.year,
          NVL (a.total_count, 0) Manual_Total_Cnt,
          NVL (b.UNID_count, 0) Manual_UNID_Cnt,
          NVL (c.unapp_count, 0) Manual_unapp_cnt,
          NVL (d.app_count, 0) Manual_app_cnt
     FROM xx_xrtx_ar_cr_txn_ou_src_v5 A,
          xx_xrtx_ar_cr_txn_ou_src_v6 b,
          xx_xrtx_ar_cr_txn_ou_src_v7 c,
          xx_xrtx_ar_cr_txn_ou_src_v8 d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.CONCURRENT_PROGRAM_NAME = b.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = b.year(+)
          AND A.operating_unit = c.operating_unit(+)
          AND A.CONCURRENT_PROGRAM_NAME = c.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = c.year(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.CONCURRENT_PROGRAM_NAME = d.CONCURRENT_PROGRAM_NAME(+)
          AND A.year = d.year(+);
