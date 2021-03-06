DROP VIEW APPS.XX_BI_P2M_ITM_PMY_V;

/* Formatted on 6/6/2016 4:59:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_ITM_PMY_V
(
   SHIPPED_QUANTITY,
   SHIPPING_QUANTITY,
   ITEM_ID,
   DESCRIPTION,
   ORDERED_DATE,
   PRODUCT_FAMILY,
   SALES_TYPE
)
AS
   SELECT DISTINCT
          OOL.SHIPPED_QUANTITY,
          OOL.SHIPPING_QUANTITY,
          MSIB.SEGMENT1 ITEM_ID,
          MSIB.DESCRIPTION,
          OOH.ORDERED_DATE,
          (SELECT FVT.DESCRIPTION
             FROM FND_FLEX_VALUE_SETS FVS,
                  FND_FLEX_VALUES FFV,
                  FND_FLEX_VALUES_TL FVT
            WHERE     ROWNUM = 1
                  AND FVS.FLEX_VALUE_SET_NAME = 'INTG_PRODUCT_CLASS'
                  AND FVT.LANGUAGE = 'US'
                  AND MCB.SEGMENT8 = FFV.FLEX_VALUE
                  AND FFV.FLEX_VALUE_SET_ID = FVS.FLEX_VALUE_SET_ID
                  AND FFV.FLEX_VALUE_ID = FVT.FLEX_VALUE_ID)
             PRODUCT_FAMILY,
          (SELECT FVT.DESCRIPTION
             FROM FND_FLEX_VALUE_SETS FVS,
                  FND_FLEX_VALUES FFV,
                  FND_FLEX_VALUES_TL FVT
            WHERE     ROWNUM = 1
                  AND FVS.FLEX_VALUE_SET_NAME = 'INTG_PRODUCT_TYPE'
                  AND FVT.LANGUAGE = 'US'
                  AND MCB.SEGMENT9 = FFV.FLEX_VALUE
                  AND FFV.FLEX_VALUE_SET_ID = FVS.FLEX_VALUE_SET_ID
                  AND FFV.FLEX_VALUE_ID = FVT.FLEX_VALUE_ID)
             SALES_TYPE
     FROM OE_ORDER_LINES_ALL OOL,
          MTL_SYSTEM_ITEMS_B MSIB,
          OE_ORDER_HEADERS_ALL OOH,
          MTL_ITEM_CATEGORIES MIC,
          MTL_CATEGORY_SETS_TL MCST,
          MTL_CATEGORY_SETS_B MCSB,
          MTL_CATEGORIES_B MCB
    WHERE     OOH.HEADER_ID = OOL.HEADER_ID
          AND MSIB.INVENTORY_ITEM_ID = OOL.INVENTORY_ITEM_ID
          AND MSIB.ORGANIZATION_ID = OOH.SHIP_FROM_ORG_ID
          AND MIC.CATEGORY_SET_ID = MCSB.CATEGORY_SET_ID
          AND MIC.CATEGORY_ID = MCB.CATEGORY_ID
          AND MCST.CATEGORY_SET_ID = MCSB.CATEGORY_SET_ID
          AND MIC.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND MIC.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
          AND (MCB.SEGMENT8 IS NOT NULL OR MCB.SEGMENT9 IS NOT NULL);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_ITM_PMY_V FOR APPS.XX_BI_P2M_ITM_PMY_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_ITM_PMY_V FOR APPS.XX_BI_P2M_ITM_PMY_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_ITM_PMY_V FOR APPS.XX_BI_P2M_ITM_PMY_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_ITM_PMY_V FOR APPS.XX_BI_P2M_ITM_PMY_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_ITM_PMY_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_ITM_PMY_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_ITM_PMY_V TO XXINTG;
