DROP VIEW APPS.XX_BI_O2C_INVOICE_V;

/* Formatted on 6/6/2016 4:59:27 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_O2C_INVOICE_V
(
   OPERATING_UNIT,
   INVOICE_TYPE,
   INVOICE_#,
   SALESPERSON,
   CUSTOMER_NAME,
   STATE_PROVINCE,
   YEAR,
   MONTH,
   TRANSACTION_DATE,
   ITEM_CODE,
   ITEM_DESCRIPTION,
   QUANTITY,
   CURRENCY_CODE,
   PRICE,
   TOTAL,
   CATEGORY_NAME,
   "Category Name",
   DIVISION,
   PRODUCT_SEGMENT,
   BRAND,
   PRODUCT_CLASS,
   PRODUCT_CLASS_DESCRIPTION,
   PRODUCT_TYPE,
   PRODUCT_TYPE_DESCRIPTION,
   TERRITORY_NAME,
   ORDER_NUMBER,
   ORDER_TYPE,
   BILL_TO_CUSTOMER,
   INVOICE_DATE
)
AS
     SELECT hou.NAME "OPERATING_UNIT",
            rctt.TYPE "INVOICE_TYPE",
            rct.trx_number "INVOICE_#",
            jrds.source_name "SALESPERSON",
            hp.party_name "CUSTOMER_NAME",
            DECODE (hp.state, NULL, hp.province, hp.state) "STATE_PROVINCE",
            TO_CHAR (rct.trx_date, 'YYYY') "YEAR",
            TO_CHAR (rct.trx_date, 'MONTH') "MONTH",
            rct.trx_date "TRANSACTION_DATE",
            msi.segment1 "ITEM_CODE",
            msi.description "ITEM_DESCRIPTION",
            DECODE (rctl.quantity_invoiced,
                    NULL, quantity_credited,
                    rctl.quantity_invoiced)
               "QUANTITY",
            rct.invoice_currency_code "CURRENCY_CODE",
            -- to_char(rctl.unit_selling_price,99999999.99) "PRICE",
            -- to_char(rctl.revenue_amount,99999999.99) "TOTAL",
            ROUND (rctl.unit_selling_price, 2) "PRICE",
            ROUND (rctl.revenue_amount, 2) "TOTAL",
            msi.item_type "CATEGORY_NAME",
            --  mcb.segment1 category_name,
            mcst.category_set_name "Category Name",
            mcb.segment4 "DIVISION",
            mcb.segment10 "PRODUCT_SEGMENT",
            --mcb.segment6 Future,
            mcb.segment7 "BRAND",
            mcb.segment8 "PRODUCT_CLASS",
            vl1.description "PRODUCT_CLASS_DESCRIPTION",
            mcb.segment9 "PRODUCT_TYPE",
            vl.description "PRODUCT_TYPE_DESCRIPTION",
            rctls.attribute1 "TERRITORY_NAME",
            rctl.sales_order "ORDER_NUMBER",
            ott.NAME "ORDER_TYPE",
            hp_bill.party_name "BILL_TO_CUSTOMER",
            rct.trx_date "INVOICE_DATE"
       FROM apps.hr_operating_units hou,
            apps.ra_customer_trx_all rct,
            apps.ra_cust_trx_types_all rctt,
            apps.ra_customer_trx_lines_all rctl,
            apps.ra_cust_trx_line_salesreps_all rctls,
            apps.jtf_rs_salesreps jrs,
            apps.jtf_rs_defresources_v jrds,
            apps.mtl_parameters_all_v org,
            apps.mtl_system_items msi,
            apps.hz_cust_accounts_all hca,
            apps.hz_parties hp,
            apps.hz_cust_accounts_all hca_bill,
            apps.hz_parties hp_bill,
            apps.mtl_item_categories mic,
            apps.mtl_category_sets mcst,
            apps.mtl_categories_b mcb,
            apps.fnd_flex_value_sets vs,
            apps.fnd_flex_values_vl vl,
            apps.fnd_flex_value_sets vs1,
            apps.fnd_flex_values_vl vl1,
            apps.oe_order_headers_all ooha,
            apps.oe_transaction_types_tl ott
      WHERE     1 = 1
            --AND upper(hou.name) = 'OU CANADA'
            --AND upper(hou.name) = 'OU AUSTRALIA'
            --AND upper(hou.name) = 'OU NEW ZEALAND'
            AND rct.org_id = hou.organization_id
            --AND rct.trx_date between '01-MAR-15' and '31-MAR-15'
            AND rctt.org_id = rct.org_id
            AND rctt.cust_trx_type_id = rct.cust_trx_type_id
            AND rctl.org_id = rct.org_id
            AND rctl.customer_trx_id = rct.customer_trx_id
            AND org.organization_code = 'MST'
            AND msi.organization_id = org.organization_id
            --AND msi.organization_id = 83
            AND msi.inventory_item_id = rctl.inventory_item_id
            AND hca.cust_account_id = rct.sold_to_customer_id
            AND hp.party_id = hca.party_id
            AND hca_bill.cust_account_id = rct.bill_to_customer_id
            AND hp_bill.party_id = hca_bill.party_id
            AND rctls.org_id = rctl.org_id
            AND rctls.customer_trx_line_id = rctl.customer_trx_line_id
            AND jrs.org_id = rctls.org_id
            AND jrs.salesrep_id = rctls.salesrep_id
            AND jrds.resource_id = jrs.resource_id
            AND mic.inventory_item_id = msi.inventory_item_id
            AND mic.organization_id = msi.organization_id
            AND mcst.category_set_id = mic.category_set_id
            AND mcb.category_id = mic.category_id
            AND mcst.structure_id = mcb.structure_id
            AND mcst.category_set_name = 'Sales and Marketing'
            AND vs.flex_value_set_name = 'INTG_PRODUCT_TYPE'
            AND vl.flex_value_set_id = vs.flex_value_set_id
            AND vl.flex_value = mcb.segment9                     --MC.segment9
            AND vl.parent_flex_value_low = mcb.segment4
            AND vs1.flex_value_set_name = 'INTG_PRODUCT_CLASS'
            AND vl1.flex_value_set_id = vs1.flex_value_set_id
            AND vl1.flex_value = mcb.segment8
            AND ooha.org_id = rctl.org_id
            AND TO_CHAR (ooha.order_number) = rctl.sales_order
            AND ott.transaction_type_id = ooha.order_type_id
            AND ott.LANGUAGE = 'US'
   ORDER BY rct.trx_number, rctl.line_number;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_O2C_INVOICE_V FOR APPS.XX_BI_O2C_INVOICE_V;
