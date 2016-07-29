DROP VIEW APPS.XX_SDC_CUSTOMER_WS_V;

/* Formatted on 6/6/2016 4:58:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_CUSTOMER_WS_V
(
   PUBLISH_BATCH_ID,
   SDC_CUST_ACCOUNT
)
AS
   SELECT xscps.publish_batch_id publish_batch_id,
          CAST (
             MULTISET (
                SELECT xscav.*,
                       CAST (
                          MULTISET (
                             SELECT xscas.*
                               FROM xx_sdc_cust_acc_sites_stg xscas
                              WHERE     xscas.customer_account_id =
                                           xscav.customer_account_id
                                    AND xscas.publish_batch_id =
                                           xscav.publish_batch_id) AS xx_sdc_cust_site_ws_ot_tabtyp)
                          sdc_cust_sites
                  FROM xx_sdc_cust_account_stg xscav
                 WHERE xscav.publish_batch_id = xscps.publish_batch_id) AS xx_sdc_cust_acc_ws_ot_tabtyp)
             sdc_cust_account
     FROM (SELECT DISTINCT publish_batch_id
             FROM xx_sdc_customer_publish_stg) xscps;
