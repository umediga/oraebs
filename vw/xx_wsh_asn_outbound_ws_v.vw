DROP VIEW APPS.XX_WSH_ASN_OUTBOUND_WS_V;

/* Formatted on 6/6/2016 4:57:59 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_WSH_ASN_OUTBOUND_WS_V
(
   PUBLISH_BATCH_ID,
   TARGET_SYSTEM,
   DELIVERIES
)
AS
   SELECT xwaps.publish_batch_id,
          CAST (
             MULTISET (
                SELECT DISTINCT xwaps1.publish_system publish_system
                  FROM xx_wsh_asn_publish_stg xwaps1
                 WHERE     xwaps1.publish_system IS NOT NULL
                       AND xwaps1.publish_batch_id = xwaps.publish_batch_id) AS xx_wsh_asn_publish_sys_tabtyp)
             target_system,
          CAST (
             MULTISET (
                SELECT xwds.*,
                       CAST (
                          MULTISET (
                             SELECT xwos.*,
                                    CAST (
                                       MULTISET (
                                            SELECT xwis.*
                                              FROM xx_wsh_items_stg xwis
                                             WHERE     xwis.delivery_id =
                                                          xwos.delivery_id
                                                   AND xwis.publish_batch_id =
                                                          xwos.publish_batch_id
                                                   AND xwis.order_header_id =
                                                          xwos.order_header_id
                                          ORDER BY TO_NUMBER (
                                                      xwis.order_line_number)) AS xx_wsh_items_ws_tabtyp)
                                       order_items
                               FROM xx_wsh_orders_stg xwos
                              WHERE     xwos.delivery_id = xwds.delivery_id
                                    AND xwos.publish_batch_id =
                                           xwds.publish_batch_id) AS xx_wsh_orders_ws_tabtyp)
                          delivery_orders
                  FROM xx_wsh_deliveries_stg xwds
                 WHERE     xwds.delivery_id = xwaps.delivery_id
                       AND xwds.publish_batch_id = xwaps.publish_batch_id) AS xx_wsh_deliveries_ws_tabtyp)
             deliveries
     FROM xx_wsh_asn_publish_stg xwaps
    WHERE     xwaps.publish_batch_id = xwaps.publish_batch_id
          AND xwaps.ROWID =
                 (SELECT MAX (ROWID)
                    FROM xx_wsh_asn_publish_stg
                   WHERE publish_batch_id = xwaps.publish_batch_id);
