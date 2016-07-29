DROP VIEW APPS.XX_BI_FI_UOM_CLASSES_V;

/* Formatted on 6/6/2016 4:59:36 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_UOM_CLASSES_V
(
   CREATION_DATE,
   DESCRIPTION,
   END_EFFECTIVE_DATE,
   LAST_UPDATE_DATE,
   UOM_CLASS_NAME,
   CREATION_DATE_1,
   CREATION_DATE_2,
   CREATION_DATE_3,
   CREATION_DATE_4,
   END_EFFECTIVE_DATE_1,
   END_EFFECTIVE_DATE_2,
   END_EFFECTIVE_DATE_3,
   END_EFFECTIVE_DATE_4,
   LAST_UPDATE_DATE_1,
   LAST_UPDATE_DATE_2,
   LAST_UPDATE_DATE_3,
   LAST_UPDATE_DATE_4
)
AS
   SELECT UO.CREATION_DATE,
          UO.DESCRIPTION,
          UO.DISABLE_DATE,
          UO.LAST_UPDATE_DATE,
          UO.UOM_CLASS,
          (DECODE (
              UO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              UO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              UO.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.DISABLE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              UO.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.DISABLE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.DISABLE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.DISABLE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.DISABLE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM'))),
          (DECODE (
              UO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (UO.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              UO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (UO.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              UO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (UO.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
     FROM mtl_uom_classes uo;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_UOM_CLASSES_V FOR APPS.XX_BI_FI_UOM_CLASSES_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_UOM_CLASSES_V FOR APPS.XX_BI_FI_UOM_CLASSES_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_UOM_CLASSES_V FOR APPS.XX_BI_FI_UOM_CLASSES_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_UOM_CLASSES_V FOR APPS.XX_BI_FI_UOM_CLASSES_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UOM_CLASSES_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UOM_CLASSES_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_UOM_CLASSES_V TO XXINTG;
