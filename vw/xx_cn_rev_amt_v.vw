DROP VIEW APPS.XX_CN_REV_AMT_V;

/* Formatted on 6/6/2016 4:58:45 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_REV_AMT_V
(
   SALESREP_LINE_ID,
   ORG_ID,
   REV_AMT
)
AS
   SELECT DISTINCT
          cust_trx_line_salesrep_id salesrep_line_id,
          org_id,
          NVL (revenue_amount_split, 0) + NVL (non_revenue_amount_split, 0)
             rev_amt
     FROM ra_cust_trx_line_salesreps_all;
