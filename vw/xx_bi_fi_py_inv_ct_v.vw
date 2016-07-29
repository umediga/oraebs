DROP VIEW APPS.XX_BI_FI_PY_INV_CT_V;

/* Formatted on 6/6/2016 4:59:40 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_PY_INV_CT_V
(
   ADJUSTMENT_ID,
   COUNTED_BY_EMPLOYEE_NAME,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   LOT_EXPIRATION_DATE,
   LOT_NUMBER,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   PHYSICAL_INVENTORY_NAME,
   REVISION,
   SERIAL_NUMBER,
   STANDARD_UOM_CODE,
   SUBINVENTORY_NAME,
   TAG_NUMBER,
   TAG_UOM_CODE,
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
   VOID_FLAG,
   INVENTORY_ITEM_NAME,
   INVENTORY_LOCATION_NAME,
   TAG_QUANTITY_AT_STANDARD_UOM,
   TAG_QUANTITY
)
AS
   SELECT MPT.ADJUSTMENT_ID,
          NULL COUNTED_BY_EMPLOYEE_NAME,
          MPT.CREATION_DATE,
          MPT.LAST_UPDATE_DATE,
          MPT.LOT_EXPIRATION_DATE,
          MPT.LOT_NUMBER,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MPI.PHYSICAL_INVENTORY_NAME,
          MPT.REVISION,
          MPT.SERIAL_NUM,
          MPT.STANDARD_UOM,
          MPT.SUBINVENTORY,
          MPT.TAG_NUMBER,
          MPT.TAG_UOM,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LOT_EXPIRATION_DATE_DAY,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_MONTH,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_QUARTER,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LOT_EXPIRATION_DATE_YEAR,
          DECODE (MPT.VOID_FLAG,  '1', 'Void',  '2', 'Active',  NULL),
          NULL INVENTORY_ITEM_NAME,
          NULL INVENTORY_LOCATION_NAME,
          MPT.TAG_QUANTITY_AT_STANDARD_UOM,
          MPT.TAG_QUANTITY
     FROM MTL_ITEM_LOCATIONS MIL,
          MTL_SYSTEM_ITEMS MSI,
          MTL_PHYSICAL_INVENTORIES MPI,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_PHYSICAL_INVENTORY_TAGS MPT,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MSI.INVENTORY_ITEM_ID(+) = MPT.INVENTORY_ITEM_ID
          AND MSI.ORGANIZATION_ID(+) = MPT.ORGANIZATION_ID
          AND MPI.PHYSICAL_INVENTORY_ID = MPT.PHYSICAL_INVENTORY_ID
          AND MP.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MPT.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = MPT.ORGANIZATION_ID
          AND MPT.COUNTED_BY_EMPLOYEE_ID IS NULL
          AND OOD.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE' /* ** GET the employee name if employee id is not null */
   UNION ALL
   SELECT MPT.ADJUSTMENT_ID,
          MEV.FULL_NAME COUNTED_BY_EMPLOYEE_NAME,
          MPT.CREATION_DATE,
          MPT.LAST_UPDATE_DATE,
          MPT.LOT_EXPIRATION_DATE,
          MPT.LOT_NUMBER,
          MP.ORGANIZATION_CODE,
          HOU.NAME,
          MPI.PHYSICAL_INVENTORY_NAME,
          MPT.REVISION,
          MPT.SERIAL_NUM,
          MPT.STANDARD_UOM,
          MPT.SUBINVENTORY,
          MPT.TAG_NUMBER,
          MPT.TAG_UOM,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              MPT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              MPT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LOT_EXPIRATION_DATE_DAY,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_MONTH,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LOT_EXPIRATION_DATE_QUARTER,
          (DECODE (
              MPT.LOT_EXPIRATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (MPT.LOT_EXPIRATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LOT_EXPIRATION_DATE_YEAR,
          DECODE (MPT.VOID_FLAG,  '1', 'Void',  '2', 'Active',  NULL),
          NULL INVENTORY_ITEM_NAME,
          NULL INVENTORY_LOCATION_NAME,
          MPT.TAG_QUANTITY_AT_STANDARD_UOM,
          MPT.TAG_QUANTITY
     FROM MTL_EMPLOYEES_VIEW MEV,
          MTL_ITEM_LOCATIONS MIL,
          MTL_SYSTEM_ITEMS MSI,
          MTL_PHYSICAL_INVENTORIES MPI,
          HR_ALL_ORGANIZATION_UNITS HOU,
          MTL_PARAMETERS MP,
          MTL_PHYSICAL_INVENTORY_TAGS MPT,
          ORG_ORGANIZATION_DEFINITIONS OOD
    WHERE     MEV.EMPLOYEE_ID = MPT.COUNTED_BY_EMPLOYEE_ID
          AND MEV.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND MSI.INVENTORY_ITEM_ID(+) = MPT.INVENTORY_ITEM_ID
          AND MSI.ORGANIZATION_ID(+) = MPT.ORGANIZATION_ID
          AND MPI.PHYSICAL_INVENTORY_ID = MPT.PHYSICAL_INVENTORY_ID
          AND MP.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND HOU.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND MIL.INVENTORY_LOCATION_ID(+) = MPT.LOCATOR_ID
          AND MIL.ORGANIZATION_ID(+) = MPT.ORGANIZATION_ID
          AND MPT.COUNTED_BY_EMPLOYEE_ID IS NOT NULL
          AND OOD.ORGANIZATION_ID = MPT.ORGANIZATION_ID
          AND HR_SECURITY.SHOW_BIS_RECORD (OOD.OPERATING_UNIT) = 'TRUE';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_PY_INV_CT_V FOR APPS.XX_BI_FI_PY_INV_CT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_PY_INV_CT_V FOR APPS.XX_BI_FI_PY_INV_CT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_PY_INV_CT_V FOR APPS.XX_BI_FI_PY_INV_CT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_PY_INV_CT_V FOR APPS.XX_BI_FI_PY_INV_CT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_INV_CT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_INV_CT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_PY_INV_CT_V TO XXINTG;
