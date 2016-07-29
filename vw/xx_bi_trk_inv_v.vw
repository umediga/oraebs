DROP VIEW APPS.XX_BI_TRK_INV_V;

/* Formatted on 6/6/2016 4:58:52 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_TRK_INV_V
(
   ORGANIZATION_CODE,
   SUBINVENTORY_NAME,
   SUBINVENTORY_DESCRIPTION,
   SUBINVENTORY_TYPE_DESCRIPTION,
   SUBINVENTORY_TYPE,
   DIVISION,
   ITEM_NUMBER,
   ITEM_ID,
   ITEM_DESCRIPTION,
   ITEM_REV,
   ITEM_UOM,
   LOT_NUMBER,
   SET_NUMBER,
   SET_NAME,
   SERIAL_NUMBER,
   ON_HAND_QTY,
   LOCATOR,
   COST_GROUP_ID,
   PLANNING_TP_TYPE,
   TRANSACTION_UOM_CODE,
   OPERATING_UNIT,
   ORGANIZATION_NAME,
   MATERIAL_ACCOUNT,
   CONTROL_LEVEL_DISP,
   DIMENSION_UOM_CODE,
   ORGANIZATION_TYPE,
   INVENTORY_ITEM_ID,
   LOT_EXPIRE_DT
)
AS
   SELECT DISTINCT
          ood.organization_code "Org Code",
          moqd.subinventory_code "Subinventory Name",
          msu.description subinventory_description,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE                                --a.FLEX_VALUE_SET_ID=1017134
                 a    .flex_value_set_name = 'XX_INTG_PARTY_TYPE'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = msu.attribute1
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             subinventory_type_description,
          msu.attribute1 subinventory_type,
          (SELECT mcb.segment4
             FROM apps.mtl_item_categories mic,
                  apps.mtl_category_sets_tl mcst,
                  apps.mtl_category_sets_b mcsb,
                  apps.mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.LANGUAGE = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msi.inventory_item_id
                  AND mic.organization_id = msi.organization_id)
             division,
          msi.segment1 item_number,
          moqd.inventory_item_id item_id,
          msi.description item_description,
          moqd.revision item_rev,
          msi.primary_uom_code item_uom,
          moqd.lot_number lot_number,
          wlpn.lpn_id set_number,
          wlpn.license_plate_number set_name,
          msn.serial_number,
          DECODE (msn.serial_number,
                  NULL, moqd.transaction_quantity,
                  msn.serial_number, 1)
             "On Hand Qty",
          mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             "Locator",
          moqd.cost_group_id,
          moqd.planning_tp_type,
          moqd.transaction_uom_code,
          ood.operating_unit,
          ood.organization_name,
          msu.material_account,
          (SELECT ml.meaning
             FROM apps.mfg_lookups ml
            WHERE     ml.lookup_code = 1
                  AND ml.lookup_type = 'ITEM_CONTROL_LEVEL_GUI')
             control_level_disp,
          mil.dimension_uom_code,
          msn.organization_type,
          msi.inventory_item_id,
          mln.expiration_date lot_expire_date
     FROM apps.mtl_onhand_quantities_detail moqd,
          apps.mtl_system_items_b msi,
          apps.org_organization_definitions ood,
          apps.mtl_secondary_inventories msu,
          apps.mtl_item_locations mil,
          apps.mtl_serial_numbers msn,
          apps.wms_license_plate_numbers wlpn,
          apps.mtl_lot_numbers mln
    WHERE     msi.organization_id = moqd.organization_id
          AND msi.inventory_item_id = moqd.inventory_item_id
          AND msi.organization_id = ood.organization_id
          AND moqd.organization_id = mil.organization_id(+)
          AND moqd.locator_id = mil.inventory_location_id(+)
          AND moqd.lpn_id = wlpn.lpn_id(+)
          AND moqd.inventory_item_id = mln.inventory_item_id(+)
          AND moqd.lot_number = mln.lot_number(+)
          AND moqd.organization_id = mln.organization_id(+)
          AND moqd.inventory_item_id = msn.inventory_item_id
          AND moqd.organization_id = msn.current_organization_id
          AND NVL (moqd.lot_number, 'ABC') = NVL (msn.lot_number(+), 'ABC')
          AND moqd.subinventory_code = msn.current_subinventory_code(+)
          AND moqd.locator_id = msn.current_locator_id
          -- AND msi.organization_id = 2103
          AND moqd.locator_id = msn.current_locator_id
          AND msn.current_status(+) = 3
          AND moqd.organization_id = ood.organization_id
          AND moqd.organization_id = msu.organization_id
          AND moqd.subinventory_code = msu.secondary_inventory_name
          AND moqd.organization_id = msu.organization_id
          AND moqd.subinventory_code = mil.subinventory_code(+)
          AND moqd.inventory_item_id = msn.inventory_item_id(+)
          AND moqd.organization_id = msn.current_organization_id(+)
          AND moqd.subinventory_code = msn.current_subinventory_code(+)
          AND NVL (msn.lpn_id, 1) = NVL (moqd.lpn_id, 1)
   --AND MSI.segment1  in ('1523072M3P')
   -- AND moqd.SUBINVENTORY_CODE='FG'
   UNION ALL
   SELECT ood.organization_code "Org Code",
          moqd.subinventory_code "Subinventory Name",
          msu.description subinventory_description,
          (SELECT c.description
             FROM apps.fnd_flex_value_sets a,
                  apps.fnd_flex_values b,
                  apps.fnd_flex_values_tl c
            WHERE                                --a.FLEX_VALUE_SET_ID=1017134
                 a    .flex_value_set_name = 'XX_INTG_PARTY_TYPE'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = msu.attribute1
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             subinventory_type_description,
          msu.attribute1 subinventory_type,
          (SELECT mcb.segment4
             FROM apps.mtl_item_categories mic,
                  apps.mtl_category_sets_tl mcst,
                  apps.mtl_category_sets_b mcsb,
                  apps.mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.LANGUAGE = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msi.inventory_item_id
                  AND mic.organization_id = msi.organization_id)
             division,
          msi.segment1 item_number,
          moqd.inventory_item_id item_id,
          msi.description item_description,
          moqd.revision item_rev,
          msi.primary_uom_code item_uom,
          moqd.lot_number lot_number,
          wlpn.lpn_id set_number,
          wlpn.license_plate_number set_name,
          NULL,
          moqd.transaction_quantity,
          mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             "Locator",
          moqd.cost_group_id,
          moqd.planning_tp_type,
          moqd.transaction_uom_code,
          ood.operating_unit,
          ood.organization_name,
          msu.material_account,
          (SELECT ml.meaning
             FROM apps.mfg_lookups ml
            WHERE     ml.lookup_code = 1
                  AND ml.lookup_type = 'ITEM_CONTROL_LEVEL_GUI')
             control_level_disp,
          mil.dimension_uom_code,
          NULL,
          msi.inventory_item_id,
          mln.expiration_date lot_expire_date
     FROM apps.mtl_onhand_quantities_detail moqd,
          apps.mtl_system_items_b msi,
          apps.org_organization_definitions ood,
          apps.mtl_item_locations mil,
          apps.wms_license_plate_numbers wlpn,
          apps.mtl_lot_numbers mln,
          apps.mtl_secondary_inventories msu
    WHERE     msi.organization_id = moqd.organization_id
          AND msi.inventory_item_id = moqd.inventory_item_id
          AND msi.organization_id = ood.organization_id
          AND moqd.organization_id = mil.organization_id(+)
          AND moqd.locator_id = mil.inventory_location_id(+)
          AND moqd.lpn_id = wlpn.lpn_id(+)
          AND moqd.inventory_item_id = mln.inventory_item_id(+)
          AND moqd.lot_number = mln.lot_number(+)
          AND moqd.organization_id = mln.organization_id(+)
          -- AND msi.organization_id = 2103
          AND moqd.organization_id = ood.organization_id
          AND moqd.organization_id = msu.organization_id
          AND moqd.subinventory_code = msu.secondary_inventory_name
          AND moqd.organization_id = msu.organization_id
          AND moqd.subinventory_code = mil.subinventory_code(+)
          --               --and moqd.SUBINVENTORY_CODE='FG'
          AND NOT EXISTS
                 (SELECT 1
                    FROM apps.mtl_serial_numbers msn
                   WHERE     msn.inventory_item_id = msi.inventory_item_id
                         AND msn.current_organization_id =
                                msi.organization_id
                         AND msn.current_status(+) = 3
                         AND msn.current_subinventory_code =
                                moqd.subinventory_code
                         AND moqd.locator_id = msn.current_locator_id);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_TRK_INV_V FOR APPS.XX_BI_TRK_INV_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_TRK_INV_V FOR APPS.XX_BI_TRK_INV_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_TRK_INV_V FOR APPS.XX_BI_TRK_INV_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_TRK_INV_V FOR APPS.XX_BI_TRK_INV_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TRK_INV_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TRK_INV_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_TRK_INV_V TO XXINTG;
