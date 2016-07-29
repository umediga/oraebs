DROP VIEW APPS.XX_SDC_ORDER_LINE_V;

/* Formatted on 6/6/2016 4:58:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_ORDER_LINE_V
(
   HEADER_ID,
   LINE_ID,
   ORDERED_ITEM,
   QTY,
   UOM,
   UNIT_SELLING_PRICE,
   REQUEST_DATE,
   SCHEDULE_SHIP_DATE,
   STATUS,
   ITEM_DESCRIPTION,
   ON_HOLD,
   SHIPPING_METHOD,
   FREIGHT_TERMS,
   PAYMENT_TERM,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   RECORD_TYPE,
   WAREHOUSE_NAME,
   TAX_AMOUNT,
   RETURN_REASON,
   RETURN_REFERENCE
)
AS
   SELECT ool.header_id,
          ool.line_id,
          msb.segment1 ordered_item,
          DECODE (ool.line_category_code,
                  'RETURN', (ool.ordered_quantity * -1),
                  ool.ordered_quantity)
             qty,
          ool.order_quantity_uom uom,
          ool.unit_selling_price,
          ool.request_date,
          ool.schedule_ship_date                --,ool.flow_status_code status
                                ,
          SUBSTR (
             xx_sdc_order_view_pkg.line_status (ool.header_id,
                                                ool.line_id,
                                                ool.flow_status_code),
             1,
             80)
             status,
          msb.description item_description,
          SUBSTR (
             xx_sdc_order_view_pkg.is_onhold (ool.header_id, ool.line_id),
             1,
             1)
             on_hold,
          car.ship_method_meaning shipping_method  --,ool.shipping_method_code
                                                     --,ool.freight_terms_code
          ,
          (SELECT meaning
             FROM fnd_lookup_values_vl
            WHERE     lookup_type = 'FREIGHT_TERMS'
                  AND lookup_code = ool.freight_terms_code
                  AND NVL (enabled_flag, 'X') = 'Y'
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE))
             freight_terms,
          rat.name payment_term,
          ool.creation_date,
          ool.last_update_date,
          DECODE (ool.line_category_code,
                  'ORDER', 'SALE',
                  'RETURN', 'RETURN',
                  'SALE')
             record_type,
          mtp.organization_name warehouse_name     --,ool.tax_value tax_amount
                                              ,
          DECODE (ool.line_category_code,
                  'RETURN', (ool.tax_value * -1),
                  ool.tax_value)
             tax_amount /*,(SELECT  wnd.waybill
                            FROM  wsh_new_deliveries wnd
                                 ,wsh_delivery_assignments wds
                                 ,wsh_delivery_details wdd
                           WHERE  wnd.delivery_id        = wds.delivery_id
                             AND  wds.delivery_detail_id = wdd.delivery_detail_id
                             AND  wdd.source_header_id = ool.header_id
                             AND  wdd.source_line_id = ool.line_id
                             AND  rownum = 1) waybill
                        ,(SELECT  car.freight_code
                                 FROM  wsh_new_deliveries wnd
                                      ,wsh_delivery_assignments wds
                                      ,wsh_delivery_details wdd
                                      ,wsh_carriers car
                                WHERE  wnd.delivery_id        = wds.delivery_id
                                  AND  wds.delivery_detail_id = wdd.delivery_detail_id
                                  AND  wdd.source_header_id = ool.header_id
                                  AND  wdd.source_line_id = ool.line_id
                                  AND  wnd.carrier_id = car.carrier_id
                             AND  rownum = 1) carrier */
                       ,
          (SELECT meaning
             FROM fnd_lookup_values_vl
            WHERE     lookup_type = 'CREDIT_MEMO_REASON'
                  AND lookup_code = ool.return_reason_code
                  AND NVL (enabled_flag, 'X') = 'Y'
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE))
             return_reason --,ool.return_context ||'-'||ool.return_attribute1 ||'-'||ool.return_attribute2 return_reference
                          ,
          SUBSTR (
             DECODE (
                xx_sdc_order_view_pkg.return_context (ool.header_id,
                                                      ool.line_id),
                'X', NULL,
                xx_sdc_order_view_pkg.return_context (ool.header_id,
                                                      ool.line_id)),
             1,
             50)
             return_reference
     FROM oe_order_lines_all ool,
          wsh_carrier_services_v car,
          ra_terms rat,
          org_organization_definitions mtp,
          mtl_system_items_b msb
    WHERE     ool.shipping_method_code = car.ship_method_code(+)
          AND ool.payment_term_id = rat.term_id(+)
          AND NVL (ool.ship_from_org_id, 83) = mtp.organization_id(+)
          AND ool.inventory_item_id = msb.inventory_item_id
          AND NVL (ool.ship_from_org_id, 83) = msb.organization_id
          AND EXISTS (SELECT header_id FROM xx_sdc_order_header_v);
