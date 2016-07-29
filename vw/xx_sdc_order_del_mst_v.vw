DROP VIEW APPS.XX_SDC_ORDER_DEL_MST_V;

/* Formatted on 6/6/2016 4:58:08 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_ORDER_DEL_MST_V
(
   PUBLISH_BATCH_ID,
   PUBLISH_SYSTEMS,
   OE_ORDER_HEADERS
)
AS
   SELECT xoops.publish_batch_id publish_batch_id,
          CAST (
             MULTISET (
                SELECT DISTINCT
                       xps.publish_system publish_system,
                       xps.target_system target_system
                  FROM xx_om_sfdc_del_control_tbl xps
                 WHERE xps.publish_batch_id = xoops.publish_batch_id) AS xx_sfdc_order_sys_tabtyp)
             publish_systems,
          CAST (
             MULTISET (
                SELECT xoohs.*
                  FROM xx_sdc_order_delivery_stg xoohs
                 WHERE xoohs.publish_batch_id = xoops.publish_batch_id) AS xx_sfdc_order_del_tabtyp)
             oe_order_headers
     FROM (SELECT DISTINCT publish_batch_id
             FROM xx_om_sfdc_del_control_tbl
            WHERE status_flag = 'NEW') xoops;
