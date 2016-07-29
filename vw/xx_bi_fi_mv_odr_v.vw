DROP VIEW APPS.XX_BI_FI_MV_ODR_V;

/* Formatted on 6/6/2016 4:59:45 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_MV_ODR_V
(
   CREATION_DATE,
   DATE_REQUIRED,
   DESCRIPTION,
   FROM_SUBINVENTORY_CODE,
   HEADER_ID,
   LAST_UPDATE_DATE,
   ORGANIZATION_NAME,
   REQUEST_NUMBER,
   STATUS_DATE,
   TO_SUBINVENTORY_CODE,
   TRANSACTION_TYPE_NAME,
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
   TO_ACCOUNT_ACC_NO,
   HEADER_STATUS
)
AS
   SELECT TRH.CREATION_DATE,
          TRH.DATE_REQUIRED,
          TRH.DESCRIPTION,
          TRH.FROM_SUBINVENTORY_CODE,
          TRH.HEADER_ID,
          TRH.LAST_UPDATE_DATE,
          HOU.NAME,
          TRH.REQUEST_NUMBER,
          TRH.STATUS_DATE,
          TRH.TO_SUBINVENTORY_CODE,
          MTT.TRANSACTION_TYPE_NAME,
          (DECODE (
              TRH.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              TRH.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              TRH.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              TRH.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              TRH.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.DATE_REQUIRED, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             DATE_REQUIRED_DAY,
          (DECODE (
              TRH.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.DATE_REQUIRED, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             DATE_REQUIRED_MONTH,
          (DECODE (
              TRH.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.DATE_REQUIRED, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             DATE_REQUIRED_QUARTER,
          (DECODE (
              TRH.DATE_REQUIRED,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.DATE_REQUIRED, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             DATE_REQUIRED_YEAR,
          (DECODE (
              TRH.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (TRH.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              TRH.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              TRH.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              TRH.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (TRH.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              TRH.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.STATUS_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             STATUS_DATE_DAY,
          (DECODE (
              TRH.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.STATUS_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             STATUS_DATE_MONTH,
          (DECODE (
              TRH.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.STATUS_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             STATUS_DATE_QUARTER,
          (DECODE (
              TRH.STATUS_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (TRH.STATUS_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             STATUS_DATE_YEAR,
          NULL,
          DECODE (TRH.HEADER_STATUS,
                  '1', 'Incomplete',
                  '2', 'Pending Approval',
                  '3', 'Approved',
                  '4', 'Not Approved',
                  '5', 'Closed',
                  '6', 'Canceled',
                  '7', 'Pre Approved',
                  '8', 'Partially Approved',
                  '9', 'Canceled by Source',
                  NULL)
     FROM HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_TRANSACTION_TYPES MTT,
          GL_CODE_COMBINATIONS GLC,
          MTL_TXN_REQUEST_HEADERS TRH,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     HOU.ORGANIZATION_ID = TRH.ORGANIZATION_ID
          AND MTT.TRANSACTION_TYPE_ID = TRH.TRANSACTION_TYPE_ID
          AND GLC.CODE_COMBINATION_ID(+) = TRH.TO_ACCOUNT_ID
          AND OOD.ORGANIZATION_ID = TRH.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_MV_ODR_V FOR APPS.XX_BI_FI_MV_ODR_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_MV_ODR_V FOR APPS.XX_BI_FI_MV_ODR_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_MV_ODR_V FOR APPS.XX_BI_FI_MV_ODR_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_MV_ODR_V FOR APPS.XX_BI_FI_MV_ODR_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MV_ODR_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MV_ODR_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_MV_ODR_V TO XXINTG;
