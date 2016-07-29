DROP VIEW APPS.XX_BI_FI_TXN_TS_V;

/* Formatted on 6/6/2016 4:59:37 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_TXN_TS_V
(
   DESCRIPTION,
   INACTIVE_DATE,
   TRANSACTION_SOURCE_TYPE_NAME,
   TRANSACTION_TYPE_NAME,
   TYPE_CLASS,
   USER_DEFINED_FLAG,
   INACTIVE_DATE_DAY,
   INACTIVE_DATE_MONTH,
   INACTIVE_DATE_QUARTER,
   INACTIVE_DATE_YEAR,
   TRANSACTION_ACTION
)
AS
   SELECT MTT.DESCRIPTION,
          MTT.DISABLE_DATE,
          MTS.TRANSACTION_SOURCE_TYPE_NAME,
          MTT.TRANSACTION_TYPE_NAME,
          MTT.TYPE_CLASS,
          MTT.USER_DEFINED_FLAG,
          (DECODE (
              MTT.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MTT.DISABLE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             INACTIVE_DATE_DAY,
          (DECODE (
              MTT.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MTT.DISABLE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             INACTIVE_DATE_MONTH,
          (DECODE (
              MTT.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MTT.DISABLE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             INACTIVE_DATE_QUARTER,
          (DECODE (
              MTT.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MTT.DISABLE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             INACTIVE_DATE_YEAR,
          DECODE (MTT.TRANSACTION_ACTION_ID,
                  '1', 'Issue from stores',
                  '12', 'Intransit receipt',
                  '2', 'Subinventory transfer',
                  '21', 'Intransit shipment',
                  '24', 'Cost update',
                  '27', 'Receipt into stores',
                  '28', 'Staging transfer',
                  '29', 'Delivery adjustments',
                  '3', 'Direct organization transfer',
                  '30', 'WIP scrap transaction',
                  '31', 'Assembly completion',
                  '32', 'Assembly return',
                  '33', 'Negative component issue',
                  '34', 'Negative component return',
                  '35', 'Container transaction',
                  '4', 'Cycle count adjustment',
                  '40', 'Lot Split',
                  '41', 'Lot Merge',
                  '42', 'Lot Translate',
                  '43', 'Lot Update Quantity',
                  '5', 'Planning Transfer',
                  '50', 'Container Pack',
                  '51', 'Container Unpack',
                  '52', 'Container Split',
                  '55', 'Cost Group Transfer',
                  '6', 'Ownership Transfer',
                  '8', 'Physical inventory adjustment',
                  NULL)
     FROM MTL_TXN_SOURCE_TYPES MTS, MTL_TRANSACTION_TYPES MTT
    WHERE MTS.TRANSACTION_SOURCE_TYPE_ID = MTT.TRANSACTION_SOURCE_TYPE_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_TXN_TS_V FOR APPS.XX_BI_FI_TXN_TS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_TXN_TS_V FOR APPS.XX_BI_FI_TXN_TS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_TXN_TS_V FOR APPS.XX_BI_FI_TXN_TS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_TXN_TS_V FOR APPS.XX_BI_FI_TXN_TS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXN_TS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXN_TS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXN_TS_V TO XXINTG;
