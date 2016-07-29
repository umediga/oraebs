DROP VIEW APPS.XX_BI_INV_VALUE_V;

/* Formatted on 6/6/2016 4:59:33 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_INV_VALUE_V
(
   ORGANIZATION_CODE,
   SUBINVENTORY_NAME,
   SUBINVENTORY_DESCRIPTION,
   SUBINVENTORY_TYPE_DESCRIPTION,
   LOCATOR,
   TERRITORY,
   DIVISION,
   ITEM_NUMBER,
   DESCRIPTION,
   UOM,
   SUBINVENTORY_TYPE,
   ONHAND_QUANTITY,
   VALUE,
   SET_NUMBER,
   SET_NAME,
   BUYER_ID,
   ITEM_TYPE,
   OPERATING_UNIT,
   ORGANIZATION_NAME,
   MATERIAL_ACCOUNT,
   EXPENSE_ACCOUNT,
   LOT_SIZE,
   MATERIAL_COST,
   COST_GROUP_ID,
   PLANNING_TP_TYPE
)
AS
   SELECT OOD.ORGANIZATION_CODE,
          MOQD.SUBINVENTORY_CODE SUBINV_CODE,
          MSU.DESCRIPTION SUBINVENTORY_DESCRIPTION,
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  fnd_flex_values_tl c
            WHERE     a.flex_value_set_name = 'XX_INTG_PARTY_TYPE'
                  AND c.language = USERENV ('LANG')
                  AND b.flex_value = msu.attribute1
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             SUBINVENTORY_TYPE_DESCRIPTION,
          MIL.SEGMENT1 || '.' || MIL.SEGMENT2 || '.' || MIL.SEGMENT3
             "Locator",
          (SELECT a.DESCRIPTION
             FROM fnd_territories_tl a,
                  HR_LOCATIONS_ALL b,
                  HR_ALL_ORGANIZATION_UNITS c
            WHERE     a.language = USERENV ('LANG')
                  AND a.TERRITORY_CODE = b.COUNTRY
                  AND b.location_id = c.location_id
                  AND c.ORGANIZATION_ID = OOD.organization_id
                  AND c.BUSINESS_GROUP_ID = ood.BUSINESS_GROUP_ID)
             Territory,
          (SELECT mcb.segment4
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.language = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id)
             DIVISION,
          MSIB.SEGMENT1 ITEM_NUMBER,
          MSIB.DESCRIPTION ITEM_DESCRIPTION,
          MSIB.PRIMARY_UOM_CODE ITEM_UOM,
          MSU.ATTRIBUTE1 SUBINVENTORY_TYPE,
          moqd.TRANSACTION_QUANTITY,
          (NVL ( (moqd.TRANSACTION_QUANTITY * CIS.ITEM_COST), 0)) VALUE,
          WLPN.LPN_ID SET_NUMBER,
          WLPN.LICENSE_PLATE_NUMBER SET_NAME,
          MSIB.BUYER_ID,
          MSIB.ITEM_TYPE,
          OOD.OPERATING_UNIT,
          OOD.ORGANIZATION_NAME,
          MSU.MATERIAL_ACCOUNT,
          MSU.EXPENSE_ACCOUNT,
          CIS.LOT_SIZE,
          CIS.MATERIAL_COST,
          MOQD.COST_GROUP_ID,
          MOQD.PLANNING_TP_TYPE
     FROM MTL_ONHAND_QUANTITIES_DETAIL MOQD,
          MTL_SYSTEM_ITEMS_B MSIB,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          APPS.CST_ITEM_COSTS CIS,
          MTL_SECONDARY_INVENTORIES MSU,
          APPS.MTL_ITEM_LOCATIONS MIL,
          APPS.WMS_LICENSE_PLATE_NUMBERS WLPN
    WHERE     CIS.COST_TYPE_ID = 1
          AND MOQD.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND MOQD.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
          AND MOQD.ORGANIZATION_ID = ood.ORGANIZATION_ID
          AND MOQD.INVENTORY_ITEM_ID = CIS.INVENTORY_ITEM_ID(+)
          AND MOQD.ORGANIZATION_ID = CIS.ORGANIZATION_ID(+)
          AND MOQD.SUBINVENTORY_CODE = MSU.SECONDARY_INVENTORY_NAME
          AND MOQD.ORGANIZATION_ID = MSU.ORGANIZATION_ID
          AND moqd.inventory_item_id = mil.inventory_item_id(+)
          AND MOQD.ORGANIZATION_ID = MIL.ORGANIZATION_ID(+)
          AND MOQD.LOCATOR_ID = MIL.INVENTORY_LOCATION_ID(+)
          AND MOQD.LOCATOR_ID = WLPN.LOCATOR_ID(+)
          AND MOQD.LPN_ID = WLPN.LPN_ID(+)
          AND MOQD.ORGANIZATION_ID = WLPN.ORGANIZATION_ID(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_INV_VALUE_V FOR APPS.XX_BI_INV_VALUE_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_INV_VALUE_V FOR APPS.XX_BI_INV_VALUE_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_INV_VALUE_V FOR APPS.XX_BI_INV_VALUE_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_INV_VALUE_V FOR APPS.XX_BI_INV_VALUE_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_INV_VALUE_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_INV_VALUE_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_INV_VALUE_V TO XXINTG;
