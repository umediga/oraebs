DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V10;

/* Formatted on 6/6/2016 4:57:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V10
(
   OPERATING_UNIT,
   YEAR,
   MANUAL_TOTAL_CNT,
   MANUAL_UNID_CNT,
   MANUAL_UNAPP_CNT,
   MANUAL_APP_CNT
)
AS
   SELECT A.operating_unit,
          A.year,
          NVL (a.total_count, 0) Manual_Total_Cnt,
          NVL (b.UNID_count, 0) Manual_UNID_Cnt,
          NVL (c.unapp_count, 0) Manual_unapp_cnt,
          NVL (d.app_count, 0) Manual_app_cnt
     FROM xx_xrtx_ar_cr_txn_ou_v5 A,
          xx_xrtx_ar_cr_txn_ou_v6 b,
          xx_xrtx_ar_cr_txn_ou_v7 c,
          xx_xrtx_ar_cr_txn_ou_v8 d
    WHERE     A.operating_unit = b.operating_unit(+)
          AND A.year = b.year(+)
          AND A.operating_unit = c.operating_unit(+)
          AND A.year = c.year(+)
          AND A.operating_unit = d.operating_unit(+)
          AND A.year = d.year(+);
