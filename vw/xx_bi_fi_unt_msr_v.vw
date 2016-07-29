DROP VIEW APPS.XX_BI_FI_UNT_MSR_V;

/* Formatted on 6/6/2016 4:59:36 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_UNT_MSR_V
(
   CREATION_DATE,
   DESCRIPTION,
   END_EFFECTIVE_DATE,
   LAST_UPDATE_DATE,
   UNIT_OF_MEASURE_NAME,
   UOM_CLASS,
   UOM_CODE,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   END_EFFECTIVE_DATE_DAY,
   END_EFFECTIVE_DATE_MONTH,
   END_EFFECTIVE_DATE_QUARTER,
   END_EFFECTIVE_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   BASE_UNIT_FLAG
)
AS
   SELECT UN.CREATION_DATE,
          UN.DESCRIPTION,
          UN.DISABLE_DATE,
          UN.LAST_UPDATE_DATE,
          UN.UNIT_OF_MEASURE,
          UN.UOM_CLASS,
          UN.UOM_CODE,
          (DECODE (
              UN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              UN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              UN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              UN.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              UN.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.DISABLE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             END_EFFECTIVE_DATE_DAY,
          (DECODE (
              UN.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.DISABLE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             END_EFFECTIVE_DATE_MONTH,
          (DECODE (
              UN.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.DISABLE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             END_EFFECTIVE_DATE_QUARTER,
          (DECODE (
              UN.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.DISABLE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             END_EFFECTIVE_DATE_YEAR,
          (DECODE (
              UN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (UN.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              UN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              UN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UN.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              UN.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (UN.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          DECODE (UN.BASE_UOM_FLAG,  'N', 'No',  'Y', 'Yes',  NULL)
     FROM mtl_uom_classes uo, mtl_units_of_measure un
    WHERE UN.UOM_CLASS = UO.UOM_CLASS;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_UNT_MSR_V FOR APPS.XX_BI_FI_UNT_MSR_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_UNT_MSR_V FOR APPS.XX_BI_FI_UNT_MSR_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_UNT_MSR_V FOR APPS.XX_BI_FI_UNT_MSR_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_UNT_MSR_V FOR APPS.XX_BI_FI_UNT_MSR_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UNT_MSR_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UNT_MSR_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UNT_MSR_V TO XXINTG;
