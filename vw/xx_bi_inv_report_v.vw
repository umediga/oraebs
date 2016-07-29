DROP VIEW APPS.XX_BI_INV_REPORT_V;

/* Formatted on 6/6/2016 4:59:33 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_INV_REPORT_V
(
   ORGANIZATION_ID,
   INVENTORY_ITEM_ID,
   INVENTORY_ITEM_STATUS_CODE,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   UOM,
   UNIT_VOLUME,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   SERIAL_NUMBER,
   LOCATOR_ID,
   SUBINVENTORY_CODE,
   LOCATOR,
   LOT_NUMBER,
   LOT_EXPIRATION_DATE,
   VALUE,
   ONHAND_QUANTITY,
   CURRENCY_CODE,
   CREATION_DATE,
   ORIGINATION_DATE,
   OPERATING_UNIT
)
AS
   SELECT msi.organization_id,
          msi.inventory_item_id,
          msi.INVENTORY_ITEM_STATUS_CODE,
          msi.segment1 "ITEM_NUMBER",
          msi.description "ITEM_DESCRIPTION",
          MSI.PRIMARY_UOM_CODE,
          MSI.UNIT_VOLUME,
          ood.organization_code,
          ood.organization_name,
          msn.serial_number,
          moq.locator_id,
          --MSN.CURRENT_LOCATOR_ID,
          moq.subinventory_code,              --MSN.CURRENT_SUBINVENTORY_CODE,
          (SELECT mil.segment1 || '.' || mil.segment2 || '.' || MIL.SEGMENT3
             FROM apps.mtl_item_locations mil
            WHERE     mil.inventory_location_id = moq.locator_id
                  AND mil.organization_id = moq.organization_id
                  AND moq.subinventory_code = mil.subinventory_code)
             "LOCATOR",
          moq.lot_number,
          mln.expiration_date "LOT_EXPIRATION_DATE",
          (  cic.item_cost
           * (DECODE (msn.serial_number,
                      NULL, moq.transaction_quantity,
                      msn.serial_number, 1)))
             "VALUE",
          DECODE (msn.serial_number,
                  NULL, moq.transaction_quantity,
                  msn.serial_number, 1)
             "ONHAND_QUANTITY",
          gsob.currency_code,
          moq.creation_date,
          MLN.ORIGINATION_DATE,
          hou.NAME "OPERATING_UNIT"
     --            msn.last_transaction_id
     FROM APPS.MTL_SYSTEM_ITEMS_B MSI,
          APPS.MTL_ONHAND_QUANTITIES MOQ,
          APPS.MTL_SERIAL_NUMBERS MSN,
          APPS.MTL_LOT_NUMBERS MLN,
          APPS.CST_ITEM_COSTS CIC,
          APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
          APPS.GL_SETS_OF_BOOKS GSOB,
          APPS.HR_OPERATING_UNITS HOU
    WHERE     1 = 1
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND moq.organization_id = msn.current_organization_id(+)
          AND moq.inventory_item_id = msn.inventory_item_id(+)
          --        AND moq.lot_number = msn.lot_number(+)
          AND moq.locator_id = msn.current_locator_id(+)
          AND MOQ.SUBINVENTORY_CODE = MSN.CURRENT_SUBINVENTORY_CODE(+)
          AND moq.update_transaction_id = msn.last_transaction_id(+)
          --        AND NVL (moq.lot_number, 'ABC') = NVL (msn.lot_number(+),'ABC')
          AND MOQ.INVENTORY_ITEM_ID = MLN.INVENTORY_ITEM_ID
          AND moq.ORGANIZATION_ID = MLN.ORGANIZATION_ID
          AND MOQ.LOT_NUMBER = MLN.LOT_NUMBER
          AND MOQ.LOT_NUMBER IS NOT NULL
          AND MOQ.ORGANIZATION_ID = CIC.ORGANIZATION_ID
          AND MOQ.INVENTORY_ITEM_ID = CIC.INVENTORY_ITEM_ID
          AND CIC.COST_TYPE_ID = 1
          AND msi.organization_id = ood.organization_id
          AND OOD.SET_OF_BOOKS_ID = GSOB.SET_OF_BOOKS_ID
          AND hou.organization_id = ood.operating_unit
   --        and msi.segment1='A1108'
   --        and ood.organization_code='310'
   --        order by msn.serial_number
   UNION ALL
   SELECT DISTINCT
          msi.organization_id,
          msi.inventory_item_id,
          msi.INVENTORY_ITEM_STATUS_CODE,
          msi.segment1 "ITEM_NUMBER",
          msi.description "ITEM_DESCRIPTION",
          msi.primary_uom_code,
          msi.unit_volume,
          ood.organization_code,
          ood.organization_name,
          msn.serial_number,
          moq.locator_id,
          --MSN.CURRENT_LOCATOR_ID,
          moq.subinventory_code,              --MSN.CURRENT_SUBINVENTORY_CODE,
          (SELECT mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             FROM APPS.MTL_ITEM_LOCATIONS MIL
            WHERE     mil.inventory_location_id = moq.locator_id
                  AND mil.organization_id = moq.organization_id
                  AND moq.subinventory_code = mil.subinventory_code)
             "LOCATOR",
          mln.lot_number,
          NULL "LOT_EXPIRATION_DATE",
          --            (cic.item_cost * MOQ.TRANSACTION_QUANTITY) "VALUE",
          (  cic.item_cost
           * (DECODE (msn.serial_number,
                      NULL, moq.transaction_quantity,
                      msn.serial_number, 1)))
             "value",
          DECODE (msn.serial_number,
                  NULL, moq.transaction_quantity,
                  msn.serial_number, 1)
             "ONHAND_QUANTITY",
          --MOQ.TRANSACTION_QUANTITY "ONHAND_QUANTITY",
          gsob.currency_code,
          msns.creation_date,
          NULL origination_date,
          hou.NAME "OPERATING_UNIT"
     FROM APPS.MTL_SYSTEM_ITEMS_B MSI,
          APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
          APPS.MTL_MATERIAL_TRANSACTIONS MOQ,
          apps.mtl_unit_transactions msn,
          APPS.MTL_SERIAL_NUMBERS MSNS,
          APPS.MTL_LOT_NUMBERS MLN,
          APPS.CST_ITEM_COSTS CIC,
          APPS.GL_SETS_OF_BOOKS GSOB,
          APPS.HR_OPERATING_UNITS HOU
    WHERE     cic.cost_type_id = 1
          AND mln.lot_number IS NULL
          AND msi.organization_id = ood.organization_id
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND moq.organization_id = msn.organization_id
          AND moq.inventory_item_id = msn.inventory_item_id
          AND moq.locator_id = msn.locator_id
          AND moq.subinventory_code = msn.subinventory_code
          AND moq.transaction_id = msn.transaction_id
          AND msn.organization_id = msns.current_organization_id
          AND msn.inventory_item_id = msns.inventory_item_id
          AND msn.subinventory_code = msns.current_subinventory_code
          AND msn.locator_id = msns.current_locator_id
          AND msn.serial_number = msns.serial_number
          AND msn.serial_number = msns.serial_number
          AND msi.organization_id = cic.organization_id
          AND msi.inventory_item_id = cic.inventory_item_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND hou.organization_id = ood.operating_unit
          AND msi.organization_id = mln.organization_id(+)
          AND msi.inventory_item_id = mln.inventory_item_id(+)
          AND msns.current_status(+) = 3
   --         and msi.segment1='1523013'   --'1523013'              --'90520AU'
   --       and ood.organization_code='150'
   --       order by msn.serial_number
   UNION ALL
   SELECT msi.organization_id,
          msi.inventory_item_id,
          msi.INVENTORY_ITEM_STATUS_CODE,
          msi.segment1 "ITEM_NUMBER",
          msi.description "ITEM_DESCRIPTION",
          msi.primary_uom_code,
          msi.unit_volume,
          ood.organization_code,
          ood.organization_name,
          msn.serial_number,
          moq.locator_id,
          --MSN.CURRENT_LOCATOR_ID,
          moq.subinventory_code,              --MSN.CURRENT_SUBINVENTORY_CODE,
          (SELECT mil.segment1 || '.' || mil.segment2 || '.' || mil.segment3
             FROM APPS.MTL_ITEM_LOCATIONS MIL
            WHERE     mil.inventory_location_id = moq.locator_id
                  AND mil.organization_id = moq.organization_id
                  AND moq.subinventory_code = mil.subinventory_code)
             "LOCATOR",
          moq.lot_number,
          NULL "LOT_EXPIRATION_DATE",
          (  cic.item_cost
           * (DECODE (msn.serial_number,
                      NULL, moq.transaction_quantity,
                      msn.serial_number, 1)))
             "VALUE",
          --(CIC.ITEM_COST * MOQ.TRANSACTION_QUANTITY) "VALUE",
          DECODE (msn.serial_number,
                  NULL, moq.transaction_quantity,
                  msn.serial_number, 1)
             "ONHAND_QUANTITY",
          --MOQ.TRANSACTION_QUANTITY "ONHAND_QUANTITY",
          gsob.currency_code,
          moq.creation_date,
          NULL origination_date,
          hou.NAME "OPERATING_UNIT"
     FROM APPS.MTL_SYSTEM_ITEMS_B MSI,
          APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
          apps.mtl_onhand_quantities moq,
          APPS.MTL_SERIAL_NUMBERS MSN,
          APPS.CST_ITEM_COSTS CIC,
          apps.gl_sets_of_books gsob,
          APPS.HR_OPERATING_UNITS HOU
    WHERE     cic.cost_type_id = 1
          AND moq.lot_number IS NULL
          AND msn.serial_number IS NULL
          AND msi.organization_id = ood.organization_id
          AND msi.organization_id = moq.organization_id
          AND msi.inventory_item_id = moq.inventory_item_id
          AND moq.organization_id = msn.current_organization_id(+)
          AND moq.inventory_item_id = msn.inventory_item_id(+)
          AND moq.locator_id = msn.current_locator_id(+)
          AND moq.subinventory_code = msn.current_subinventory_code(+)
          --        AND moq.update_transaction_id = msn.last_transaction_id(+)
          AND msi.organization_id = cic.organization_id
          AND msi.inventory_item_id = cic.inventory_item_id
          AND ood.set_of_books_id = gsob.set_of_books_id
          AND HOU.ORGANIZATION_ID = OOD.OPERATING_UNIT
          AND msn.current_status(+) = 3;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_INV_REPORT_V FOR APPS.XX_BI_INV_REPORT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_INV_REPORT_V FOR APPS.XX_BI_INV_REPORT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_INV_REPORT_V FOR APPS.XX_BI_INV_REPORT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_INV_REPORT_V FOR APPS.XX_BI_INV_REPORT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_INV_REPORT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_INV_REPORT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_INV_REPORT_V TO XXINTG;
