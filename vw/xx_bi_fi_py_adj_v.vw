DROP VIEW APPS.XX_BI_FI_PY_ADJ_V;

/* Formatted on 6/6/2016 4:59:41 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_PY_ADJ_V
(
   ADJUSTMENT_ID,
   APPROVED_BY_EMPLOYEE_NAME,
   CREATION_DATE,
   INVENTORY_LOCATOR_ID,
   LAST_UPDATE_DATE,
   LOT_EXPIRATION_DATE,
   LOT_NUMBER,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   PHYSICAL_INVENTORY_NAME,
   REVISION,
   SERIAL_NUMBER,
   SUBINVENTORY_NAME,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   LOT_EXPIRATION_DATE_DAY,
   LOT_EXPIRATION_DATE_MONTH,
   LOT_EXPIRATION_DATE_QUARTER,
   LOT_EXPIRATION_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   INVENTORY_LOCATION_NAME,
   APPROVAL_STATUS,
   ADJUSTMENT_ACC_NO,
   COST_PER_UNIT,
   ADJUSTMENT_QUANTITY,
   COUNT_QUANTITY,
   SYSTEM_QUANTITY
)
AS
   SELECT MPA.ADJUSTMENT_ID,
          NULL APPROVED_BY_EMPLOYEE_NAME,
          MPA.CREATION_DATE,
          MPA.LOCATOR_ID,
          MPA.LAST_UPDATE_DATE,
          MPA.LOT_EXPIRATION_DATE,
          MPA.LOT_NUMBER,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MPI.PHYSICAL_INVENTORY_NAME,
          MPA.REVISION,
          MPA.SERIAL_NUMBER,
          MPA.SUBINVENTORY_NAME,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LOT_EXPIRATION_DATE_DAY,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_MONTH,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_QUARTER,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LOT_EXPIRATION_DATE_YEAR,
          NULL,                                                 /* KEY FLEX */
          NULL,
          DECODE (MPA.APPROVAL_STATUS,
                  '1', 'Approved',
                  '2', 'Rejected',
                  '3', 'Posted',
                  NULL),                                          /* LOOKUP */
          MPA.GL_ADJUST_ACCOUNT,
          MPA.ACTUAL_COST,
          MPA.ADJUSTMENT_QUANTITY,
          MPA.COUNT_QUANTITY,
          MPA.SYSTEM_QUANTITY
     FROM GL_CODE_COMBINATIONS GLC,
          MTL_ITEM_LOCATIONS MIL,
          MTL_SYSTEM_ITEMS MSI,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_PHYSICAL_INVENTORIES MPI,
          MTL_PHYSICAL_ADJUSTMENTS MPA,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MP.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = MPA.INVENTORY_ITEM_ID
          AND MSI.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND GLC.CODE_COMBINATION_ID(+) = MPA.GL_ADJUST_ACCOUNT
          AND MPI.PHYSICAL_INVENTORY_ID = MPA.PHYSICAL_INVENTORY_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MPA.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = MPA.ORGANIZATION_ID
          AND MPA.APPROVED_BY_EMPLOYEE_ID IS NULL
          AND OOD.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE' /*-- -- Get the Employee name if EMPLOYEE_ID IS NOT NULL*/
   UNION ALL
   SELECT MPA.ADJUSTMENT_ID,
          MEV.FULL_NAME APPROVED_BY_EMPLOYEE_NAME,
          MPA.CREATION_DATE,
          MPA.LOCATOR_ID,
          MPA.LAST_UPDATE_DATE,
          MPA.LOT_EXPIRATION_DATE,
          MPA.LOT_NUMBER,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MPI.PHYSICAL_INVENTORY_NAME,
          MPA.REVISION,
          MPA.SERIAL_NUMBER,
          MPA.SUBINVENTORY_NAME,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MPA.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MPA.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LOT_EXPIRATION_DATE_DAY,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_MONTH,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_QUARTER,
          (DECODE (
              MPA.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPA.LOT_EXPIRATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LOT_EXPIRATION_DATE_YEAR,
          NULL,                                                 /* KEY FLEX */
          NULL,
          DECODE (MPA.APPROVAL_STATUS,
                  '1', 'Approved',
                  '2', 'Rejected',
                  '3', 'Posted',
                  NULL),                                          /* LOOKUP */
          MPA.GL_ADJUST_ACCOUNT,
          MPA.ACTUAL_COST,
          MPA.ADJUSTMENT_QUANTITY,
          MPA.COUNT_QUANTITY,
          MPA.SYSTEM_QUANTITY
     FROM MTL_EMPLOYEES_VIEW MEV,
          MTL_ITEM_LOCATIONS MIL,
          GL_CODE_COMBINATIONS GLC,
          MTL_SYSTEM_ITEMS MSI,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_PHYSICAL_INVENTORIES MPI,
          MTL_PHYSICAL_ADJUSTMENTS MPA,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MP.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID = MPA.INVENTORY_ITEM_ID
          AND MSI.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND GLC.CODE_COMBINATION_ID(+) = MPA.GL_ADJUST_ACCOUNT
          AND MPI.PHYSICAL_INVENTORY_ID = MPA.PHYSICAL_INVENTORY_ID
          AND MEV.EMPLOYEE_ID = MPA.APPROVED_BY_EMPLOYEE_ID
          AND MEV.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MPA.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = MPA.ORGANIZATION_ID
          AND MPA.APPROVED_BY_EMPLOYEE_ID IS NOT NULL
          AND OOD.ORGANIZATION_ID = MPA.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_PY_ADJ_V FOR APPS.XX_BI_FI_PY_ADJ_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_PY_ADJ_V FOR APPS.XX_BI_FI_PY_ADJ_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_PY_ADJ_V FOR APPS.XX_BI_FI_PY_ADJ_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_PY_ADJ_V FOR APPS.XX_BI_FI_PY_ADJ_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_ADJ_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_ADJ_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_ADJ_V TO XXINTG;
