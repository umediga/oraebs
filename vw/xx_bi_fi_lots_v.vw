DROP VIEW APPS.XX_BI_FI_LOTS_V;

/* Formatted on 6/6/2016 4:59:50 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_LOTS_V
(
   CREATION_DATE,
   EXPIRATION_DATE,
   LAST_UPDATE_DATE,
   PRODUCT#,
   DESCRIPTION,
   LOT_NUMBER,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   EXPIRATION_DATE_DAY,
   EXPIRATION_DATE_MONTH,
   EXPIRATION_DATE_QUARTER,
   EXPIRATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   INACTIVE_FLAG
)
AS
   SELECT MLN.CREATION_DATE,
          MLN.EXPIRATION_DATE,
          MLN.LAST_UPDATE_DATE,
          MSIB.SEGMENT1,
          MSIB.DESCRIPTION,
          MLN.LOT_NUMBER,
          OOD.ORGANIZATION_CODE,
          OOD.ORGANIZATION_NAME,
          (DECODE (
              MLN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MLN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MLN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MLN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MLN.EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MLN.EXPIRATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             EXPIRATION_DATE_DAY,
          (DECODE (
              MLN.EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.EXPIRATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             EXPIRATION_DATE_MONTH,
          (DECODE (
              MLN.EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.EXPIRATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             EXPIRATION_DATE_QUARTER,
          (DECODE (
              MLN.EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MLN.EXPIRATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             EXPIRATION_DATE_YEAR,
          (DECODE (
              MLN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MLN.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MLN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MLN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MLN.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MLN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MLN.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          NULL,                                               /*KeyFlexField*/
          DECODE (MLN.DISABLE_FLAG,  '1', 'Yes',  '2', 'No',  NULL)
             INACTIVE_FLAG
     FROM ORG_ORGANIZATION_DEFINITIONS OOD,
          MTL_SYSTEM_ITEMS_B MSIB,
          MTL_LOT_NUMBERS MLN
    WHERE     OOD.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
          AND MSIB.ORGANIZATION_ID = MLN.ORGANIZATION_ID
          AND MSIB.INVENTORY_ITEM_ID = MLN.INVENTORY_ITEM_ID
          AND OOD.ORGANIZATION_ID = MLN.ORGANIZATION_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_LOTS_V FOR APPS.XX_BI_FI_LOTS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_LOTS_V FOR APPS.XX_BI_FI_LOTS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_LOTS_V FOR APPS.XX_BI_FI_LOTS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_LOTS_V FOR APPS.XX_BI_FI_LOTS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_LOTS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_LOTS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_LOTS_V TO XXINTG;
