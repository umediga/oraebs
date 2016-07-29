DROP VIEW APPS.XX_BI_HSP_CONSGN_V;

/* Formatted on 6/6/2016 4:59:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_HSP_CONSGN_V
(
   ORGANIZATION_CODE,
   SUBINVENTORY_NAME,
   SUBINVENTORY_DESCRIPTION,
   SUBINVENTORY_TYPE_DESCRIPTION,
   SUBINVENTORY_TYPE,
   DIVISION,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   ITEM_UOM,
   ITEM_ID,
   ORGANIZATION_ID,
   ITEM_REV,
   LOT_NUMBER,
   SET_NUMBER,
   SET_NAME,
   TRAN_QTY,
   LOT_EXPIRE_DT,
   LOCATOR_ID,
   COST_GROUP_ID,
   PLANNING_TP_TYPE,
   TRANSACTION_UOM_CODE,
   PRIMARY_UOM_CODE,
   SALES_ACCOUNT,
   OPERATING_UNIT,
   ORGANIZATION_NAME,
   CONTROL_LEVEL_DISP,
   DIMENSION_UOM_CODE,
   MATERIAL_ACCOUNT
)
AS
   SELECT ood.organization_code,
          msu.secondary_inventory_name,
          msu.description subinventory_description,
          --  FFVV.DESCRIPTION SUBINVENTORY_TYPE_DESCRIPTION,
          (SELECT FFVV.DESCRIPTION
             FROM APPS.FND_FLEX_VALUE_SETS FFVS,
                  APPS.FND_FLEX_VALUES_VL FFVV,
                  apps.mtl_secondary_inventories msu1
            WHERE     MSU.ATTRIBUTE1 = FFVV.FLEX_VALUE(+)
                  AND FFVS.FLEX_VALUE_SET_NAME = 'XX_INTG_PARTY_TYPE'
                  AND FFVS.FLEX_VALUE_SET_ID(+) = FFVV.FLEX_VALUE_SET_ID
                  AND msu1.organization_id = msu.organization_id
                  AND MSU1.ATTRIBUTE1 = MSU.ATTRIBUTE1
                  AND msu1.secondary_inventory_name =
                         msu.secondary_inventory_name)
             SUBINVENTORY_TYPE_DESCRIPTION,
          msu.Attribute1 subinventory_type,
          micv.segment4 division,
          msi.segment1 item_number,
          msi.description item_description,
          msi.primary_uom_code item_uom,
          msi.inventory_item_id item_id,
          moqd.organization_id,
          moqd.revision item_rev,
          mln.lot_number lot_number,
          wlpn.lpn_id set_number,
          wlpn.license_plate_number set_name,
          ROUND (moqd.primary_transaction_quantity,
                 fnd_profile.VALUE ('REPORT_QUANTITY_PRECISION'))
             tran_qty,
          mln.expiration_date lot_expire_dt,
          NVL (moqd.locator_id, -9999) locator_id,
          moqd.COST_GROUP_ID,
          moqd.PLANNING_TP_TYPE,
          moqd.TRANSACTION_UOM_CODE,
          msi.PRIMARY_UOM_CODE,
          msi.SALES_ACCOUNT,
          ood.OPERATING_UNIT,
          ood.ORGANIZATION_NAME,
          micv.CONTROL_LEVEL_DISP,
          mil.DIMENSION_UOM_CODE,
          msu.MATERIAL_ACCOUNT
     FROM mtl_system_items msi,
          mtl_onhand_quantities_detail moqd,
          mtl_lot_numbers mln,
          mtl_item_locations mil,
          org_organization_definitions ood,
          mtl_secondary_inventories msu,
          apps.mtl_item_Categories_v micv,
          apps.wms_license_plate_numbers wlpn
    --    APPS.fnd_flex_value_sets ffvs,
    --   APPS.FND_FLEX_VALUES_VL FFVV
    WHERE     msi.organization_id = mln.organization_id
          AND msi.inventory_item_id = moqd.inventory_item_id
          AND moqd.inventory_item_id = mln.inventory_item_id
          AND moqd.organization_id = mln.organization_id
          AND moqd.lot_number = mln.lot_number
          AND moqd.organization_id = mil.organization_id
          AND moqd.locator_id = mil.inventory_location_id
          AND msi.organization_id = ood.organization_id
          AND moqd.subinventory_code = msu.secondary_inventory_name
          AND mln.organization_id = msu.organization_id
          AND micv.inventory_item_id = msi.inventory_item_id
          AND micv.organization_id = msi.organization_id
          --          AND MSU.ATTRIBUTE1 = FFVV.FLEX_VALUE(+)
          --          AND FFVS.FLEX_VALUE_SET_NAME(+) = 'XX_INTG_PARTY_TYPE'
          --          AND FFVS.FLEX_VALUE_SET_ID(+) = FFVV.FLEX_VALUE_SET_ID
          AND moqd.locator_id = wlpn.locator_id(+)
          AND moqd.lpn_id = wlpn.lpn_id(+)
          AND moqd.organization_id = wlpn.organization_id(+)
          AND micv.category_set_id = 5;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_HSP_CONSGN_V FOR APPS.XX_BI_HSP_CONSGN_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_HSP_CONSGN_V FOR APPS.XX_BI_HSP_CONSGN_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_HSP_CONSGN_V FOR APPS.XX_BI_HSP_CONSGN_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_HSP_CONSGN_V FOR APPS.XX_BI_HSP_CONSGN_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_HSP_CONSGN_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_HSP_CONSGN_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_HSP_CONSGN_V TO XXINTG;
