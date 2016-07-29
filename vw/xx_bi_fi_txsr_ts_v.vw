DROP VIEW APPS.XX_BI_FI_TXSR_TS_V;

/* Formatted on 6/6/2016 4:59:36 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_TXSR_TS_V
(
   CREATION_DATE,
   DESCRIPTION,
   DISABLE_DATE,
   LAST_UPDATE_DATE,
   TRANSACTION_SOURCE_TYPE_NAME,
   CREATION_DATE_DD,
   CREATION_DATE_MM,
   CREATION_DATE_Q,
   CREATION_DATE_YYYY,
   DISABLE_DATE_DD,
   DISABLE_DATE_MM,
   DISABLE_DATE_Q,
   DISABLE_DATE_YYYY,
   LAST_UPDATE_DATE_DD,
   LAST_UPDATE_DATE_MM,
   LAST_UPDATE_DATE_Q,
   LAST_UPDATE_DATE_YYYY,
   USER_DEFINED_FLAG,
   VALIDATED_FLAG
)
AS
   SELECT MST.CREATION_DATE CREATION_DATE,
          MST.DESCRIPTION DESCRIPTION,
          MST.DISABLE_DATE DISABLE_DATE,
          MST.LAST_UPDATE_DATE LAST_UPDATE_DATE,
          MST.TRANSACTION_SOURCE_TYPE_NAME TRANSACTION_SOURCE_TYPE_NAME,
          (DECODE (
              MST.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DD,
          (DECODE (
              MST.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MM,
          (DECODE (
              MST.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_Q,
          (DECODE (
              MST.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YYYY,
          (DECODE (
              MST.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.DISABLE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             DISABLE_DATE_DD,
          (DECODE (
              MST.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.DISABLE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             DISABLE_DATE_MM,
          (DECODE (
              MST.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.DISABLE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             DISABLE_DATE_Q,
          (DECODE (
              MST.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.DISABLE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             DISABLE_DATE_YYYY,
          (DECODE (
              MST.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MST.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DD,
          (DECODE (
              MST.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MM,
          (DECODE (
              MST.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MST.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_Q,
          (DECODE (
              MST.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MST.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YYYY,
          DECODE (MST.USER_DEFINED_FLAG,  'N', 'No',  'Y', 'Yes',  NULL)
             USER_DEFINED_FLAG,
          DECODE (MST.VALIDATED_FLAG,
                  '1', 'Value set',
                  '2', 'None',
                  '3', 'System',
                  NULL)
             VALIDATED_FLAG
     FROM MTL_TXN_SOURCE_TYPES MST;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_TXSR_TS_V FOR APPS.XX_BI_FI_TXSR_TS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_TXSR_TS_V FOR APPS.XX_BI_FI_TXSR_TS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_TXSR_TS_V FOR APPS.XX_BI_FI_TXSR_TS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_TXSR_TS_V FOR APPS.XX_BI_FI_TXSR_TS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXSR_TS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXSR_TS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_TXSR_TS_V TO XXINTG;
