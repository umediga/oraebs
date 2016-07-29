DROP VIEW APPS.XX_BI_SALES_LCTR_RPT;

/* Formatted on 6/6/2016 4:58:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_LCTR_RPT
(
   ORG_CODE,
   SUBINVENTORY_CODE,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   LOT_NUMBER,
   SERIAL_NUMBER,
   INV_ATTRIBUTE12,
   INV_ITEM_ATTRIBUTE_CATEGORY,
   ON_HAND_QUANTITY,
   LOCATOR_NAME,
   DIVISION
)
AS
   SELECT ood.organization_code "Org Code",
          moq.subinventory_code,
          msi.segment1 "Item Number",
          msi.description "Item Description",
          mln.LOT_NUMBER,
          msn.SERIAL_NUMBER,
          msi.Attribute12,
          msi.Attribute_Category INV_ITEM_ATTRIBUTE_CATEGORY,
          (  SELECT SUM (moq.TRANSACTION_QUANTITY)
               FROM apps.mtl_onhand_quantities moq2
              WHERE     moq.INVENTORY_ITEM_ID = moq2.INVENTORY_ITEM_ID
                    AND moq.ORGANIZATION_ID = moq2.ORGANIZATION_ID
           GROUP BY moq.TRANSACTION_QUANTITY)
             on_hand,
             mil.SEGMENT1
          || '.'
          || mil.SEGMENT2
          || '.'
          || mil.SEGMENT3
          || '.'
          || mil.SEGMENT4
             "Locator Name",
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
                  AND mic.inventory_item_id = msi.inventory_item_id
                  AND mic.organization_id = msi.organization_id)
             DIVISION
     FROM apps.mtl_system_items_b msi,
          apps.mtl_lot_numbers mln,
          apps.mtl_serial_numbers msn,
          apps.mtl_onhand_quantities moq,
          apps.mtl_item_locations mil,
          apps.org_organization_definitions ood
    WHERE     msi.INVENTORY_ITEM_ID = mln.INVENTORY_ITEM_ID(+)
          AND msi.ORGANIZATION_ID = mln.ORGANIZATION_ID(+)
          AND msi.INVENTORY_ITEM_ID = msn.INVENTORY_ITEM_ID(+)
          AND msi.ORGANIZATION_ID = msn.OWNING_ORGANIZATION_ID(+)
          AND msi.INVENTORY_ITEM_ID = moq.INVENTORY_ITEM_ID
          AND msi.ORGANIZATION_ID = moq.ORGANIZATION_ID
          AND moq.locator_id = mil.inventory_location_id
          AND moq.organization_id = mil.organization_id
          AND msi.organization_id = ood.organization_id
          AND mil.SUBINVENTORY_CODE = moq.SUBINVENTORY_CODE;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_LCTR_RPT FOR APPS.XX_BI_SALES_LCTR_RPT;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_LCTR_RPT FOR APPS.XX_BI_SALES_LCTR_RPT;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_LCTR_RPT FOR APPS.XX_BI_SALES_LCTR_RPT;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_LCTR_RPT FOR APPS.XX_BI_SALES_LCTR_RPT;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_LCTR_RPT TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_LCTR_RPT TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_LCTR_RPT TO XXINTG;
