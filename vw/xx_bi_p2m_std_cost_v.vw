DROP VIEW APPS.XX_BI_P2M_STD_COST_V;

/* Formatted on 6/6/2016 4:59:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_STD_COST_V
(
   PROCESS_ITEM_NUMBER,
   ORGANIZATION,
   STANDARD_COST,
   DESCRIPTION,
   BUYER,
   ITEM_TYPE_NAME,
   COST_TYPE
)
AS
   SELECT MSIB.SEGMENT1 PROCESS_ITEM_NUMBER,
          OOD.ORGANIZATION_CODE organization,
          CST.ITEM_COST STANDARD_COST,
          MSIB.DESCRIPTION,
          PAPF.full_name buyer,
          FCL.MEANING ITEM_TYPE_NAME,
          CCT.COST_TYPE
     FROM ORG_ORGANIZATION_DEFINITIONS OOD,
          MTL_SYSTEM_ITEMS_B MSIB,
          CST_ITEM_COSTS CST,
          FND_COMMON_LOOKUPS FCL,
          PER_ALL_PEOPLE_F PAPF,
          CST_COST_TYPES CCT
    WHERE     MSIB.ORGANIZATION_ID = OOD.ORGANIZATION_ID
          AND MSIB.INVENTORY_ITEM_ID = CST.INVENTORY_ITEM_ID
          AND OOD.ORGANIZATION_ID = CST.ORGANIZATION_ID
          AND FCL.LOOKUP_CODE = MSIB.ITEM_TYPE
          AND FCL.LOOKUP_TYPE = 'ITEM_TYPE'
          AND MSIB.BUYER_ID = PAPF.PERSON_ID
          AND CCT.COST_TYPE_ID = CST.COST_TYPE_ID
          AND SYSDATE BETWEEN PAPF.EFFECTIVE_START_DATE
                          AND PAPF.EFFECTIVE_END_DATE;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_STD_COST_V FOR APPS.XX_BI_P2M_STD_COST_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_STD_COST_V FOR APPS.XX_BI_P2M_STD_COST_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_STD_COST_V FOR APPS.XX_BI_P2M_STD_COST_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_STD_COST_V FOR APPS.XX_BI_P2M_STD_COST_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_STD_COST_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_STD_COST_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_STD_COST_V TO XXINTG;
