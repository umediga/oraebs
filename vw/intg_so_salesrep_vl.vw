DROP VIEW APPS.INTG_SO_SALESREP_VL;

/* Formatted on 6/6/2016 5:00:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.INTG_SO_SALESREP_VL
(
   SALESREP_NAME
)
AS
   SELECT DISTINCT name SALESREP_NAME
     FROM (SELECT jrs.name
             FROM jtf_rs_salesreps jrs, oe_sales_credits osc
            WHERE     jrs.status = 'A'
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (start_date_active)
                                          AND TRUNC (
                                                 NVL (end_date_active,
                                                      SYSDATE + 1))
                  AND jrs.salesrep_id = osc.salesrep_id
           UNION
           SELECT jrs.name
             FROM jtf_rs_salesreps jrs, oe_order_headers_all ooh
            WHERE     jrs.status = 'A'
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (start_date_active)
                                          AND TRUNC (
                                                 NVL (end_date_active,
                                                      SYSDATE + 1))
                  AND jrs.org_id = ooh.org_id
                  AND jrs.salesrep_id = ooh.salesrep_id);
