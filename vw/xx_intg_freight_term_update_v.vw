DROP VIEW APPS.XX_INTG_FREIGHT_TERM_UPDATE_V;

/* Formatted on 6/6/2016 4:58:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_INTG_FREIGHT_TERM_UPDATE_V
(
   FRUPD_ID,
   ORGANIZATION_ID,
   OPERATING_UNIT,
   RANK,
   TRANSACTION_TYPE_ID,
   ORDER_TYPE,
   INVENTORY_ITEM_ID,
   PART_NO,
   CATEGORY,
   SHIP_PRIORITY,
   SHIP_PRI_MEANING,
   SHIP_METHOD_FROM,
   SHIP_METHOD_TO,
   FREIGHT_TERMS,
   DATE_FROM,
   DATE_TO,
   INV_ORG_ID,
   INV_ORG_NAME,
   CREATION_DATE,
   CREATED_BY,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY
)
AS
   SELECT a.frupd_id,
          a.ORGANIZATION_ID,
          b.name OPERATING_UNIT,
          a.RANK,
          a.TRANSACTION_TYPE_ID,
          (SELECT name
             FROM OE_TRANSACTION_TYPES_TL
            WHERE     language = 'US'
                  AND transaction_type_id = a.transaction_type_id)
             ORDER_TYPE,
          a.INVENTORY_ITEM_ID,
          (SELECT segment1
             FROM MTL_SYSTEM_ITEMS_B m, ORG_ORGANIZATION_DEFINITIONS B
            WHERE     B.ORGANIZATION_NAME = 'IO INTEGRA ITEM MASTER'
                  AND m.INVENTORY_ITEM_ID = a.INVENTORY_ITEM_ID
                  AND m.organization_id = b.organization_id)
             PART_NO,
          a.CATEGORY,
          a.Ship_Priority,
          (SELECT meaning
             FROM FND_LOOKUP_VALUES
            WHERE     lookup_type = 'SHIPMENT_PRIORITY'
                  AND LANGUAGE = 'US'
                  AND enabled_flag = 'Y'
                  AND lookup_code = a.Ship_Priority)
             SHIP_PRI_MEANING,
          a.SHIP_METHOD_FROM,
          a.SHIP_METHOD_TO,
          a.FREIGHT_TERMS,
          a.DATE_FROM,
          a.DATE_TO,
          a.INV_ORG_ID,
          (SELECT organization_code
             FROM ORG_ORGANIZATION_DEFINITIONS
            WHERE organization_id = a.INV_ORG_ID)
             INV_ORG_NAME,
          a.CREATION_DATE,
          a.CREATED_BY,
          a.LAST_UPDATE_DATE,
          a.LAST_UPDATE_BY LAST_UPDATED_BY
     FROM XX_INTG_FREIGHT_TERM_UPDATE a, hr_operating_units b
    WHERE a.organization_id = b.organization_id;
