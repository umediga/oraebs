DROP VIEW APPS.XX_BI_SALES_ACT_SHIP_V;

/* Formatted on 6/6/2016 4:59:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_ACT_SHIP_V
(
   DEALER_CODE,
   RELATION,
   RSM_CODE,
   CUSTOMER_NUMBER,
   CUSTOMER_NAME,
   SHIP_TO_SITE_NUMBER,
   BILL_TO_SITE_NUMBER,
   ADDRESS_1,
   ADDRESS_2,
   CITY,
   STATE,
   ZIP,
   TERRITORY,
   REGION,
   SHIP_TO_COUNTRY,
   BILL_CUSTOMER_NUMBER,
   BILL_CUST_NAME,
   CUSTOMER_CATEGORY,
   LOCATION_NUMBER,
   ORDER_NO,
   INVOICE_DATE,
   INVOICE_NUM,
   INVOICE_LINE,
   ITEM_NO,
   ITEM_DESC,
   DCODE,
   DCODE_DESC,
   UNIT_SELLING_PRICE,
   QUANTITY_INVOICED,
   QUANTITY_CREDITED,
   EXTENDED_AMT,
   NET_QTY,
   INVOICE_MONTH,
   DIVISION,
   OPERATING_UNIT,
   ORG_CODE
)
AS
   SELECT NULL "Dealer Code",
          NULL "Relation",
          NULL "Rsm Code",
          hca.account_number customer_number,
          hp.party_name,
          hps.party_site_number ship_to_site_number,
          hps1.party_site_number bill_to_site_number,
          hl.address1,
          hl.address2,
          hl.city,
          hl.state,
          hl.postal_code,
          (SELECT osc.attribute1
             FROM oe_sales_credits osc
            WHERE ooh.header_id = osc.header_id AND ROWNUM = 1)
             territory,
          hla.region_1 region,
          hl.country ship_to_country,
          hca1.account_number bill_customer_number,
          hp1.party_name bill_cust_name,
          hca.customer_class_code,
          hcs.LOCATION location_number,
          ooh.order_number,
          rcta.trx_date invoice_date,
          rcta.trx_number,
          rctl.line_number,
          msib.segment1,
          msib.description,
          mcb.segment9 "DCODE",
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  fnd_flex_values_tl c
            WHERE     a.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id
                  AND ROWNUM = 1)
             "DCODE DESCRIPTION",
          rctl.unit_selling_price "Unit Selling price",
          rctl.quantity_invoiced,
          rctl.quantity_credited,
          rctl.extended_amount "Extended Amt",
          (NVL (rctl.quantity_invoiced, 0) + NVL (rctl.quantity_credited, 0))
             "Net_Quantity",
          TRUNC (TO_DATE (rcta.trx_date), 'MM') "INVOICE MONTH",
          (SELECT mcb.segment4
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.LANGUAGE = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = msib.inventory_item_id
                  AND mic.organization_id = msib.organization_id)
             "DIVISION",
          ooh.org_id,
          ood.organization_code
     FROM ra_customer_trx_all rcta,
          hz_parties hp,
          hz_cust_accounts hca,
          hz_parties hp1,
          hz_cust_accounts hca1,
          hz_cust_site_uses_all hcs,
          hz_cust_site_uses_all hcs1,
          hz_cust_acct_sites_all hcas,
          hz_cust_acct_sites_all hcas1,
          hz_locations hl,
          hz_locations hl1,
          hz_party_sites hps,
          hz_party_sites hps1,
          oe_order_headers_all ooh,
          oe_order_lines_all ool,
          ra_customer_trx_lines_all rctl,
          mtl_system_items_b msib,
          mtl_item_categories mic,
          mtl_category_sets_tl mcst,
          mtl_category_sets_b mcsb,
          mtl_categories_b mcb,
          hr_locations_all hla,
          hr_all_organization_units hou,
          org_organization_definitions ood,
          hr_operating_units hopu
    WHERE     rcta.ship_to_customer_id = hca.cust_account_id
          AND hca.party_id = hp.party_id
          AND rcta.ship_to_site_use_id = hcs.site_use_id
          AND hcs.site_use_code = 'SHIP_TO'
          AND rcta.bill_to_customer_id = hca1.cust_account_id
          AND hca1.party_id = hp1.party_id
          AND rcta.bill_to_site_use_id = hcs1.site_use_id
          AND hcs1.site_use_code = 'BILL_TO'
          AND hcs.cust_acct_site_id = hcas.cust_acct_site_id
          AND hps.location_id = hl.location_id
          AND hps1.location_id = hl1.location_id
          AND hcas.party_site_id = hps.party_site_id
          AND hcs1.cust_acct_site_id = hcas1.cust_acct_site_id
          AND hcas1.party_site_id = hps1.party_site_id
          AND ool.invoice_to_org_id(+) = hcs1.bill_to_site_use_id
          AND rcta.interface_header_attribute1 = TO_CHAR (ooh.order_number)
          AND rctl.customer_trx_id = rcta.customer_trx_id
          AND rctl.org_id = rcta.org_id
          AND rctl.inventory_item_id = msib.inventory_item_id
          AND rctl.warehouse_id = msib.organization_id
          AND rcta.org_id = ooh.org_id
          AND mcst.category_set_id = mcsb.category_set_id
          AND mcst.LANGUAGE = USERENV ('LANG')
          AND mic.category_set_id = mcsb.category_set_id
          AND mic.category_id = mcb.category_id
          AND mcst.category_set_name = 'Sales and Marketing'
          AND mic.inventory_item_id = msib.inventory_item_id
          AND mic.organization_id = msib.organization_id
          AND hou.location_id(+) = hla.location_id
          AND hopu.organization_id = ooh.org_id
          AND msib.organization_id = ood.organization_id
          AND hou.organization_id = ood.operating_unit
          AND hopu.organization_id = rcta.org_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_ACT_SHIP_V FOR APPS.XX_BI_SALES_ACT_SHIP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_ACT_SHIP_V FOR APPS.XX_BI_SALES_ACT_SHIP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_ACT_SHIP_V FOR APPS.XX_BI_SALES_ACT_SHIP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_ACT_SHIP_V FOR APPS.XX_BI_SALES_ACT_SHIP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ACT_SHIP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ACT_SHIP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_ACT_SHIP_V TO XXINTG;
