DROP VIEW APPS.XX_SDC_ORDER_DEL_V;

/* Formatted on 6/6/2016 4:58:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_ORDER_DEL_V
(
   HEADER_ID,
   LINE_ID,
   DELIVERY_DETAIL_ID,
   WAYBILL,
   CARRIER,
   SHIPPED_QUANTITY,
   CONFIRM_DATE,
   CREATION_DATE,
   LAST_UPDATE_DATE
)
AS
   SELECT ool.header_id,
          ool.line_id,
          wdd.delivery_detail_id,
          wnd.waybill,
          car.freight_code carrier,
          wdd.shipped_quantity      --,wdd.delivered_quantity shipped_quantity
                              ,
          wnd.confirm_date,
          wdd.creation_date,
          wdd.last_update_date
     FROM oe_order_lines_all ool,
          wsh_new_deliveries wnd,
          wsh_delivery_assignments wds,
          wsh_delivery_details wdd,
          wsh_carriers car
    WHERE     wnd.delivery_id = wds.delivery_id
          AND wds.delivery_detail_id = wdd.delivery_detail_id
          AND wdd.source_header_id = ool.header_id
          AND wdd.source_line_id = ool.line_id
          AND wnd.carrier_id = car.carrier_id
          AND EXISTS (SELECT header_id FROM xx_sdc_order_header_v);
