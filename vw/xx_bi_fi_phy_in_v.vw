DROP VIEW APPS.XX_BI_FI_PHY_IN_V;

/* Formatted on 6/6/2016 4:59:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_PHY_IN_V
(
   CREATION_DATE,
   DESCRIPTION,
   LAST_ADJUSTMENT_DATE,
   LAST_UPDATE_DATE,
   NEGATIVE_APPROVAL_TOLERANCE,
   NEGATIVE_COST_VARIANCE,
   NEXT_TAG_NUMBER,
   NUMBER_OF_SKUS,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   PHYSICAL_INVENTORY_DATE,
   PHYSICAL_INVENTORY_NAME,
   POSITIVE_APPROVAL_TOLERANCE,
   POSITIVE_COST_VARIANCE,
   SNAPSHOT_DATE,
   TAG_NUMBER_INCREMENTS,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_ADJUSTMENT_DATE_DAY,
   LAST_ADJUSTMENT_DATE_MONTH,
   LAST_ADJUSTMENT_DATE_QUARTER,
   LAST_ADJUSTMENT_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUATER,
   LAST_UPDATE_DATE_YEAR,
   PHYSICAL_INV_DATE_DAY,
   PHYSICAL_INV_DATE_MONTH,
   PHYSICAL_INV_DATE_QUARTER,
   PHYSICAL_INV_DATE_YEAR,
   SNAPSHOT_DATE_DAY,
   SNAPSHOT_DATE_MONTH,
   SNAPSHOT_DATE_QUARTER,
   SNAPSHOT_DATE_YEAR,
   APPROVAL_FLAG,
   ALL_SUBINVENTORIES_FLAG,
   ALLOW_DYNAMIC_TAGS_FLAG,
   TOTAL_ADJUSTMENT_VALUE
)
AS
   SELECT MPI.CREATION_DATE,
          MPI.DESCRIPTION,
          MPI.LAST_ADJUSTMENT_DATE,
          MPI.LAST_UPDATE_DATE,
          MPI.APPROVAL_TOLERANCE_NEG,
          MPI.COST_VARIANCE_NEG,
          MPI.NEXT_TAG_NUMBER,
          MPI.NUMBER_OF_SKUS,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MPI.PHYSICAL_INVENTORY_DATE,
          MPI.PHYSICAL_INVENTORY_NAME,
          MPI.APPROVAL_TOLERANCE_POS,
          MPI.COST_VARIANCE_POS,
          MPI.FREEZE_DATE,
          MPI.TAG_NUMBER_INCREMENTS,
          (DECODE (
              MPI.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MPI.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MPI.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MPI.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MPI.LAST_ADJUSTMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_ADJUSTMENT_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_ADJUSTMENT_DATE_DAY,
          (DECODE (
              MPI.LAST_ADJUSTMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_ADJUSTMENT_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LAST_ADJUSTMENT_DATE_MONTH,
          (DECODE (
              MPI.LAST_ADJUSTMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_ADJUSTMENT_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LAST_ADJUSTMENT_DATE_QUARTER,
          (DECODE (
              MPI.LAST_ADJUSTMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_ADJUSTMENT_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_ADJUSTMENT_DATE_YEAR,
          (DECODE (
              MPI.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MPI.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MPI.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MPI.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MPI.PHYSICAL_INVENTORY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.PHYSICAL_INVENTORY_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             PHYSICAL_INV_DATE_DAY,
          (DECODE (
              MPI.PHYSICAL_INVENTORY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.PHYSICAL_INVENTORY_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             PHYSICAL_INV_DATE_MONTH,
          (DECODE (
              MPI.PHYSICAL_INVENTORY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.PHYSICAL_INVENTORY_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             PHYSICAL_INV_DATE_QUARTER,
          (DECODE (
              MPI.PHYSICAL_INVENTORY_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPI.PHYSICAL_INVENTORY_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             PHYSICAL_INV_DATE_YEAR,
          (DECODE (
              MPI.FREEZE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.FREEZE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             SNAPSHOT_DATE_DAY,
          (DECODE (
              MPI.FREEZE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.FREEZE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             SNAPSHOT_DATE_MONTH,
          (DECODE (
              MPI.FREEZE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.FREEZE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             SNAPSHOT_DATE_QUARTER,
          (DECODE (
              MPI.FREEZE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPI.FREEZE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             SNAPSHOT_DATE_YEAR,
          DECODE (MPI.APPROVAL_REQUIRED,
                  '1', 'Required for all adjustments',
                  '2', 'Not required for adjustments',
                  '3', 'Required for adjustments out of tolerance',
                  NULL),                                          /* Lookup */
          DECODE (MPI.ALL_SUBINVENTORIES_FLAG,
                  '1', 'Yes',
                  '2', 'No',
                  NULL),                                          /* Lookup */
          DECODE (MPI.DYNAMIC_TAG_ENTRY_FLAG,  '1', 'Yes',  '2', 'No',  NULL), /* Lookup */
          MPI.TOTAL_ADJUSTMENT_VALUE
     FROM MTL_PARAMETERS MP,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PHYSICAL_INVENTORIES MPI,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MP.ORGANIZATION_ID = MPI.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MPI.ORGANIZATION_ID
          AND OOD.ORGANIZATION_ID = MPI.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_PHY_IN_V FOR APPS.XX_BI_FI_PHY_IN_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_PHY_IN_V FOR APPS.XX_BI_FI_PHY_IN_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_PHY_IN_V FOR APPS.XX_BI_FI_PHY_IN_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_PHY_IN_V FOR APPS.XX_BI_FI_PHY_IN_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PHY_IN_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PHY_IN_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PHY_IN_V TO XXINTG;
