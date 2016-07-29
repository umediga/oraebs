DROP VIEW APPS.XX_AR_INVOICE_OUTBOUND_WS_V;

/* Formatted on 6/6/2016 4:59:59 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_AR_INVOICE_OUTBOUND_WS_V
(
   PUBLISH_BATCH_ID,
   PUBLISH_SYSTEMS,
   AR_INVOICE_HEADERS
)
AS
   SELECT xaips.publish_batch_id publish_batch_id,
          CAST (
             MULTISET (SELECT DISTINCT xps.publish_system publish_system
                         FROM xx_ar_invoice_publish_stg xps
                        WHERE xps.publish_batch_id = xaips.publish_batch_id) AS xx_ar_pub_sys_ws_out_tabtyp)
             publish_systems,
          CAST (
             MULTISET (
                SELECT xaihs.*,
                       CAST (
                          MULTISET (
                             SELECT xails.*
                               FROM xx_ar_invoice_lines_stg xails
                              WHERE     xails.customer_trx_id =
                                           xaihs.customer_trx_id
                                    AND xails.publish_batch_id =
                                           xaihs.publish_batch_id
                                    AND xails.publish_batch_id =
                                           xaips.publish_batch_id) AS xx_ar_inv_line_ws_out_tabtyp)
                          ar_invoice_lines
                  FROM xx_ar_invoice_headers_stg xaihs
                 WHERE xaihs.publish_batch_id = xaips.publish_batch_id) AS xx_ar_inv_hdr_ws_out_tabtyp)
             ar_invoice_headers
     FROM (SELECT DISTINCT publish_batch_id
             FROM xx_ar_invoice_publish_stg) xaips;


GRANT SELECT ON APPS.XX_AR_INVOICE_OUTBOUND_WS_V TO XXAPPSREAD;
