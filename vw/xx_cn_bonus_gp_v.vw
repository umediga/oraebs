DROP VIEW APPS.XX_CN_BONUS_GP_V;

/* Formatted on 6/6/2016 4:58:51 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_BONUS_GP_V
(
   INVOICE_NUMBER,
   PROCESSED_DATE,
   ORDER_NUMBER,
   HEADER_ID,
   INVENTORY_ITEM_ID,
   ORDER_LINE_NUMBER,
   ORDER_LINE_ID,
   ITEM_NUMBER,
   DESCRIPTION,
   INTG_ORG_ID,
   ORGANIZATION_CODE,
   ORGANIZATION_ID,
   OPERATING_UNIT,
   WAREHOUSE_NAME,
   PARTY_ID,
   PARTY_NUMBER,
   CUSTOMER_NAME,
   MATERIAL_NUMBER,
   UNIT_SELLING_PRICE,
   UNIT_LIST_PRICE,
   ITEM_COST,
   ORDERED_QUANTITY,
   QUANTITY_SHIPPED,
   UOM,
   UNIT_DIFF,
   TRANSACTION_AMOUNT,
   GROSS_PROFIT,
   DISCOUNT,
   CANCELLED_QUANTITY,
   SHIPPING_QUANTITY,
   TRANSACTION_TYPE_ID,
   SHIP_FROM_ORG_ID,
   BILL_TO_ADDRESS_ID,
   SHIP_TO_ADDRESS_ID,
   BILL_TO_CONTACT_ID,
   SHIP_TO_CONTACT_ID,
   CREATION_DATE,
   LINE_TYPE_ID,
   PRICE_LIST_ID,
   DIVISION,
   SUB_DIVISION,
   CONTRACT_CATEGORY,
   BRAND,
   PRODUCT_CLASS,
   PRODUCT_TYPE,
   D_CODE,
   INVENTORY_ITEM_STATUS_CODE,
   CURRENCY,
   ORDER_TYPE,
   CUST_ACCOUNT_ID,
   ORDER_DATE,
   ORDER_HEADER_ID,
   CONVERSION_RATE,
   CONVERSION_TYPE_CODE,
   HEADER_SALESREP_ID,
   SALESREP_ID,
   SALESREP_NUMBER,
   CRM_SALESREP_NAME,
   HEADER_SHIP_COUNTRY_ID,
   CUSTOMER_TRX_ID,
   CUSTOMER_TRX_LINE_ID,
   PRIMARY_SALESREP_ID,
   LINE_SALESREP_ID,
   CUST_TRX_LINE_SALESREP_ID,
   HEADER_SHIP_COUNTRY_NAME
)
AS
     SELECT SUM (rct.trx_number) invoice_number,
            TO_CHAR (rct.trx_date, 'DD-MON-YYYY') processed_date,
            h.order_number order_number,
            h.HEADER_ID,
            msib.inventory_item_id,
            l.line_number order_line_number,
            l.line_id order_line_id,
            msib.segment1 item_number,
            msib.description,
            h.org_id gbc_org_id,
            ood.organization_code,
            ood.organization_id,
            ood.operating_unit,
            ood.organization_name warehouse_name,
            party.party_id,
            party.party_number,
            party.party_name customer_name,
            SUBSTR (l.ordered_item, 1, 15) material_number,
            l.unit_selling_price,
            l.unit_list_price,
            cicv.item_cost,
            l.ordered_quantity Ordered_quantity,
            l.shipped_quantity quantity_shipped,
            l.pricing_quantity_uom uom,
            (l.unit_list_price - l.unit_selling_price) unit_diff,
            ROUND (l.shipped_quantity * l.unit_selling_price, 2)
               transaction_amount,
              ROUND (l.unit_selling_price - cicv.item_cost, 2)
            * l.shipped_quantity
               gross_profit,
            CASE
               WHEN l.unit_list_price < l.unit_selling_price
               THEN
                  NULL
               ELSE
                  ROUND (
                     ( (  (l.unit_list_price - L.unit_selling_price)
                        / NULLIF (unit_list_price, 0)
                        * 100)),
                     2)                            --to display only discounts
            END
               "DISCOUNT",
            l.cancelled_quantity,
            l.shipping_quantity,
            ot.transaction_type_id,
            l.ship_from_org_id,
            rct.bill_to_address_id,
            rct.ship_to_address_id,
            rct.bill_to_contact_id,
            rct.ship_to_contact_id,
            l.creation_date,
            l.line_type_id,
            l.price_list_id,
            MIN (mc.segment1) division,
            MIN (mc.segment2) sub_division,
            MIN (mc.segment3) contract_category,
            MIN (mc.segment4) brand,
            MIN (mc.segment5) product_class,
            MIN (mc.segment6) product_type,
            MIN (mc.segment7) d_code,
            msib.inventory_item_status_code,
            h.transactional_curr_code currency,
            ot.name order_type,
            acct.cust_account_id,
            h.ordered_date order_date,
            h.header_id order_header_id,
            h.conversion_rate conversion_rate,
            h.conversion_type_code conversion_type_code,
            h.salesrep_id header_salesrep_id,
            jrs.salesrep_id,
            jrs.salesrep_number,
            jrs.name crm_salesrep_name,
            h.ship_to_org_id header_ship_country_id,
            rct.customer_trx_id,
            rtx.customer_trx_line_id,
            rct.primary_salesrep_id,
            rctls.salesrep_id line_salesrep_id,
            rctls.cust_trx_line_salesrep_id,
            terr.territory_short_name header_ship_country_name
       FROM apps.oe_order_headers_all h,
            apps.oe_order_lines_all l,
            apps.oe_transaction_types_tl ot,
            apps.org_organization_definitions ood,
            apps.mtl_parameters mp,
            apps.mtl_item_categories mtl,
            apps.mtl_category_sets_b mcs,
            apps.mtl_category_sets_tl mct,
            apps.mtl_system_items_b msib,
            apps.mtl_categories mc,
            apps.cst_item_costs_view cicv,
            apps.hz_cust_site_uses_all site,
            apps.hz_cust_acct_sites_all acct_site,
            apps.hz_party_sites party_site,
            apps.hz_locations loc,
            apps.ra_salesreps_all sr,
            apps.fnd_territories_vl terr,
            apps.hz_parties party,
            apps.hz_cust_accounts_all acct,
            apps.ra_customer_trx_all rct,
            apps.ra_customer_trx_lines_all rtx,
            apps.ra_cust_trx_line_salesreps_all rctls,
            apps.jtf_rs_salesreps jrs
      WHERE     h.sold_to_org_id = acct.cust_account_id
            AND party.party_id = acct.party_id
            AND l.ship_from_org_id = msib.organization_id
            AND h.order_type_id = ot.transaction_type_id
            AND ot.LANGUAGE = 'US'
            AND msib.inventory_item_id = mtl.inventory_item_id
            AND ood.organization_id = mp.organization_id
            AND msib.organization_id = mp.organization_id
            AND mp.organization_id != mp.master_organization_id
            AND cicv.cost_type_id = '1'
            AND cicv.inventory_item_id = msib.inventory_item_id
            AND cicv.organization_id = msib.organization_id
            AND l.inventory_item_id = msib.inventory_item_id
            AND msib.organization_id = mtl.organization_id
            AND mtl.category_id = mc.category_id
            AND mtl.category_set_id = mcs.category_set_id
            AND mct.category_set_id = mcs.category_set_id
            AND mct.category_set_id = mct.category_set_id
            AND mct.category_set_name = 'Sales and Marketing'
            --AND mcs.CATEGORY_SET_ID = '5'  Replace with category set name
            AND rtx.inventory_item_id = msib.inventory_item_id
            AND l.invoice_interface_status_code = 'YES'
            AND rct.customer_trx_id = rtx.customer_trx_id
            AND rtx.customer_trx_line_id = rctls.customer_trx_line_id
            AND rtx.customer_trx_id = rctls.customer_trx_id
            AND rct.customer_trx_id = rctls.customer_trx_id
            AND rtx.sales_order = TO_CHAR (h.order_number)
            AND h.header_id = l.header_id
            AND ot.transaction_type_id = h.order_type_id
            AND ot.language = USERENV ('LANG')
            AND h.salesrep_id = sr.salesrep_id(+)
            AND h.ship_to_org_id = site.site_use_id
            AND site.cust_acct_site_id = acct_site.cust_acct_site_id
            AND acct_site.party_site_id = party_site.party_site_id
            AND party_site.location_id = loc.location_id
            AND l.line_id = rtx.interface_line_attribute6
            AND jrs.salesrep_id = rctls.salesrep_id
            AND loc.country = terr.territory_code
   GROUP BY l.line_id,
            h.order_number,
            h.header_id,
            h.org_id,
            msib.inventory_item_id,
            ood.organization_code,
            ood.organization_id,
            ood.operating_unit,
            ood.organization_name,
            cicv.organization_id,
            cicv.inventory_item_id,
            cicv.cost_type_id,
            party.party_id,
            party.party_name,
            msib.segment1,
            msib.DESCRIPTION,
            cicv.item_cost,
            rct.trx_number,
            l.line_number,
            SUBSTR (l.ordered_item, 1, 15),
            l.unit_selling_price,
            l.unit_list_price,
            l.ordered_quantity,
            l.shipped_quantity,
            msib.inventory_item_status_code,
            h.transactional_curr_code,
            ot.name,
            l.cancelled_quantity,
            l.shipping_quantity,
            ot.transaction_type_id,
            l.ship_from_org_id,
            l.creation_date,
            l.line_type_id,
            l.price_list_id,
            acct.cust_account_id,
            party.party_name,
            acct.cust_account_id,
            h.order_number,
            h.ordered_date,
            h.header_id,
            ot.name,
            party.party_number,
            msib.segment1,
            h.conversion_rate,
            h.conversion_type_code,
            h.salesrep_id,
            jrs.salesrep_id,
            jrs.salesrep_number,
            jrs.name,
            h.ship_to_org_id,
            rct.customer_trx_id,
            rct.trx_date,
            rct.bill_to_address_id,
            rct.ship_to_address_id,
            rct.bill_to_contact_id,
            rct.ship_to_contact_id,
            l.pricing_quantity_uom,
            rtx.customer_trx_line_id,
            rct.primary_salesrep_id,
            rctls.salesrep_id,
            rctls.cust_trx_line_salesrep_id,
            terr.territory_short_name;
