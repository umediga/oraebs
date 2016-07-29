DROP VIEW APPS.XX_OM_SHIP_MANIFEST_LINE_V;

/* Formatted on 6/6/2016 4:58:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_OM_SHIP_MANIFEST_LINE_V
(
   ORG_ID,
   HEADER_ID,
   LINE_ID,
   ORG_CODE,
   ORG_NAME,
   ORDER_NUMBER,
   DELIVERY_ID,
   DELIVERY_NUMBER,
   DELIVERY_DETAIL_ID,
   RELEASED_STATUS,
   ORDERED_DATE,
   REQUEST_DATE,
   SCHEDULE_SHIP_DATE,
   PROMISE_DATE,
   SHIP_TO_ORG_ID,
   DELIVER_TO_ORG_ID,
   INVOICE_TO_ORG_ID,
   CUST_PO_NUMBER,
   END_CUSTOMER_PO,
   SHIPMENT_PRIORITY,
   SHIPPING_INSTRUCTIONS,
   ORDER_LINE_TYPE,
   SHIP_ORG_ID,
   WAREHOUSE,
   LICENSE_PLATE_NUMBER,
   ORGANIZATION_ID,
   INVENTORY_ITEM_ID,
   SHIPPED_QUANTITY,
   UOM,
   SELLING_PRICE,
   CURRENCY_CODE,
   LOT_NUMBER,
   PLACE_OF_ORIGIN,
   SHIP_CREATED_BY,
   SHIP_CREATED_DATE,
   ITEM_NUMBER,
   ITEM_DESC,
   ITEM_INV_CATEGORY_SET,
   ITEM_HAZARD_CLASS,
   ITEM_UN_NUMBER,
   ITEM_ATTR_CONTEXT,
   ITEM_ATTRIBUTE1,
   ITEM_ATTRIBUTE2,
   ITEM_ATTRIBUTE3,
   ITEM_ATTRIBUTE4,
   ITEM_ATTRIBUTE5,
   ITEM_ATTRIBUTE6,
   ITEM_ATTRIBUTE7,
   ITEM_ATTRIBUTE8,
   ITEM_ATTRIBUTE9,
   ITEM_ATTRIBUTE10,
   ITEM_ATTRIBUTE11,
   ITEM_ATTRIBUTE12,
   ITEM_ATTRIBUTE13,
   ITEM_ATTRIBUTE14,
   ITEM_ATTRIBUTE15,
   ITEM_ATTRIBUTE16,
   ITEM_ATTRIBUTE17,
   ITEM_ATTRIBUTE18,
   ITEM_ATTRIBUTE19,
   ITEM_ATTRIBUTE20,
   ITEM_ATTRIBUTE21,
   ITEM_ATTRIBUTE22,
   ITEM_ATTRIBUTE23,
   ITEM_ATTRIBUTE24,
   ITEM_ATTRIBUTE25,
   ITEM_ATTRIBUTE26,
   ITEM_ATTRIBUTE27,
   ITEM_ATTRIBUTE28,
   ITEM_ATTRIBUTE29,
   ITEM_ATTRIBUTE30
)
AS
   SELECT ooh.org_id,
          ooh.header_id,
          ool.line_id,
          hro.short_code org_code,
          hro.name org_name,
          ooh.order_number,
          wnd.delivery_id,
          wnd.name delivery_number,
          wdd.delivery_detail_id,
          wdd.released_status                           --,oht.name order_type
                             ,
          ooh.ordered_date,
          NVL (ool.request_date, ooh.request_date) request_date,
          ool.schedule_ship_date,
          ool.promise_date,
          NVL (ool.ship_to_org_id, ooh.ship_to_org_id) ship_to_org_id,
          NVL (ool.deliver_to_org_id, ooh.deliver_to_org_id)
             deliver_to_org_id,
          NVL (ool.invoice_to_org_id, ooh.invoice_to_org_id)
             invoice_to_org_id,
          ooh.cust_po_number,
          ooh.attribute5 end_customer_po,
          (SELECT meaning
             FROM fnd_lookup_values_vl
            WHERE     lookup_type = 'SHIPMENT_PRIORITY'
                  AND lookup_code =
                         NVL (ool.shipment_priority_code,
                              ooh.shipment_priority_code)
                  AND NVL (enabled_flag, 'X') = 'Y'
                  AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                  AND NVL (end_date_active, SYSDATE))
             shipment_priority,
          DECODE (
             ool.shipping_instructions,
             NULL, ool.packing_instructions,
             ool.shipping_instructions || ',' || ool.packing_instructions)
             shipping_instructions,
          (SELECT name
             FROM oe_transaction_types_tl
            WHERE     TRANSACTION_TYPE_ID = ool.line_type_id
                  AND language = USERENV ('LANG'))
             order_line_type,
          ool.ship_from_org_id ship_org_id  --ooh.ship_from_org_id ship_org_id
                                          ,
          (SELECT organization_code
             FROM mtl_parameters
            WHERE organization_id =
                     NVL (ool.ship_from_org_id, ooh.ship_from_org_id))
             warehouse,
          lpn.license_plate_number,
          wdd.organization_id,
          wdd.inventory_item_id                            --,wdd.subinventory
                               ,
          wdd.shipped_quantity,
          wdd.requested_quantity_uom uom       --,wdd.unit_price selling_price
                                        ,
          ool.unit_selling_price selling_price,
          wdd.currency_code,
          wdd.lot_number,
          lot.place_of_origin,
          wdd.created_by ship_created_by,
          wnd.ultimate_dropoff_date ship_created_date                  -- Item
                                                     ,
          itm.segment1 item_number,
          itm.description item_desc,
          (SELECT category_concat_segs
             FROM mtl_item_categories_v
            WHERE     inventory_item_id = itm.inventory_item_id
                  AND organization_id = itm.organization_id
                  AND category_set_name = 'Inventory')
             item_inv_category_set,
          (SELECT description
             FROM po_hazard_classes_tl
            WHERE     hazard_class_id = itm.hazard_class_id
                  AND language = USERENV ('LANG'))
             item_hazard_class,
          (SELECT un_number
             FROM po_un_numbers_tl
            WHERE     un_number_id = itm.un_number_id
                  AND language = USERENV ('LANG'))
             item_un_number,
          NVL (itm.attribute_category, itm_mst.attribute_category)
             item_attr_context,
          NVL (itm.attribute1, itm_mst.attribute1) item_attribute1,
          NVL (itm.attribute2, itm_mst.attribute2) item_attribute2,
          NVL (itm.attribute3, itm_mst.attribute3) item_attribute3,
          NVL (itm.attribute4, itm_mst.attribute4) item_attribute4,
          NVL (itm.attribute5, itm_mst.attribute5) item_attribute5,
          NVL (itm.attribute6, itm_mst.attribute6) item_attribute6,
          NVL (itm.attribute7, itm_mst.attribute7) item_attribute7,
          NVL (itm.attribute8, itm_mst.attribute8) item_attribute8,
          NVL (itm.attribute9, itm_mst.attribute9) item_attribute9,
          NVL (itm.attribute10, itm_mst.attribute10) item_attribute10,
          NVL (itm.attribute11, itm_mst.attribute11) item_attribute11,
          NVL (itm.attribute12, itm_mst.attribute12) item_attribute12,
          NVL (itm.attribute13, itm_mst.attribute13) item_attribute13 --,NVL(itm.attribute17,itm_mst.attribute17) item_attribute13
                                                                     ,
          NVL (itm.attribute14, itm_mst.attribute14) item_attribute14,
          NVL (itm.attribute15, itm_mst.attribute15) item_attribute15,
          NVL (itm.attribute16, itm_mst.attribute16) item_attribute16,
          NVL (itm.attribute17, itm_mst.attribute17) item_attribute17,
          NVL (itm.attribute18, itm_mst.attribute18) item_attribute18,
          NVL (itm.attribute19, itm_mst.attribute19) item_attribute19,
          NVL (itm.attribute20, itm_mst.attribute20) item_attribute20,
          NVL (itm.attribute21, itm_mst.attribute21) item_attribute21,
          NVL (itm.attribute22, itm_mst.attribute22) item_attribute22,
          NVL (itm.attribute23, itm_mst.attribute23) item_attribute23,
          NVL (itm.attribute24, itm_mst.attribute24) item_attribute24,
          NVL (itm.attribute25, itm_mst.attribute25) item_attribute25,
          NVL (itm.attribute26, itm_mst.attribute26) item_attribute26,
          NVL (itm.attribute27, itm_mst.attribute27) item_attribute27,
          NVL (itm.attribute28, itm_mst.attribute28) item_attribute28,
          NVL (itm.attribute29, itm_mst.attribute29) item_attribute29,
          NVL (itm.attribute30, itm_mst.attribute30) item_attribute30
     FROM oe_order_headers_all ooh,
          oe_order_lines_all ool,
          mtl_system_items_b msi,
          wsh_delivery_details wdd,
          wsh_delivery_assignments wds,
          wsh_new_deliveries wnd                                       -- Item
                                ,
          mtl_system_items_b itm,
          mtl_system_items_b itm_mst,
          mtl_parameters pram_mast,
          mtl_lot_numbers lot                                               --
                             ,
          hr_operating_units hro,
          oe_transaction_types_tl oht,
          oe_order_sources ohs,
          wsh_carrier_services_v car,
          wms_license_plate_numbers lpn,
          mtl_parameters pram
    WHERE     ooh.header_id = ool.header_id
          AND msi.inventory_item_id = ool.inventory_item_id
          AND ool.ship_from_org_id = msi.organization_id
          AND itm_mst.organization_id = pram_mast.organization_id
          AND pram_mast.organization_code = 'MST'
          AND itm_mst.inventory_item_id = msi.inventory_item_id
          --
          AND hro.organization_id = ooh.org_id
          AND oht.transaction_type_id = ooh.order_type_id
          AND oht.language = USERENV ('LANG')
          AND ohs.order_source_id = ooh.order_source_id(+)
          AND car.ship_method_code =
                 NVL (ool.shipping_method_code, ooh.shipping_method_code)
          --
          AND wdd.source_line_id = ool.line_id
          AND wdd.source_header_id = ooh.header_id
          AND wds.delivery_detail_id = wdd.delivery_detail_id
          AND wds.delivery_id = wnd.delivery_id
          AND wdd.organization_id = itm.organization_id
          AND wdd.inventory_item_id = itm.inventory_item_id
          AND wdd.inventory_item_id = lot.inventory_item_id(+)
          AND wdd.organization_id = lot.organization_id(+)
          AND wdd.lot_number = lot.lot_number(+)
          AND wdd.lpn_id = lpn.lpn_id(+)
          AND wdd.organization_id = pram.organization_id;


CREATE OR REPLACE SYNONYM XX_SHPRO.XX_OM_SHIP_MANIFEST_LINE_V FOR APPS.XX_OM_SHIP_MANIFEST_LINE_V;


GRANT SELECT ON APPS.XX_OM_SHIP_MANIFEST_LINE_V TO XXAPPSREAD;

GRANT SELECT ON APPS.XX_OM_SHIP_MANIFEST_LINE_V TO XX_SHPRO;
