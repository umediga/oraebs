DROP VIEW APPS.XX_BI_FI_SN_TRX_V;

/* Formatted on 6/6/2016 4:59:39 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_SN_TRX_V
(
   TRANSACTION_ID,
   SERIAL_TRANSACTION_ID,
   SERIAL_NUMBER,
   PRODUCT#,
   DESCRIPTION,
   INVENTORY_ITEM_ID,
   ORGANIZATION_ID,
   NAME,
   ORGANIZATION_CODE,
   SUBINVENTORY_CODE,
   LOCATOR_ID,
   LOT_NUMBER,
   TRANSACTION_DATE,
   TRANSACTION_SOURCE_ID,
   TRANSACTION_SOURCE_TYPE_NAME,
   TRANSACTION_SOURCE_NAME,
   RECEIPT_ISSUE_TYPE,
   PRIMARY_UOM_CODE,
   CREATED_BY,
   CREATION_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_DATE,
   CREATION_DATE_DD,
   CREATION_DATE_MM,
   CREATION_DATE_Q,
   CREATION_DATE_YYYY,
   LAST_UPDATE_DATE_DD,
   LAST_UPDATE_DATE_MM,
   LAST_UPDATE_DATE_Q,
   LAST_UPDATE_DATE_YYYY,
   TRANSACTION_DATE_DD,
   TRANSACTION_DATE_MM,
   TRANSACTION_DATE_Q,
   TRANSACTION_DATE_YYYY
)
AS
   SELECT MLN.TRANSACTION_ID,
          MLN.SERIAL_TRANSACTION_ID,
          MUT.SERIAL_NUMBER,
          MSI.SEGMENT1,
          MSI.DESCRIPTION,
          MUT.INVENTORY_ITEM_ID,
          MUT.ORGANIZATION_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          MUT.SUBINVENTORY_CODE,
          MUT.LOCATOR_ID,
          MLN.LOT_NUMBER,
          MUT.TRANSACTION_DATE,
          MUT.TRANSACTION_SOURCE_ID,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          MUT.TRANSACTION_SOURCE_NAME,
          MUT.RECEIPT_ISSUE_TYPE,
          MSI.PRIMARY_UOM_CODE,
          MUT.CREATED_BY,
          MUT.CREATION_DATE,
          MUT.LAST_UPDATED_BY,
          MUT.LAST_UPDATE_DATE,
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
     FROM MTL_SYSTEM_ITEMS_B MSI,
          MTL_TRANSACTION_LOT_NUMBERS MLN,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_TXN_SOURCE_TYPES MTS,
          MTL_UNIT_TRANSACTIONS MUT,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MTS.TRANSACTION_SOURCE_TYPE_ID = MUT.TRANSACTION_SOURCE_TYPE_ID
          AND HOU.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MLN.SERIAL_TRANSACTION_ID = MUT.TRANSACTION_ID
          AND MSI.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = MUT.INVENTORY_ITEM_ID
          AND OOD.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE'
   UNION ALL /* If the item is NOT UNDER LOT control then join to MTL_MATERIAL_TRANSACTIONS directly as the MTL_UNIT_TRANSACTIONS.TRANSACTION_ID is actually MTL_MATERIAL_TRANSACTIONS.TRANSACTION_ID*/
   SELECT MUT.TRANSACTION_ID,
          TO_NUMBER (NULL),
          MUT.SERIAL_NUMBER,
          MSI.SEGMENT1,
          MSI.DESCRIPTION,
          MUT.INVENTORY_ITEM_ID,
          MUT.ORGANIZATION_ID,
          HOU.NAME,
          MP.ORGANIZATION_CODE,
          MUT.SUBINVENTORY_CODE,
          MUT.LOCATOR_ID,
          NULL,
          MUT.TRANSACTION_DATE,
          MUT.TRANSACTION_SOURCE_ID,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          MUT.TRANSACTION_SOURCE_NAME,
          MUT.RECEIPT_ISSUE_TYPE,
          MSI.PRIMARY_UOM_CODE,
          MUT.CREATED_BY,
          MUT.CREATION_DATE,
          MUT.LAST_UPDATED_BY,
          MUT.LAST_UPDATE_DATE,
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              MUT.TRANSACTION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MUT.TRANSACTION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
     FROM MTL_SYSTEM_ITEMS_B MSI,
          MTL_MATERIAL_TRANSACTIONS MMT,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_TXN_SOURCE_TYPES MTS,
          MTL_UNIT_TRANSACTIONS MUT,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MTS.TRANSACTION_SOURCE_TYPE_ID = MUT.TRANSACTION_SOURCE_TYPE_ID
          AND HOU.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MP.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MMT.TRANSACTION_ID = MUT.TRANSACTION_ID
          AND MSI.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = MUT.INVENTORY_ITEM_ID
          AND OOD.ORGANIZATION_ID = MUT.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE'
          AND MMT.ORGANIZATION_ID =
                 NVL (MMT.OWNING_ORGANIZATION_ID, MMT.ORGANIZATION_ID)
          AND NVL (MMT.OWNING_TP_TYPE, 2) = 2
   WITH READ ONLY;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_SN_TRX_V FOR APPS.XX_BI_FI_SN_TRX_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_SN_TRX_V FOR APPS.XX_BI_FI_SN_TRX_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_SN_TRX_V FOR APPS.XX_BI_FI_SN_TRX_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_SN_TRX_V FOR APPS.XX_BI_FI_SN_TRX_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SN_TRX_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SN_TRX_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_SN_TRX_V TO XXINTG;
