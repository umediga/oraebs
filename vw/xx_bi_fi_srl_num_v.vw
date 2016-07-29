DROP VIEW APPS.XX_BI_FI_SRL_NUM_V;

/* Formatted on 6/6/2016 4:59:39 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_SRL_NUM_V
(
   SERIAL_NUMBER,
   PRODUCT#,
   DESCRIPTION,
   INVENTORY_ITEM_ID,
   CURRENT_ORGANIZATION_ID,
   ORGANIZATION_CODE,
   NAME,
   INITIALIZATION_DATE,
   CURRENT_SUBINVENTORY_CODE,
   CURRENT_LOCATOR_ID,
   REVISION,
   LOT_NUMBER,
   CURRENT_STATUS,
   COMPLETION_DATE,
   SHIP_DATE,
   ORIGINAL_WIP_ENTITY_ID,
   WIP_ENTITY_NAME,
   ORIGINAL_UNIT_VENDOR_ID,
   VENDOR_NAME,
   VENDOR_SERIAL_NUMBER,
   VENDOR_LOT_NUMBER,
   LAST_TRANSACTION_ID,
   LAST_RECEIPT_ISSUE_TYPE,
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_DATE,
   END_ITEM_UNIT_NUMBER,
   CREATION_DATE_DD,
   CREATION_DATE_MM,
   CREATION_DATE_Q,
   CREATION_DATE_YYYY,
   LAST_UPDATE_DATE_DD,
   LAST_UPDATE_DATE_MM,
   LAST_UPDATE_DATE_Q,
   LAST_UPDATE_DATE_YYYY,
   RECEIPT_DATE_DD,
   RECEIPT_DATE_MM,
   RECEIPT_DATE_Q,
   RECEIPT_DATE_YYYY,
   SHIP_DATE_DD,
   SHIP_DATE_MM,
   SHIP_DATE_Q,
   SHIP_DATE_YYYY,
   UNIT_INITIALIZATION_DATE_DD,
   UNIT_INITIALIZATION_DATE_MM,
   UNIT_INITIALIZATION_DATE_Q,
   UNIT_INITIALIZATION_DATE_YYYY
)
AS
   SELECT MSN.SERIAL_NUMBER,
          MSI.SEGMENT1,
          MSI.DESCRIPTION,
          MSN.INVENTORY_ITEM_ID,
          MSN.CURRENT_ORGANIZATION_ID,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MSN.INITIALIZATION_DATE,
          MSN.CURRENT_SUBINVENTORY_CODE,
          MSN.CURRENT_LOCATOR_ID,
          MSN.REVISION,
          MSN.LOT_NUMBER,
          DECODE (MSN.CURRENT_STATUS,
                  '1', 'Defined but not used',
                  '3', 'Resides in stores',
                  '4', 'Issued out of stores',
                  '5', 'Resides in intransit',
                  NULL),                                          /* LOOKUP */
          MSN.COMPLETION_DATE,
          MSN.SHIP_DATE,
          MSN.ORIGINAL_WIP_ENTITY_ID,
          WIP.WIP_ENTITY_NAME,
          MSN.ORIGINAL_UNIT_VENDOR_ID,
          PO.VENDOR_NAME,
          MSN.VENDOR_SERIAL_NUMBER,
          MSN.VENDOR_LOT_NUMBER,
          MSN.LAST_TRANSACTION_ID,
          MSN.LAST_RECEIPT_ISSUE_TYPE,
          MSN.CREATED_BY,
          MSN.CREATION_DATE,
          MSN.LAST_UPDATED_BY,
          MSN.LAST_UPDATE_DATE,
          MSN.END_ITEM_UNIT_NUMBER,
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM'))),
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM'))),
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.SHIP_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MSN.SHIP_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY'))),
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MSN.SHIP_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY'))),
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.SHIP_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY'))),
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
     FROM WIP_ENTITIES WIP,
          PO_VENDORS PO,
          MTL_PARAMETERS MP,
          MTL_SYSTEM_ITEMS MSI,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_ITEM_LOCATIONS MIL,
          MTL_SERIAL_NUMBERS MSN,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = MSN.INVENTORY_ITEM_ID
          AND MIL.ORGANIZATION_ID(+) = MSN.CURRENT_ORGANIZATION_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MSN.CURRENT_LOCATOR_ID
          AND MP.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND WIP.WIP_ENTITY_ID(+) = MSN.ORIGINAL_WIP_ENTITY_ID
          AND PO.VENDOR_ID(+) = MSN.ORIGINAL_UNIT_VENDOR_ID
          AND OOD.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_SRL_NUM_V FOR APPS.XX_BI_FI_SRL_NUM_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_SRL_NUM_V FOR APPS.XX_BI_FI_SRL_NUM_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_SRL_NUM_V FOR APPS.XX_BI_FI_SRL_NUM_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_SRL_NUM_V FOR APPS.XX_BI_FI_SRL_NUM_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SRL_NUM_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SRL_NUM_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SRL_NUM_V TO XXINTG;
