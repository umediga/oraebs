DROP VIEW APPS.XX_OE_ORDER_OUTBOUND_WS_V;

/* Formatted on 6/6/2016 4:58:23 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OE_ORDER_OUTBOUND_WS_V
(
   PUBLISH_BATCH_ID,
   PUBLISH_SYSTEMS,
   OE_ORDER_HEADERS
)
AS
   SELECT xoops.publish_batch_id publish_batch_id,
          CAST (
             MULTISET (SELECT DISTINCT xps.publish_system publish_system
                         FROM xx_oe_order_publish_stg xps
                        WHERE xps.publish_batch_id = xoops.publish_batch_id) AS xx_oe_pub_sys_ws_out_tabtyp)
             publish_systems,
          CAST (
             MULTISET (
                SELECT xoohs.*,
                       CAST (
                          MULTISET (
                             SELECT xools.*
                               FROM xx_oe_order_lines_stg xools
                              WHERE     xools.header_id = xoohs.header_id
                                    AND xools.publish_batch_id =
                                           xoohs.publish_batch_id
                                    AND xools.publish_batch_id =
                                           xoops.publish_batch_id) AS xx_oe_ord_line_ws_out_tabtyp)
                          oe_order_lines
                  FROM xx_oe_order_headers_stg xoohs
                 WHERE xoohs.publish_batch_id = xoops.publish_batch_id) AS xx_oe_ord_hdr_ws_out_tabtyp)
             oe_order_headers
     FROM (SELECT DISTINCT publish_batch_id
             FROM xx_oe_order_publish_stg) xoops;
