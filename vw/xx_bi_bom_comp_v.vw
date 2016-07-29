DROP VIEW APPS.XX_BI_BOM_COMP_V;

/* Formatted on 6/6/2016 4:59:58 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_BOM_COMP_V
(
   START_EFFECTIVE_DATE,
   COMPONENT_ITEM_NAME,
   COMPONENT_DESCRIPTION,
   BILL_ITEM_NAME,
   BILL_ITEM_DESCRIPTION,
   COMPONENT_QUANTITY,
   REVISION,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   ALTERNATE_BOM_CODE,
   CHANGE_NOTICE,
   COMMENTS,
   ECO_IMPLEMENTATION_DATE,
   END_EFFECTIVE_DATE,
   SUPPLY_SUBINVENTORY,
   FROM_END_ITEM_UNIT_NUMBER,
   TO_END_ITEM_UNIT_NUMBER,
   INCLUDE_IN_COST_ROLLUP,
   CHECK_ATP,
   SHIPPABLE_ITEM_FLAG,
   INCLUDE_ON_SHIP_DOCS,
   MUTUALLY_EXCLUSIVE_OPT,
   OPTIONAL,
   QUANTITY_RELATED,
   REQUIRED_FOR_REVENUE,
   REQUIRED_TO_SHIP,
   SHIPPING_ALLOWED,
   SO_BASIS,
   WIP_SUPPLY_TYPE,
   UPDATED_ON,
   CREATED_ON,
   START_EFFECTIVE_DATE_YEAR,
   START_EFFECTIVE_DATE_QUARTER,
   START_EFFECTIVE_DATE_MONTH,
   START_EFFECTIVE_DATE_DAY,
   ECO_IMP_DATE_YEAR,
   ECO_IMP_DATE_QUARTER,
   ECO_IMP_DATE_MONTH,
   ECO_IMP_DATE_DAY,
   END_EFFECTIVE_DATE_YEAR,
   END_EFFECTIVE_DATE_QUARTER,
   END_EFFECTIVE_DATE_MONTH,
   END_EFFECTIVE_DATE_DAY,
   UPDATED_ON_YEAR,
   UPDATED_ON_QUARTER,
   UPDATED_ON_MONTH,
   UPDATED_ON_DAY,
   CREATED_ON_YEAR,
   CREATED_ON_QUARTER,
   CREATED_ON_MONTH,
   CREATED_ON_DAY,
   CREATED_BY_SUM,
   UPDATED_BY_SUM,
   COMPONENT_SEQUENCE_ID,
   COMPONENT_ITEM_ID,
   BILL_SEQUENCE_ID,
   ASSEMBLY_ITEM_ID,
   ORGANIZATION_ID,
   SUPPLY_LOCATOR_ID,
   OPERATION_OFFSET_IN_ROUTING,
   MAXIMUM_ALLOWED_QUANTITY,
   MINIMUM_ALLOWED_QUANTITY,
   PLANNING_PERCENT,
   PROJECTED_YIELD,
   QUANTITY_PER_ASSEMBLY,
   ITEM_SEQUENCE_NUMBER,
   OPERATION_SEQUENCE_NUMBER
)
AS
   SELECT BIC.EFFECTIVITY_DATE START_EFFECTIVE_DATE,
          MSIB1.SEGMENT1 COMPONENT_ITEM_NAME,
          MSIB1.DESCRIPTION,
          MSIB2.SEGMENT1 BILL_ITEM_NAME,
          MSIB2.DESCRIPTION,
          BIC.COMPONENT_QUANTITY,
          MIR.REVISION,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          BBOM.ALTERNATE_BOM_DESIGNATOR ALTERNATE_BOM_CODE,
          BIC.CHANGE_NOTICE,
          BIC.COMPONENT_REMARKS COMMENTS,
          BIC.IMPLEMENTATION_DATE ECO_IMPLEMENTATION_DATE,
          BIC.DISABLE_DATE END_EFFECTIVE_DATE,
          BIC.SUPPLY_SUBINVENTORY,
          BIC.FROM_END_ITEM_UNIT_NUMBER,
          BIC.TO_END_ITEM_UNIT_NUMBER,
          DECODE (BIC.INCLUDE_IN_COST_ROLLUP,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.CHECK_ATP,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (MSIB1.SHIPPABLE_ITEM_FLAG,  'Y', 'Yes',  'N', 'No'),
          DECODE (BIC.INCLUDE_ON_SHIP_DOCS,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.MUTUALLY_EXCLUSIVE_OPTIONS,
                  '1', 'Yes',
                  '2', 'No',
                  NULL),
          DECODE (BIC.OPTIONAL,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.QUANTITY_RELATED,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.REQUIRED_FOR_REVENUE,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.REQUIRED_TO_SHIP,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.SHIPPING_ALLOWED,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.SO_BASIS,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (BIC.WIP_SUPPLY_TYPE,
                  '1', 'Push',
                  '2', 'Assembly Pull',
                  '3', 'Operation Pull',
                  '4', 'Bulk',
                  '5', 'Supplier',
                  '6', 'Phantom',
                  '7', 'Based on Bill',
                  NULL),
          BIC.LAST_UPDATE_DATE UPDATED_ON,
          BIC.CREATION_DATE CREATED_ON,
          (DECODE (
              BIC.EFFECTIVITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.EFFECTIVITY_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             START_EFFECTIVE_DATE_YEAR,
          (DECODE (
              BIC.EFFECTIVITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.EFFECTIVITY_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             START_EFFECTIVE_DATE_QUARTER,
          (DECODE (
              BIC.EFFECTIVITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.EFFECTIVITY_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             START_EFFECTIVE_DATE_MONTH,
          (DECODE (
              BIC.EFFECTIVITY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.EFFECTIVITY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             START_EFFECTIVE_DATE_DAY,
          (DECODE (
              BIC.IMPLEMENTATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.IMPLEMENTATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             ECO_IMPLEMENTATION_DATE_YEAR,
          (DECODE (
              BIC.IMPLEMENTATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.IMPLEMENTATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ECO_IMP_DATE_QUARTER,
          (DECODE (
              BIC.IMPLEMENTATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.IMPLEMENTATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             ECO_IMPLEMENTATION_DATE_MONTH,
          (DECODE (
              BIC.IMPLEMENTATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.IMPLEMENTATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             ECO_IMPLEMENTATION_DATE_DAY,
          (DECODE (
              BIC.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.DISABLE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             END_EFFECTIVE_DATE_YEAR,
          (DECODE (
              BIC.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.DISABLE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             END_EFFECTIVE_DATE_QUARTER,
          (DECODE (
              BIC.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.DISABLE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             END_EFFECTIVE_DATE_MONTH,
          (DECODE (
              BIC.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.DISABLE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             END_EFFECTIVE_DATE_DAY,
          (DECODE (
              BIC.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             UPDATED_ON_YEAR,
          (DECODE (
              BIC.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             UPDATED_ON_QUARTER,
          (DECODE (
              BIC.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             UPDATED_ON_MONTH,
          (DECODE (
              BIC.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (BIC.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             UPDATED_ON_DAY,
          (DECODE (
              BIC.CREATION_DATE,
              TO_DATE (NULL, 'MMDDYYYY'), TO_DATE (
                                                TO_CHAR (
                                                   TRUNC (BIC.CREATION_DATE,
                                                          'YYYY'),
                                                   'YYYY')
                                             || '01',
                                             'YYYYMM')))
             CREATED_ON_YEAR,
          (DECODE (
              BIC.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATED_ON_QUARTER,
          (DECODE (
              BIC.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATED_ON_MONTH,
          (DECODE (
              BIC.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (BIC.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATED_ON_DAY,
          BIC.CREATED_BY,
          BIC.LAST_UPDATED_BY,
          BIC.COMPONENT_SEQUENCE_ID,
          BIC.COMPONENT_ITEM_ID,
          BIC.BILL_SEQUENCE_ID,
          BBOM.ASSEMBLY_ITEM_ID,
          BBOM.ORGANIZATION_ID,
          BIC.SUPPLY_LOCATOR_ID,
          BIC.OPERATION_LEAD_TIME_PERCENT,
          BIC.HIGH_QUANTITY,
          BIC.LOW_QUANTITY,
          BIC.PLANNING_FACTOR,
          BIC.COMPONENT_YIELD_FACTOR,
          BIC.COMPONENT_QUANTITY,
          BIC.ITEM_NUM,
          BIC.OPERATION_SEQ_NUM
     FROM ORG_ORGANIZATION_DEFINITIONS OOD,
          BOM_BILL_OF_MATERIALS BBOM,
          MTL_SYSTEM_ITEMS_B MSIB1,
          MTL_ITEM_LOCATIONS MIL,
          MTL_SYSTEM_ITEMS_B MSIB2,
          BOM_INVENTORY_COMPONENTS BIC,
          APPS.MTL_ITEM_REVISIONS MIR
    WHERE     BBOM.ORGANIZATION_ID = OOD.ORGANIZATION_ID
          AND BBOM.ASSEMBLY_ITEM_ID = MSIB2.INVENTORY_ITEM_ID
          AND BBOM.ORGANIZATION_ID = MSIB2.ORGANIZATION_ID
          AND BIC.COMPONENT_ITEM_ID = MSIB1.INVENTORY_ITEM_ID
          AND BBOM.ORGANIZATION_ID = MSIB1.ORGANIZATION_ID
          AND MSIB2.INVENTORY_ITEM_ID = MIR.INVENTORY_ITEM_ID
          AND BBOM.ORGANIZATION_ID = MIR.ORGANIZATION_ID
          AND MSIB2.ORGANIZATION_ID = MIR.ORGANIZATION_ID
          AND BIC.SUPPLY_LOCATOR_ID = MIL.INVENTORY_LOCATION_ID(+)
          AND BIC.BILL_SEQUENCE_ID = BBOM.BILL_SEQUENCE_ID
          AND BIC.IMPLEMENTATION_DATE IS NOT NULL
          AND DECODE (BIC.SUPPLY_LOCATOR_ID, NULL, -1, BBOM.ORGANIZATION_ID) =
                 DECODE (BIC.SUPPLY_LOCATOR_ID,
                         NULL, -1,
                         MIL.ORGANIZATION_ID);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_BOM_COMP_V FOR APPS.XX_BI_BOM_COMP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_BOM_COMP_V FOR APPS.XX_BI_BOM_COMP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_BOM_COMP_V FOR APPS.XX_BI_BOM_COMP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_BOM_COMP_V FOR APPS.XX_BI_BOM_COMP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_BOM_COMP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_BOM_COMP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_BOM_COMP_V TO XXINTG;
