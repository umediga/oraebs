DROP VIEW APPS.XX_BI_OE_MVODR_LN_V;

/* Formatted on 6/6/2016 4:59:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_MVODR_LN_V
(
   CREATION_DATE,
   DATE_REQUIRED,
   FROM_SUBINVENTORY_CODE,
   HEADER_ID,
   LAST_UPDATE_DATE,
   LINE_ID,
   LOT_NUMBER,
   ORGANIZATION_NAME,
   PROJECT_NUMBER,
   REASON_ID,
   REFERENCE_ID,
   REFERENCE_NUMBER,
   REVISION,
   SERIAL_NUMBER_END,
   SERIAL_NUMBER_START,
   STATUS_DATE,
   TASK_NUMBER,
   TO_SUBINVENTORY_CODE,
   TRANSACTION_SOURCE_TYPE_NAME,
   TRANSACTION_TYPE_NAME,
   UOM_CODE,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   DATE_REQUIRED_DAY,
   DATE_REQUIRED_MONTH,
   DATE_REQUIRED_QUARTER,
   DATE_REQUIRED_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   STATUS_DATE_DAY,
   STATUS_DATE_MONTH,
   STATUS_DATE_QUARTER,
   STATUS_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   FROM_LOCATOR_NAME,
   TO_LOCATOR_NAME,
   TO_ACCOUNT_ACC_NO,
   REFERENCE_TYPE,
   LINE_STATUS_NAME,
   QUANTITY_DETAILED,
   QUANTITY_DELIVERED,
   QUANTITY,
   LINE_NUMBER
)
AS
   SELECT TRL.CREATION_DATE,
          TRL.DATE_REQUIRED,
          TRL.FROM_SUBINVENTORY_CODE,
          TRL.HEADER_ID,
          TRL.LAST_UPDATE_DATE,
          TRL.LINE_ID,
          TRL.LOT_NUMBER,
          HOU.NAME,
          PJM.PROJECT_NUMBER,
          MTR.REASON_NAME,
          TRL.REFERENCE_ID,
          TRH.REQUEST_NUMBER,
          TRL.REVISION,
          TRL.SERIAL_NUMBER_END,
          TRL.SERIAL_NUMBER_START,
          TRL.STATUS_DATE,
          PTS.TASK_NUMBER,
          TRL.TO_SUBINVENTORY_CODE,
          MST.TRANSACTION_SOURCE_TYPE_NAME,
          MTT.TRANSACTION_TYPE_NAME,
          TRL.UOM_CODE,
          (DECODE (
              TRL.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              TRL.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              TRL.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              TRL.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              TRL.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.DATE_REQUIRED, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             DATE_REQUIRED_DAY,
          (DECODE (
              TRL.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.DATE_REQUIRED, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             DATE_REQUIRED_MONTH,
          (DECODE (
              TRL.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.DATE_REQUIRED, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             DATE_REQUIRED_QUARTER,
          (DECODE (
              TRL.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.DATE_REQUIRED, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             DATE_REQUIRED_YEAR,
          (DECODE (
              TRL.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (TRL.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              TRL.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              TRL.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              TRL.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (TRL.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              TRL.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.STATUS_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             STATUS_DATE_DAY,
          (DECODE (
              TRL.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.STATUS_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             STATUS_DATE_MONTH,
          (DECODE (
              TRL.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.STATUS_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             STATUS_DATE_QUARTER,
          (DECODE (
              TRL.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRL.STATUS_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             STATUS_DATE_YEAR,
          NULL,
          NULL,
          NULL,
          NULL,
          DECODE (TRL.REFERENCE_TYPE_CODE,
                  '1', 'Optional reference entries',
                  '2', 'Reference entries required',
                  NULL),
          DECODE (TRL.LINE_STATUS,
                  '1', 'Incomplete',
                  '2', 'Pending Approval',
                  '3', 'Approved',
                  '4', 'Not Approved',
                  '5', 'Closed',
                  '6', 'Canceled',
                  '7', 'Pre Approved',
                  '8', 'Partially Approved',
                  '9', 'Canceled by Source',
                  NULL),
          TRL.QUANTITY_DETAILED,
          TRL.QUANTITY_DELIVERED,
          TRL.QUANTITY,
          TRL.LINE_NUMBER
     FROM MTL_SYSTEM_ITEMS MSI,
          GL_CODE_COMBINATIONS GLC,
          MTL_ITEM_LOCATIONS MIL,
          MTL_ITEM_LOCATIONS MIT,
          MTL_TRANSACTION_REASONS MTR,
          HR_ALL_ORGANIZATION_UNITS HOU,
          PJM_PROJECTS_V PJM,
          PA_TASKS PTS,
          MTL_KANBAN_CARDS MKC,
          MTL_TRANSACTION_TYPES MTT,
          MTL_TXN_SOURCE_TYPES MST,
          MTL_TXN_REQUEST_HEADERS TRH,
          MTL_TXN_REQUEST_LINES TRL,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.INVENTORY_ITEM_ID = TRL.INVENTORY_ITEM_ID
          AND MSI.ORGANIZATION_ID = TRL.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = TRL.ORGANIZATION_ID
          AND GLC.CODE_COMBINATION_ID(+) = TRL.TO_ACCOUNT_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = TRL.FROM_LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = TRL.ORGANIZATION_ID
          AND MIT.INVENTORY_LOCATION_ID(+) = TRL.TO_LOCATOR_ID
          AND MIT.ORGANIZATION_ID(+) = TRL.ORGANIZATION_ID
          AND MTR.REASON_ID(+) = TRL.REASON_ID
          AND PJM.PROJECT_ID(+) = TRL.PROJECT_ID
          AND PTS.TASK_ID(+) = TRL.TASK_ID
          AND PTS.PROJECT_ID(+) = TRL.PROJECT_ID
          AND MKC.KANBAN_CARD_ID(+) = TRL.REFERENCE_ID
          AND TRH.HEADER_ID = TRL.HEADER_ID
          AND MTT.TRANSACTION_TYPE_ID = TRH.TRANSACTION_TYPE_ID
          AND MTT.TRANSACTION_SOURCE_TYPE_ID = MST.TRANSACTION_SOURCE_TYPE_ID
          AND OOD.ORGANIZATION_ID = TRL.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_MVODR_LN_V FOR APPS.XX_BI_OE_MVODR_LN_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_MVODR_LN_V FOR APPS.XX_BI_OE_MVODR_LN_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_MVODR_LN_V FOR APPS.XX_BI_OE_MVODR_LN_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_MVODR_LN_V FOR APPS.XX_BI_OE_MVODR_LN_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_MVODR_LN_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_MVODR_LN_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_MVODR_LN_V TO XXINTG;
