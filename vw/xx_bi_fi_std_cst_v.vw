DROP VIEW APPS.XX_BI_FI_STD_CST_V;

/* Formatted on 6/6/2016 4:59:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_STD_CST_V
(
   CATEGORY_SET_NAME,
   ITEM_NUMBER,
   COST_TYPE_NAME,
   UPDATE_DATE,
   DESCRIPTION,
   LOT#,
   EXPIRATION_DATE,
   CREATION_DATE,
   ITEM_RANGE_HIGH,
   ITEM_RANGE_LOW,
   LAST_UPDATE_DATE,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   UPDATE_DATE_DAY,
   UPDATE_DATE_MONTH,
   UPDATE_DATE_QUARTER,
   UPDATE_DATE_YEAR,
   STATUS,
   RANGE_OPTION,
   UPDT_RESOURCE_OVHD_FLAG,
   UPDATE_ACTIVITY_FLAG,
   SNAPSHOT_SAVED_FLAG,
   CATEGORY_NAME,
   INV_ADJ_ACCOUNT,
   SCRAP_ADJUSTMENT_VALUE,
   WIP_ADJUSTMENT_VALUE,
   INTRANSIT_ADJUSTMENT_VALUE,
   INVENTORY_ADJUSTMENT_VALUE,
   SINGLE_ITEM,
   UNIT_COST
)
AS
   SELECT MCS.CATEGORY_SET_NAME,
          MSI.SEGMENT1,
          CCT.COST_TYPE,
          CO.UPDATE_DATE,
          CO.DESCRIPTION,
          MLN.LOT_NUMBER,
          MLN.EXPIRATION_DATE,
          CO.CREATION_DATE,
          CO.ITEM_RANGE_HIGH,
          CO.ITEM_RANGE_LOW,
          CO.LAST_UPDATE_DATE,
          PA.ORGANIZATION_CODE,
          HAOU.NAME,
          (DECODE (
              CO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              CO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              CO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              CO.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              CO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CO.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              CO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              CO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              CO.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CO.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          (DECODE (
              CO.UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             UPDATE_DATE_DAY,
          (DECODE (
              CO.UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             UPDATE_DATE_MONTH,
          (DECODE (
              CO.UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (TO_CHAR (TRUNC (CO.UPDATE_DATE, 'Q'), 'MM') || '1900',
                       'MMYYYY')))
             UPDATE_DATE_QUARTER,
          (DECODE (
              CO.UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (CO.UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             UPDATE_DATE_YEAR,
          DECODE (co.status,
                  '-1', 'Error',
                  '1', 'Pending',
                  '2', 'Running',
                  '3', 'Completed',
                  NULL),
          DECODE (co.range_option,
                  '1', 'All items',
                  '2', 'Specific item',
                  '3', 'Range of items',
                  '4', 'Zero cost items',
                  '5', 'Category',
                  '6', 'Based on rollup items',
                  '7', 'Not based on rollup items',
                  NULL),
          DECODE (co.update_resource_ovhd_flag,
                  '1', 'Yes',
                  '2', 'No',
                  NULL),
          DECODE (co.update_activity_flag,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (co.snapshot_saved_flag,  '1', 'Yes',  '2', 'No',  NULL),
          DECODE (
             mc.STRUCTURE_ID,
             201, mc.SEGMENT1,
             50136, mc.SEGMENT1 || '.' || mc.SEGMENT2 || '.' || mc.SEGMENT3,
             50152, mc.SEGMENT1,
             50153, mc.SEGMENT1,
             50168, mc.SEGMENT1 || '.' || mc.SEGMENT2,
             50169, mc.SEGMENT1,
             50190, mc.SEGMENT1 || '.' || mc.SEGMENT2 || '.' || mc.SEGMENT3,
             50208, mc.SEGMENT1,
             NULL),
          NULL,                                                       /* ID */
          /* WHO */
          CO.SCRAP_ADJUSTMENT_VALUE,    /* RESOLVED FOREIGN KEY RESOLUTIONS */
          CO.WIP_ADJUSTMENT_VALUE,
          CO.INTRANSIT_ADJUSTMENT_VALUE,
          CO.INVENTORY_ADJUSTMENT_VALUE,
          CO.SINGLE_ITEM,
          CSC.STANDARD_COST
     FROM MTL_SYSTEM_ITEMS MSI,
          apps.MTL_CATEGORY_SETS MCS,
          apps.MTL_CATEGORIES MC,
          MTL_LOT_NUMBERS MLN,
          GL_CODE_COMBINATIONS GCC,
          CST_COST_TYPES CCT,
          HR_ALL_ORGANIZATION_UNITS HAOU,
          MTL_PARAMETERS PA,
          CST_COST_UPDATES CO,
          CST_STANDARD_COSTS CSC
    WHERE     CO.ORGANIZATION_ID = PA.ORGANIZATION_ID
          AND CO.ORGANIZATION_ID = HAOU.ORGANIZATION_ID
          AND CO.COST_TYPE_ID = CCT.COST_TYPE_ID
          AND CO.INV_ADJUSTMENT_ACCOUNT = GCC.CODE_COMBINATION_ID(+)
          AND CO.CATEGORY_ID = MC.CATEGORY_ID(+)
          AND CO.CATEGORY_SET_ID = MCS.CATEGORY_SET_ID(+)
          AND CO.SINGLE_ITEM = MSI.INVENTORY_ITEM_ID(+)
          AND CO.ORGANIZATION_ID = MSI.ORGANIZATION_ID(+)
          AND MSI.ORGANIZATION_ID = MLN.ORGANIZATION_ID(+)
          AND MSI.INVENTORY_ITEM_ID = MLN.INVENTORY_ITEM_ID(+)
          AND CO.COST_UPDATE_ID(+) = CSC.COST_UPDATE_ID
          AND CO.ORGANIZATION_ID(+) = CSC.ORGANIZATION_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_STD_CST_V FOR APPS.XX_BI_FI_STD_CST_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_STD_CST_V FOR APPS.XX_BI_FI_STD_CST_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_STD_CST_V FOR APPS.XX_BI_FI_STD_CST_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_STD_CST_V FOR APPS.XX_BI_FI_STD_CST_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_CST_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_CST_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_STD_CST_V TO XXINTG;
