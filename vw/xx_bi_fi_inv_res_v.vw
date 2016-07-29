DROP VIEW APPS.XX_BI_FI_INV_RES_V;

/* Formatted on 6/6/2016 4:59:53 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_INV_RES_V
(
   ACCOUNT_ALIAS_ID,
   ACCOUNT_ID,
   CREATION_DATE,
   DEMAND_ID,
   DEMAND_SOURCE_HEADER_ID,
   DEMAND_SOURCE_NAME,
   DEMAND_SOURCE_TYPE_NAME,
   LAST_UPDATE_DATE,
   LINE_NUMBER,
   LOT_NUMBER,
   ORGANIZATION_CODE,
   ORGANIZATION_NAME,
   REQUIRED_DATE,
   REVISION,
   SALES_ORDER_ID,
   SUBINVENTORY_NAME,
   UNIT_OF_MEASURE,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   REQUIRED_DATE_DAY,
   REQUIRED_DATE_MONTH,
   REQUIRED_DATE_QUARTER,
   REQUIRED_DATE_YEAR,
   INVENTORY_ITEM_NAME,
   DEMAND_SRC_HDR_NAME,
   INVENTORY_LOCATION_NAME,
   PENDING_ISSUE_QUANTITY,
   ISSUED_QUANTITY,
   RESERVED_QUANTITY
)
AS
   SELECT TO_NUMBER (NULL) account_alias_id,
          TO_NUMBER (NULL) account_id,
          m.creation_date,
          m.demand_id,
          m.demand_source_header_id,
          DECODE (m.demand_source_type,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  m.demand_source_name)
             Demand_Source_Name,
          mts.transaction_source_type_name,
          m.last_update_date,
          m.user_line_num,
          m.lot_number,
          mp.organization_code,
          hou.NAME Organization_Name,
          m.requirement_date,
          m.revision,
          m.demand_source_header_id sales_order_id,
          m.subinventory,
          m.uom_code uom,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Last_Update_date_day,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Month,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Quarter,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Last_Update_date_Year,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Required_Date_Day,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Month,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Quarter,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Required_Date_Year,
          NULL Inventory_Item_Name,
          NULL Demand_Src_Hdr_Name,
          NULL Inventory_Location_Name,
          (  m.line_item_quantity
           - (  m.completed_quantity
              * (inv_convert.inv_um_convert (m.inventory_item_id,
                                             5,
                                             1,
                                             msi.primary_uom_code,
                                             m.uom_code,
                                             NULL,
                                             NULL))))
             pending_issue_quantity,
          (  m.completed_quantity
           * (inv_convert.inv_um_convert (m.inventory_item_id,
                                          5,
                                          1,
                                          msi.primary_uom_code,
                                          m.uom_code,
                                          NULL,
                                          NULL)))
             issued_quantity,
          m.line_item_quantity reserved_quantity
     FROM mtl_sales_orders mso,
          mtl_txn_source_types mts,
          hr_all_organization_units hou,
          mtl_parameters mp,
          mtl_system_items msi,
          mtl_item_locations mil,
          mtl_demand m,
          org_organization_definitions ood
    WHERE     m.organization_id = msi.organization_id
          AND m.inventory_item_id = msi.inventory_item_id
          AND mil.inventory_location_id(+) = m.locator_id
          AND mil.organization_id(+) = m.organization_id
          AND m.reservation_type = 2
          AND (m.primary_uom_quantity - m.completed_quantity) > 0
          AND m.demand_source_type = mts.transaction_source_type_id
          AND hou.organization_id = m.organization_id
          AND mp.organization_id = m.organization_id
          AND mso.sales_order_id = m.demand_source_header_id
          AND (m.demand_source_type IN (2, 8, 12))
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND m.organization_id = ood.organization_id
   UNION ALL                             /* Demand Source Type: 3 (Account) */
   SELECT TO_NUMBER (NULL) account_alias_id,
          TO_NUMBER (NULL) account_id,
          m.creation_date,
          m.demand_id,
          m.demand_source_header_id,
          DECODE (m.demand_source_type,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  m.demand_source_name)
             Demand_Source_Name,
          mts.transaction_source_type_name,
          m.last_update_date,
          m.user_line_num,
          m.lot_number,
          mp.organization_code,
          hou.NAME Organization_Name,
          m.requirement_date,
          m.revision,
          m.demand_source_header_id sales_order_id,
          m.subinventory,
          m.uom_code uom,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Last_Update_date_day,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Month,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Quarter,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Last_Update_date_Year,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Required_Date_Day,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Month,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Quarter,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Required_Date_Year,
          NULL Inventory_Item_Name,
          NULL Demand_Src_Hdr_Name,
          NULL Inventory_Location_Name,
          (  m.line_item_quantity
           - (  m.completed_quantity
              * (inv_convert.inv_um_convert (m.inventory_item_id,
                                             5,
                                             1,
                                             msi.primary_uom_code,
                                             m.uom_code,
                                             NULL,
                                             NULL))))
             pending_issue_quantity,
          (  m.completed_quantity
           * (inv_convert.inv_um_convert (m.inventory_item_id,
                                          5,
                                          1,
                                          msi.primary_uom_code,
                                          m.uom_code,
                                          NULL,
                                          NULL)))
             issued_quantity,
          m.line_item_quantity reserved_quantity
     FROM gl_code_combinations glc,
          mtl_txn_source_types mts,
          hr_all_organization_units hou,
          mtl_parameters mp,
          mtl_system_items msi,
          mtl_item_locations mil,
          mtl_demand m,
          org_organization_definitions ood
    WHERE     m.organization_id = msi.organization_id
          AND m.inventory_item_id = msi.inventory_item_id
          AND mil.inventory_location_id(+) = m.locator_id
          AND mil.organization_id(+) = m.organization_id
          AND m.reservation_type = 2
          AND (m.primary_uom_quantity - m.completed_quantity) > 0
          AND m.demand_source_type = mts.transaction_source_type_id
          AND hou.organization_id = m.organization_id
          AND mp.organization_id = m.organization_id
          AND glc.code_combination_id = m.demand_source_header_id
          AND m.demand_source_type = 3
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND m.organization_id = ood.organization_id
   UNION ALL                       /* Demand Source Type: 6 (Account Alias) */
   SELECT TO_NUMBER (NULL) account_alias_id,
          TO_NUMBER (NULL) account_id,
          m.creation_date,
          m.demand_id,
          m.demand_source_header_id,
          DECODE (m.demand_source_type,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  m.demand_source_name)
             Demand_Source_Name,
          mts.transaction_source_type_name,
          m.last_update_date,
          m.user_line_num,
          m.lot_number,
          mp.organization_code,
          hou.NAME Organization_Name,
          m.requirement_date,
          m.revision,
          m.demand_source_header_id sales_order_id,
          m.subinventory,
          m.uom_code uom,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Last_Update_date_day,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Month,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Quarter,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Last_Update_date_Year,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Required_Date_Day,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Month,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Quarter,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Required_Date_Year,
          NULL Inventory_Item_Name,
          NULL Demand_Src_Hdr_Name,
          NULL Inventory_Location_Name,
          (  m.line_item_quantity
           - (  m.completed_quantity
              * (inv_convert.inv_um_convert (m.inventory_item_id,
                                             5,
                                             1,
                                             msi.primary_uom_code,
                                             m.uom_code,
                                             NULL,
                                             NULL))))
             pending_issue_quantity,
          (  m.completed_quantity
           * (inv_convert.inv_um_convert (m.inventory_item_id,
                                          5,
                                          1,
                                          msi.primary_uom_code,
                                          m.uom_code,
                                          NULL,
                                          NULL)))
             issued_quantity,
          m.line_item_quantity reserved_quantity
     FROM mtl_generic_dispositions mgd,
          mtl_txn_source_types mts,
          hr_all_organization_units hou,
          mtl_parameters mp,
          mtl_system_items msi,
          mtl_item_locations mil,
          mtl_demand m,
          org_organization_definitions ood
    WHERE     m.organization_id = msi.organization_id
          AND m.inventory_item_id = msi.inventory_item_id
          AND mil.inventory_location_id(+) = m.locator_id
          AND mil.organization_id(+) = m.organization_id
          AND m.reservation_type = 2
          AND (m.primary_uom_quantity - m.completed_quantity) > 0
          AND m.demand_source_type = mts.transaction_source_type_id
          AND hou.organization_id = m.organization_id
          AND mp.organization_id = m.organization_id
          AND mgd.disposition_id = m.demand_source_header_id
          AND mgd.organization_id = m.organization_id
          AND m.demand_source_type = 6
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND m.organization_id = ood.organization_id
   UNION ALL       /* Demand Source Type: 13, >99 (Inventory, User Defined) */
   SELECT TO_NUMBER (NULL) account_alias_id,
          TO_NUMBER (NULL) account_id,
          m.creation_date,
          m.demand_id,
          m.demand_source_header_id,
          DECODE (m.demand_source_type,
                  2, NULL,
                  3, NULL,
                  6, NULL,
                  8, NULL,
                  12, NULL,
                  m.demand_source_name)
             Demand_Source_Name,
          mts.transaction_source_type_name,
          m.last_update_date,
          m.user_line_num,
          m.lot_number,
          mp.organization_code,
          hou.NAME Organization_Name,
          m.requirement_date,
          m.revision,
          m.demand_source_header_id sales_order_id,
          m.subinventory,
          m.uom_code uom,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Creation_Date_Day,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Month,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Creation_Date_Quarter,
          (DECODE (
              M.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.CREATION_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Creation_Date_Year,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Last_Update_date_day,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Month,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Last_Update_date_Quarter,
          (DECODE (
              M.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.LAST_UPDATE_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Last_Update_date_Year,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'DD'), 'DD') || '190001',
                 'DDYYYYMM')))
             AS Required_Date_Day,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'MM'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Month,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'Q'), 'MM') || '1900',
                 'MMYYYY')))
             AS Required_Date_Quarter,
          (DECODE (
              M.REQUIREMENT_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (M.REQUIREMENT_DATE, 'YYYY'), 'YYYY') || '01',
                 'YYYYMM')))
             AS Required_Date_Year,
          NULL Inventory_Item_Name,
          NULL Demand_Src_Hdr_Name,
          NULL Inventory_Location_Name,
          (  m.line_item_quantity
           - (  m.completed_quantity
              * (inv_convert.inv_um_convert (m.inventory_item_id,
                                             5,
                                             1,
                                             msi.primary_uom_code,
                                             m.uom_code,
                                             NULL,
                                             NULL))))
             pending_issue_quantity,
          (  m.completed_quantity
           * (inv_convert.inv_um_convert (m.inventory_item_id,
                                          5,
                                          1,
                                          msi.primary_uom_code,
                                          m.uom_code,
                                          NULL,
                                          NULL)))
             issued_quantity,
          m.line_item_quantity reserved_quantity
     FROM mtl_txn_source_types mts,
          hr_all_organization_units hou,
          mtl_parameters mp,
          mtl_system_items msi,
          mtl_item_locations mil,
          mtl_demand m,
          org_organization_definitions ood
    WHERE     m.organization_id = msi.organization_id
          AND m.inventory_item_id = msi.inventory_item_id
          AND mil.inventory_location_id(+) = m.locator_id
          AND mil.organization_id(+) = m.organization_id
          AND m.reservation_type = 2
          AND (m.primary_uom_quantity - m.completed_quantity) > 0
          AND m.demand_source_type = mts.transaction_source_type_id
          AND hou.organization_id = m.organization_id
          AND mp.organization_id = m.organization_id
          AND (m.demand_source_type = 13 OR m.demand_source_type > 99)
          AND hr_security.show_bis_record (ood.operating_unit) = 'TRUE'
          AND m.organization_id = ood.organization_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_INV_RES_V FOR APPS.XX_BI_FI_INV_RES_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_INV_RES_V FOR APPS.XX_BI_FI_INV_RES_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_INV_RES_V FOR APPS.XX_BI_FI_INV_RES_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_INV_RES_V FOR APPS.XX_BI_FI_INV_RES_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_RES_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_RES_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_INV_RES_V TO XXINTG;
