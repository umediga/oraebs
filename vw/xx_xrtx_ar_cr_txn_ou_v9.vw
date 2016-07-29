DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V9;

/* Formatted on 6/6/2016 4:57:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V9
(
   OPERATING_UNIT,
   YEAR,
   IMPORT_TOTAL_CNT,
   IMPORT_UNID_CNT,
   IMPORT_UNAPP_CNT,
   IMPORT_APP_CNT
)
AS
   SELECT A.operating_unit,
          A.year,
          NVL (a.total_count, 0) Import_Total_Cnt,
          NVL (b.UNID_count, 0) Import_UNID_Cnt,
          NVL (c.unapp_count, 0) Import_unapp_cnt,
          NVL (d.app_count, 0) Import_app_cnt
     FROM xx_xrtx_ar_cr_txn_ou_v1 A,
          xx_xrtx_ar_cr_txn_ou_v2 b,
          xx_xrtx_ar_cr_txn_ou_v3 c,
          xx_xrtx_ar_cr_txn_ou_v4 d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.year = b.year(+)
          AND A.operating_unit = c.operating_unit(+)
          AND A.year = c.year(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.year = d.year(+);
