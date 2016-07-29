DROP VIEW APPS.XX_WMS_CAROUSEL_OTBND_V;

/* Formatted on 6/6/2016 4:57:59 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_WMS_CAROUSEL_OTBND_V
(
   ORDERNO,
   WORDERNO,
   CARTONID,
   PRODUCT,
   DESCRIPTION,
   UPC,
   ZONE,
   BIN,
   QTY,
   UOM,
   LOT,
   PICKID,
   INFO1,
   INFO2
)
AS
   SELECT ooha.order_number,
          NULL,
          license_plate_number,
          msi.segment1,
          msi.description,
          NULL,
          mmtt1.subinventory_code,
          mil.segment1 || mil.segment2 || mil.segment3,
          mmtt1.transaction_quantity,
          mmtt1.transaction_uom,
          mtlt.lot_number lot,
          mmtt1.transaction_temp_id,
          NULL,
          NULL
     FROM mtl_material_transactions_temp mmtt1,
          oe_order_headers_all ooha,
          oe_order_lines_all oola,
          mtl_item_locations mil,
          mtl_system_items_b msi,
          wms_license_plate_numbers wlpn,
          mtl_transaction_lots_temp mtlt,
          (SELECT DISTINCT
                  mmtt.cartonization_id,
                  mmtt.wms_task_type,
                  mmtt.wms_task_status
             FROM mtl_material_transactions_temp mmtt,
                  xx_emf_process_parameters xpp,
                  xx_emf_process_setup xps,
                  mfg_lookups ml1,
                  mfg_lookups ml2
            WHERE     mmtt.subinventory_code = xpp.parameter_value
                  AND NVL (xps.enabled_flag, 'Y') = 'Y'
                  AND NVL (xpp.enabled_flag, 'Y') = 'Y'
                  AND xpp.parameter_name = 'ZONE'
                  AND xps.process_id = xpp.process_id
                  AND xps.process_name = 'XXWMSCAROTBNDV'
                  AND mmtt.wms_task_status = ml2.lookup_code
                  AND mmtt.wms_task_type = ml1.lookup_code
                  AND ml1.lookup_type = 'WMS_TASK_TYPES'
                  AND ml1.meaning = 'Pick'
                  AND ml2.meaning = 'Pending'
                  AND ml2.lookup_type = 'WMS_TASK_STATUS') crsl_cartoon
    WHERE     mmtt1.cartonization_id = crsl_cartoon.cartonization_id
          AND oola.line_id = mmtt1.trx_source_line_id
          AND ooha.header_id = oola.header_id
          AND mil.inventory_location_id = mmtt1.locator_id
          AND msi.inventory_item_id = mmtt1.inventory_item_id
          AND msi.organization_id = mmtt1.organization_id
          AND wlpn.lpn_id = mmtt1.cartonization_id
          AND mtlt.transaction_temp_id(+) = mmtt1.transaction_temp_id
          AND mmtt1.wms_task_status = crsl_cartoon.wms_task_status
          AND mmtt1.wms_task_type = crsl_cartoon.wms_task_type
   UNION
   SELECT NULL,
          we.wip_entity_name,
          license_plate_number,
          msi.segment1,
          msi.description,
          NULL,
          mmtt1.subinventory_code,
          mil.segment1 || mil.segment2 || mil.segment3,
          mmtt1.transaction_quantity,
          mmtt1.transaction_uom,
          mtlt.lot_number lot,
          mmtt1.transaction_temp_id,
          NULL,
          NULL
     FROM mtl_material_transactions_temp mmtt1,
          wip_entities we,
          mtl_item_locations mil,
          mtl_system_items_b msi,
          wms_license_plate_numbers wlpn,
          mtl_transaction_lots_temp mtlt,
          (SELECT DISTINCT
                  mmtt.cartonization_id,
                  mmtt.wms_task_type,
                  mmtt.wms_task_status
             FROM mtl_material_transactions_temp mmtt,
                  xx_emf_process_parameters xpp,
                  xx_emf_process_setup xps,
                  mfg_lookups ml1,
                  mfg_lookups ml2
            WHERE     mmtt.subinventory_code = xpp.parameter_value
                  AND NVL (xps.enabled_flag, 'Y') = 'Y'
                  AND NVL (xpp.enabled_flag, 'Y') = 'Y'
                  AND xpp.parameter_name = 'ZONE'
                  AND xps.process_id = xpp.process_id
                  AND xps.process_name = 'XXWMSCAROTBNDV'
                  AND mmtt.wms_task_status = ml2.lookup_code
                  AND mmtt.wms_task_type = ml1.lookup_code
                  AND ml1.lookup_type = 'WMS_TASK_TYPES'
                  AND ml1.meaning = 'Pick'
                  AND ml2.meaning = 'Pending'
                  AND ml2.lookup_type = 'WMS_TASK_STATUS') crsl_cartoon
    WHERE     mmtt1.cartonization_id = crsl_cartoon.cartonization_id
          AND we.wip_entity_id = mmtt1.transaction_source_id
          -- added By Renjith As per ticket#001977
          -- [
          AND mmtt1.transaction_source_type_id = 5
          AND mmtt1.transaction_action_id = 1
          -- ]
          AND we.organization_id = mmtt1.organization_id
          AND mil.inventory_location_id = mmtt1.locator_id
          AND msi.inventory_item_id = mmtt1.inventory_item_id
          AND msi.organization_id = mmtt1.organization_id
          AND wlpn.lpn_id = mmtt1.cartonization_id
          AND mtlt.transaction_temp_id(+) = mmtt1.transaction_temp_id
          AND mmtt1.wms_task_status = crsl_cartoon.wms_task_status
          AND mmtt1.wms_task_type = crsl_cartoon.wms_task_type;


GRANT SELECT ON APPS.XX_WMS_CAROUSEL_OTBND_V TO XXAPPSREAD;
