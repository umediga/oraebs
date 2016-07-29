DROP VIEW APPS.XX_BI_OE_SRL_NBR_V;

/* Formatted on 6/6/2016 4:59:16 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_SRL_NBR_V
(
   CREATION_DATE,
   END_ITEM_UNIT_NUMBER,
   LAST_TRANSACTION_ID,
   LAST_UPDATE_DATE,
   LOT_NUMBER,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   ORIGINAL_WIP_ENTITY_NAME,
   RECEIPT_DATE,
   REVISION,
   SERIAL_NUMBER,
   SHIP_DATE,
   SUBINVENTORY_NAME,
   UNIT_INITIALIZATION_DATE,
   VENDOR_LOT_NUMBER,
   VENDOR_NAME,
   VENDOR_SERIAL_NUMBER,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   RECEIPT_DATE_DAY,
   RECEIPT_DATE_MONTH,
   RECEIPT_DATE_QUARTER,
   RECEIPT_DATE_YEAR,
   SHIP_DATE_DAY,
   SHIP_DATE_MONTH,
   SHIP_DATE_QUARTER,
   SHIP_DATE_YEAR,
   UNIT_INITIALIZATION_DATE_DAY,
   UNIT_INI_DATE_MONTH,
   UNIT_INITIALIZATION_DATE_QUAR,
   UNIT_INITIALIZATION_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   INVENTORY_LOCATION_NAME,
   SERIAL_NUMBER_STATUS,
   LAST_RECEIPT_ISSUE_TYPE
)
AS
   SELECT MSN.CREATION_DATE,
          MSN.END_ITEM_UNIT_NUMBER,
          MSN.LAST_TRANSACTION_ID,
          MSN.LAST_UPDATE_DATE,
          MSN.LOT_NUMBER,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          WIP.WIP_ENTITY_NAME ORIGINAL_WIP_ENTITY_NAME,
          MSN.COMPLETION_DATE RECEIPT_DATE,
          MSN.REVISION,
          MSN.SERIAL_NUMBER,
          MSN.SHIP_DATE,
          MSN.CURRENT_SUBINVENTORY_CODE SUBINVENTORY_NAME,
          MSN.INITIALIZATION_DATE UNIT_INITIALIZATION_DATE,
          MSN.VENDOR_LOT_NUMBER,
          PO.VENDOR_NAME,
          MSN.VENDOR_SERIAL_NUMBER,
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MSN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MSN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             RECEIPT_DATE_DAY,
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             RECEIPT_DATE_MONTH,
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             RECEIPT_DATE_QUARTER,
          (DECODE (
              MSN.COMPLETION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.COMPLETION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             RECEIPT_DATE_YEAR,
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.SHIP_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             SHIP_DATE_DAY,
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MSN.SHIP_DATE, 'MM'), 'MM') || '1900',
                       'MMYYYY')))
             SHIP_DATE_MONTH,
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (MSN.SHIP_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             SHIP_DATE_QUARTER,
          (DECODE (
              MSN.SHIP_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MSN.SHIP_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             SHIP_DATE_YEAR,
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             UNIT_INITIALIZATION_DATE_DAY,
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             UNIT_INITIALIZATION_DATE_MONTH,
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             UNT_INITIALZTN_DATE_QTR,
          (DECODE (
              MSN.INITIALIZATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MSN.INITIALIZATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             UNIT_INITIALIZATION_DATE_YEAR,
          NULL,                                                    /*KeyFlex*/
          NULL,                                                    /*KeyFlex*/
          DECODE (MSN.CURRENT_STATUS,
                  '1', 'Defined but not used',
                  '3', 'Resides in stores',
                  '4', 'Issued out of stores',
                  '5', 'Resides in intransit',
                  NULL)
             SERIAL_NUMBER_STATUS,
          MSN.LAST_RECEIPT_ISSUE_TYPE
     FROM WIP_ENTITIES WIP,
          PO_VENDORS PO,
          MTL_SYSTEM_ITEMS MSIB,
          ORG_ORGANIZATION_DEFINITIONS OOD,
          MTL_ITEM_LOCATIONS MIL,
          MTL_SERIAL_NUMBERS MSN
    WHERE     MSIB.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND MSIB.INVENTORY_ITEM_ID = MSN.INVENTORY_ITEM_ID
          AND MIL.ORGANIZATION_ID(+) = MSN.CURRENT_ORGANIZATION_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MSN.CURRENT_LOCATOR_ID
          AND OOD.ORGANIZATION_ID = MSN.CURRENT_ORGANIZATION_ID
          AND WIP.WIP_ENTITY_ID(+) = MSN.ORIGINAL_WIP_ENTITY_ID
          AND PO.VENDOR_ID(+) = MSN.ORIGINAL_UNIT_VENDOR_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_SRL_NBR_V FOR APPS.XX_BI_OE_SRL_NBR_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_SRL_NBR_V FOR APPS.XX_BI_OE_SRL_NBR_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_SRL_NBR_V FOR APPS.XX_BI_OE_SRL_NBR_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_SRL_NBR_V FOR APPS.XX_BI_OE_SRL_NBR_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_SRL_NBR_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_SRL_NBR_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_SRL_NBR_V TO XXINTG;
