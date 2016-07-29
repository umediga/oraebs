DROP VIEW APPS.XX_WSH_ITEMS_WS_V;

/* Formatted on 6/6/2016 4:57:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_WSH_ITEMS_WS_V
(
   PUBLISH_BATCH_ID,
   SOURCE_CODE,
   DELIVERY_ID,
   CONTAINER_INSTANCE_ID,
   ITEM_ID,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   ORDER_HEADER_ID,
   ORDER_LINE_ID,
   DELIVERY_DETAIL_ID,
   CUSTOMER_ITEM_ID,
   ATO_LINE_ID,
   CUSTOMER_PART_NUMBER,
   SUPPLIER_PART_NUMBER,
   REQUESTED_DATE,
   SHIPPED_QUANTITY,
   ITEM_UOM_CODE_INT,
   COMMODITY_CODE_INT,
   CONTAINER_ITEM_FLAG,
   CONTAINER_TYPE_CODE_INT,
   CUSTOMER_ORDER_FLAG,
   ORDERED_QUANTITY,
   CANCELLED_QUANTITY,
   PACKED_QUANTITY,
   UNIT_LIST_PRICE,
   GROSS_WEIGHT,
   SHIP_MODEL_COMPLETE_FLAG,
   CUSTOMER_DOCK_CODE,
   SHIPMENT_PRIORITY_CODE_INT,
   SHIPMENT_CONFIRMED_DATE,
   CUSTOMER_ITEM_DESCRIPTION,
   HAZARDOUS_MATERIAL_CODE_INT,
   HAZARD_CLASS_INT,
   HAZARD_CLASS_DESCRIPTION,
   ORDER_QUANTITY_UOM_INT,
   CUST_PRODUCTION_SEQ_NUM,
   CUST_PO_NUMBER,
   FREIGHT_TERMS_CODE_INT,
   FOB_POINT_CODE_INT,
   ORGANIZATION_ID,
   CUSTOMER_JOB,
   CUSTOMER_PRODUCTION_LINE,
   CUSTOMER_MODEL_SERIAL_NUMBER,
   REFERENCE_LINE_NUMBER,
   ORIGINAL_SYSTEM_LINE_REFERENCE,
   ORDER_LINE_NUMBER,
   PROMISE_DATE,
   ITEM_TYPE_CODE_INT,
   UNIT_SELLING_PRICE,
   OPTION_FLAG,
   COMPONENT_CODE,
   LOT_NUMBER,
   LOT_EXPIRATION_DATE
)
AS
   SELECT NULL publish_batch_id,
          wdd.source_code source_code,
          wnd.delivery_id delivery_id,
          wda.parent_delivery_detail_id container_instance_id,
          wdd.inventory_item_id item_id,
          msi.segment1 item_number,
          msi.description item_description,
          wdd.source_header_id order_header_id,
          wdd.source_line_id order_line_id,
          wdd.delivery_detail_id delivery_detail_id,
          wdd.customer_item_id customer_item_id,
          wdd.ato_line_id ato_line_id --        , nvl(oel.tp_attribute2, mci.customer_item_number) customer_part_number -- Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
                                     ,
          oel.tp_attribute2 customer_part_number,
          DECODE (
             wdd.client_id,
             NULL, mif.item_number,
             wms_deploy.get_client_item (mif.organization_id,
                                         mif.inventory_item_id))
             supplier_part_number,
          wdd.date_requested requested_date,
          wdd.shipped_quantity shipped_quantity,
          wdd.requested_quantity_uom item_uom_code_int --        , mcc.commodity_code commodity_code_int
                                                      ,
          NULL commodity_code_int,
          msi.container_item_flag container_item_flag,
          msi.container_type_code container_type_code_int,
          msi.customer_order_enabled_flag customer_order_flag,
          DECODE (
             wdd.reference_line_quantity_uom,
             NULL, wdd.src_requested_quantity,
             wdd.src_requested_quantity_uom, wdd.reference_line_quantity,
             NULL)
             ordered_quantity,
          NVL (wdd.cancelled_quantity, 0) cancelled_quantity,
          DECODE (
             wda.parent_delivery_detail_id,
             NULL, 0,
             (SELECT edpq.packed_quantity
                FROM wsh_dsno_packed_quantity_v edpq
               WHERE     wda.delivery_id = edpq.delivery_id
                     AND NVL (wda.parent_delivery_detail_id, 0) =
                            NVL (edpq.container_id, 0)
                     AND wdd.inventory_item_id = edpq.inventory_item_id
                     AND wdd.source_line_id = edpq.source_line_id))
             packed_quantity,
          wdd.unit_price unit_list_price,
          wdd.gross_weight gross_weight,
          wdd.ship_model_complete_flag ship_model_complete_flag,
          wdd.customer_dock_code customer_dock_code,
          wdd.shipment_priority_code shipment_priority_code_int,
          wnd.confirm_date shipment_confirmed_date --        , mci.customer_item_desc customer_item_description -- Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
                                                  ,
          NULL customer_item_description,
          'UN' hazardous_material_code_int,
          phc.hazard_class hazard_class_int,
          phc.description hazard_class_description,
          DECODE (
             wdd.reference_line_quantity_uom,
             NULL, wdd.src_requested_quantity_uom,
             wdd.src_requested_quantity_uom, wdd.reference_line_quantity_uom,
             NULL)
             order_quantity_uom_int,
          wdd.customer_prod_seq cust_production_seq_num,
          wdd.cust_po_number cust_po_number,
          wdd.freight_terms_code freight_terms_code_int,
          wdd.fob_code fob_point_code_int,
          wdd.organization_id organization_id,
          wdd.customer_job customer_job --, wdd.customer_production_line customer_production_line
                                       ,
          oel.customer_line_number customer_production_line --, wdd.cust_model_serial_number customer_model_serial_number
                                                           ,
          (SELECT fm_serial_number
             FROM wsh_serial_numbers
            WHERE delivery_detail_id = wdd.delivery_detail_id AND ROWNUM = 1)
             customer_model_serial_number,
          wdd.reference_line_number reference_line_number,
          oel.orig_sys_line_ref original_system_line_reference,
          TO_CHAR (oel.line_number) order_line_number,
          oel.promise_date promise_date,
          oel.item_type_code item_type_code_int,
          oel.unit_selling_price unit_selling_price,
          oel.option_flag option_flag,
          oel.component_code component_code,
          wdd.lot_number lot_number,
          mln.expiration_date lot_expiration_date
     FROM po_hazard_classes phc,
          mtl_system_items msi --        , mtl_customer_items mci -- Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
 --        , mtl_commodity_codes mcc -- Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
          ,
          mtl_item_flexfields mif,
          wsh_new_deliveries wnd,
          wsh_delivery_assignments_v wda,
          wsh_delivery_details wdd,
          oe_order_headers_all oeh,
          oe_order_sources oos,
          oe_order_lines_all oel,
          mtl_lot_numbers mln
    --        , mtl_customer_item_xrefs_v mcix -- Added on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
    -- Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
    WHERE     NVL (wdd.container_flag, 'N') = 'N'
          AND wdd.source_code = 'OE'
          AND msi.hazard_class_id = phc.hazard_class_id(+)
          -- following lines Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
          --AND wdd.customer_item_id = mci.customer_item_id(+) -- Commented on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
          --      AND mci.commodity_code_id = mcc.commodity_code_id(+)
          AND wdd.organization_id = msi.organization_id
          AND wdd.inventory_item_id = msi.inventory_item_id
          AND wdd.organization_id = mif.organization_id
          AND wdd.inventory_item_id = mif.inventory_item_id
          AND wnd.delivery_id = wda.delivery_id
          AND NVL (wdd.shipped_quantity, 0) > 0
          AND wda.delivery_detail_id = wdd.delivery_detail_id
          AND wda.delivery_id IS NOT NULL
          AND wnd.delivery_type = 'STANDARD'
          AND oeh.header_id = oel.header_id
          AND oeh.order_source_id = oos.order_source_id
          AND oos.name = ANY ('EDIGHX', 'EDIGXS')
          AND wdd.source_header_id = oel.header_id
          AND wdd.source_line_id = oel.line_id
          -- following lines Commented for wave1 since 856 fails with items having multiple Cust Items for same customer
          --      AND oel.inventory_item_id = mcix.inventory_item_id(+) -- Added on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
          --      AND oel.sold_to_org_id = mcix.customer_id(+) -- Added on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
          --      AND mcix.inactive_flag(+) = 'N' -- Added on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
          --      AND mcix.customer_item_id = mci.customer_item_id(+)      -- Added on 20Feb2013 to pick Customer Item from Xref when not in TP_ATTRIBUTE2 Case#  002009
          AND wdd.lot_number = mln.lot_number(+)
          AND wdd.organization_id = mln.organization_id(+)
          AND wdd.inventory_item_id = mln.inventory_item_id(+);


GRANT SELECT ON APPS.XX_WSH_ITEMS_WS_V TO XXAPPSREAD;
