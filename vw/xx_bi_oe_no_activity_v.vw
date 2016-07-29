DROP VIEW APPS.XX_BI_OE_NO_ACTIVITY_V;

/* Formatted on 6/6/2016 4:59:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_NO_ACTIVITY_V
(
   ORDER_NUMBER,
   SUB_INVENTORY,
   SUB_INVENTORY_DESC,
   ORDER_TYPE,
   ORDER_ITEM,
   LINE,
   LINE_TYPE,
   FULFILLED_QUANTITY,
   SELL_PRICE,
   EXT_PRICE,
   FULFILLMENT_DATE_MONTH,
   FULFILLMENT_DATE_YEAR,
   SHIP_FROM_ORG_ID,
   ORG_CODE,
   SHIPMENT_PRIORITY_CODE,
   ORDER_QUANTITY_UOM,
   ITEM_TYPE_CODE,
   LINE_CATEGORY_CODE,
   SCHEDULE_STATUS_CODE,
   FLOW_STATUS_CODE,
   MATERIAL_ACCOUNT,
   EXPENSE_ACCOUNT,
   SOURCE_LANG
)
AS
   SELECT ooh.ORDER_NUMBER,
          msi.SECONDARY_INVENTORY_NAME "SECONDARY_INVENTORY_NAME",
          msi.description "SECONDARY_INVENTORY_DESC",
          (SELECT ott1.NAME
             FROM oe_transaction_types_tl ott1
            WHERE     ott1.language = USERENV ('LANG')
                  AND ott1.transaction_type_id = ooh.order_type_id)
             "ORDER_TYPE",
          ool.ORDERED_ITEM,
          ool.LINE_NUMBER,
          ott.NAME "Line_Type",
          ool.FULFILLED_QUANTITY,
          ool.UNIT_SELLING_PRICE,
          NVL ( (ool.ordered_quantity * ool.unit_selling_price), 0) Ext_Price,
          TO_CHAR (ool.FULFILLMENT_DATE, 'MONTH') "FULFILLMENT_DATE_MONTH",
          TO_CHAR (ool.FULFILLMENT_DATE, 'YYYY') "FULFILLMENT_DATE_YEAR",
          ool.ship_from_org_id ship_from_org_id,
          OOD.ORGANIZATION_CODE,
          OOH.SHIPMENT_PRIORITY_CODE,
          OOL.ORDER_QUANTITY_UOM,
          OOL.ITEM_TYPE_CODE,
          OOL.LINE_CATEGORY_CODE,
          OOL.SCHEDULE_STATUS_CODE,
          OOL.FLOW_STATUS_CODE,
          --msi.SUBINVENTORY_CODE,
          msi.MATERIAL_ACCOUNT,
          msi.EXPENSE_ACCOUNT,
          ott.SOURCE_LANG
     FROM apps.oe_order_headers_all ooh,
          apps.oe_order_lines_all ool,
          --mtl_material_transactions mmt,
          mtl_secondary_inventories msi,
          apps.oe_transaction_types_tl ott,
          APPS.ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     ool.header_id = ooh.header_id
          AND ool.org_id = ooh.org_id
          --AND mmt.source_line_id = ool.line_id
          --AND mmt.inventory_item_id = ool.INVENTORY_ITEM_ID
          --AND mmt.organization_id = NVL (ool.ship_from_org_id, 0)
          AND msi.secondary_inventory_name = ool.subinventory(+)
          ---AND msi.organization_id = NVL (ool.ship_from_org_id, ooh.ship_from_org_id) Commented for UAT BUG
          AND ool.ship_from_org_id = msi.organization_id   --Added for UAT BUG
          --AND msi.organization_id =ooh.ship_from_org_id
          AND ott.transaction_type_id = ool.line_type_id
          -- AND ood.organization_id =NVL (ool.ship_from_org_id, ooh.ship_from_org_id)--Commented for UAT BUG
          AND ood.organization_id = ool.ship_from_org_id   --Added for UAT BUG
          AND ott.language = USERENV ('LANG');


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_NO_ACTIVITY_V FOR APPS.XX_BI_OE_NO_ACTIVITY_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_NO_ACTIVITY_V FOR APPS.XX_BI_OE_NO_ACTIVITY_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_NO_ACTIVITY_V FOR APPS.XX_BI_OE_NO_ACTIVITY_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_NO_ACTIVITY_V FOR APPS.XX_BI_OE_NO_ACTIVITY_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_NO_ACTIVITY_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_NO_ACTIVITY_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_NO_ACTIVITY_V TO XXINTG;
