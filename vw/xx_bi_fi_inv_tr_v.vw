DROP VIEW APPS.XX_BI_FI_INV_TR_V;

/* Formatted on 6/6/2016 4:59:51 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_INV_TR_V
(
   ACCT_PERIOD_NAME,
   ACCT_PERIOD_SET_NAME,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   ACCOUNTING_PERIOD_SET,
   ORGANIZATION_ID,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   BOP_INTRANSIT,
   BOP_WIP,
   BOP_ONHAND,
   INVENTORY_ITEM_ID,
   COST_OF_GOODS_SOLD,
   INTRANSIT,
   WIP,
   ONHAND,
   ACCT_PERIOD_NUMBER,
   ACCT_PERIOD_YEAR
)
AS
   SELECT oap.period_name AS acct_period_name,
          oap.period_set_name AS acct_period_set_name,
          mbi.creation_date,
          mbi.last_update_date,
          mp.organization_code,
          hou.NAME Organization_Name,
          (oap.period_set_name || '+' || oap.period_name)
             AS Accounting_Period_Set,
          (TO_CHAR (mbi.organization_id)) Orgnization_Id,
          (DECODE (
              mbi.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              mbi.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              mbi.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              mbi.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              mbi.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mbi.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             AS Last_Update_Date_Day,
          (DECODE (
              mbi.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_update_date_Month,
          (DECODE (
              mbi.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (mbi.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_update_date_Quarter,
          (DECODE (
              mbi.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (mbi.LAST_UPDATE_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             AS Last_update_date_Year,
          NULL AS Inventory_Item_Name,
          mbi.bop_intransit,
          mbi.bop_wip,
          mbi.bop_onhand,
          mbi.inventory_item_id,
          mbi.cogs,
          mbi.intransit,
          mbi.wip,
          mbi.onhand,
          oap.period_num AS Acct_Period_Number,
          oap.period_year AS Acct_Period_Year
     FROM mtl_bis_inv_by_period mbi,
          mtl_system_items msi,
          org_acct_periods oap,
          mtl_parameters mp,
          hr_all_organization_units hou,
          org_organization_definitions ood
    WHERE     msi.inventory_item_id = mbi.inventory_item_id
          AND msi.organization_id = mbi.organization_id
          AND oap.acct_period_id = mbi.acct_period_id
          AND mp.organization_id = mbi.organization_id
          AND hou.organization_id = mbi.organization_id
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND mbi.organization_id = ood.ORGANIZATION_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_INV_TR_V FOR APPS.XX_BI_FI_INV_TR_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_INV_TR_V FOR APPS.XX_BI_FI_INV_TR_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_INV_TR_V FOR APPS.XX_BI_FI_INV_TR_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_INV_TR_V FOR APPS.XX_BI_FI_INV_TR_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_TR_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_TR_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_TR_V TO XXINTG;
