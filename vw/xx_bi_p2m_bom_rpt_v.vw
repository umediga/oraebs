DROP VIEW APPS.XX_BI_P2M_BOM_RPT_V;

/* Formatted on 6/6/2016 4:59:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2M_BOM_RPT_V
(
   BILL_ITEM_NUMBER,
   BILL_ITEM_NAME,
   COMPONENT_ITEM_NUMBER,
   COMPONENT_ITEM_NAME,
   EFFECTIVITY_DATE,
   DISABLE_DATE,
   IMPLEMENTATION_DATE,
   ORGANIZATION_CODE,
   QUANTITY_PER_ASSEMBLY_SUM
)
AS
     SELECT msib1.segment1 bill_item_number,
            msib1.description bill_item_name,
            MSIB2.SEGMENT1 COMPONENT_ITEM_number,
            MSIB2.description COMPONENT_ITEM_NAME,
            BIC.EFFECTIVITY_DATE,
            BIC.DISABLE_DATE,
            BIC.IMPLEMENTATION_DATE,
            OOD.ORGANIZATION_CODE,
            BIC.COMPONENT_QUANTITY QUANTITY_PER_ASSEMBLY_SUM
       FROM BOM_BILL_OF_MATERIALS BBOM,
            BOM_INVENTORY_COMPONENTS BIC,
            MTL_SYSTEM_ITEMS_B MSIB1,
            MTL_SYSTEM_ITEMS_B MSIB2,
            ORG_ORGANIZATION_DEFINITIONS OOD
      WHERE     BBOM.BILL_SEQUENCE_ID = BIC.BILL_SEQUENCE_ID
            AND MSIB1.INVENTORY_ITEM_ID = BBOM.ASSEMBLY_ITEM_ID
            AND MSIB2.INVENTORY_ITEM_ID = BIC.COMPONENT_ITEM_ID
            AND MSIB1.ORGANIZATION_ID = BBOM.ORGANIZATION_ID
            AND MSIB2.ORGANIZATION_ID = BBOM.ORGANIZATION_ID
            AND OOD.ORGANIZATION_ID = MSIB2.ORGANIZATION_ID
            AND OOD.ORGANIZATION_ID = MSIB1.ORGANIZATION_ID
   --and BIC.COMPONENT_ITEM_ID=25238
   --and BBOM.ORGANIZATION_ID=85
   ORDER BY MSIB1.SEGMENT1;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2M_BOM_RPT_V FOR APPS.XX_BI_P2M_BOM_RPT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2M_BOM_RPT_V FOR APPS.XX_BI_P2M_BOM_RPT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2M_BOM_RPT_V FOR APPS.XX_BI_P2M_BOM_RPT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2M_BOM_RPT_V FOR APPS.XX_BI_P2M_BOM_RPT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_BOM_RPT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_BOM_RPT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2M_BOM_RPT_V TO XXINTG;
