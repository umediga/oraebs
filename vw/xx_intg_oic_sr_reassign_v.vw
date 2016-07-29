DROP VIEW APPS.XX_INTG_OIC_SR_REASSIGN_V;

/* Formatted on 6/6/2016 4:58:25 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_INTG_OIC_SR_REASSIGN_V
(
   INVOICE_NUMBER,
   PROCESSED_DATE,
   INVOICE_DATE,
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
   DCODE,
   INVENTORY_ITEM_STATUS_CODE,
   CURRENCY,
   ORDER_TYPE,
   CUST_ACCOUNT_ID,
   ACCOUNT_NAME,
   ACCOUNT_NUMBER,
   ORDER_DATE,
   ORDER_HEADER_ID,
   CONVERSION_RATE,
   CONVERSION_TYPE_CODE,
   HEADER_SALESREP_ID,
   ORIG_BOOK_SALESREP_NUM,
   ORIG_BOOK_SALESREP_ID,
   ORIG_BOOK_SALESREP_NAME,
   LATEST_SALESREP_NUMBER,
   LATEST_SALESREP_ID,
   LATEST_SALESREP_NAME,
   CRM_SALESREP_NAME,
   HEADER_SHIP_COUNTRY_ID,
   CUSTOMER_TRX_ID,
   CUST_PO_NUMBER,
   CUSTOMER_TRX_LINE_ID,
   PRIMARY_SALESREP_ID,
   LINE_SALESREP_ID,
   CUST_TRX_LINE_SALESREP_ID,
   HEADER_SHIP_COUNTRY_NAME,
   EMPLOYEE_NUMBER,
   EMPLOYEE_NAME,
   SALESREP_NUMBER,
   SALES_ORDER,
   SALES_ORDER_LINE,
   SET_OF_BOOKS_ID,
   REVENUE_AMOUNT,
   EXTENDED_AMOUNT,
   QUANTITY_INVOICED,
   QUANTITY_ORDERED,
   UNIT_STANDARD_PRICE,
   REVENUE_TYPE,
   SPLIT_PCT,
   INTG_RECORD_ID,
   TERRITORIES_NAME,
   REG_TERRITORIES_NAME,
   AREA_TERRITORIES_NAME
)
AS
     SELECT rct.trx_number invoice_number,
            rctgl.gl_posted_date processed_date,
            rct.trx_date invoice_date,
            h.order_number order_number,
            h.header_id,
            msib.inventory_item_id,
            l.line_number order_line_number,
            l.line_id order_line_id,
            msib.segment1 item_number,
            msib.description,
            h.org_id intg_org_id,
            ood.organization_code,
            ood.organization_id,
            ood.operating_unit,
            ood.organization_name warehouse_name,
            party.party_id,
            party.party_number,
            party.party_name customer_name,
            SUBSTR (l.ordered_item, 1, 15) material_number,
            NVL (l.unit_selling_price, 0),
            NVL (l.unit_list_price, 0),
            NVL (cicv.item_cost, 0),
            NVL (l.ordered_quantity, 0) ordered_quantity,
            NVL (l.shipped_quantity, 0) quantity_shipped,
            NVL (l.pricing_quantity_uom, 0) uom,
            (NVL (l.unit_list_price, 0) - NVL (l.unit_selling_price, 0))
               unit_diff,
            ROUND (NVL (l.shipped_quantity, 0) * NVL (l.unit_selling_price, 0),
                   2)
               transaction_amount,
            NVL (l.cancelled_quantity, 0),
            NVL (l.shipping_quantity, 0),
            ot.transaction_type_id,
            l.ship_from_org_id,
            rct.bill_to_customer_id,
            rct.ship_to_customer_id,
            rct.bill_to_contact_id,
            rct.ship_to_contact_id,
            l.creation_date,
            l.line_type_id,
            l.price_list_id,
            MIN (mc.segment4) division,
            MIN (mc.segment5) sub_division,
            MIN (mc.segment6) contract_category,
            MIN (mc.segment7) brand,
            MIN (mc.segment8) product_class,
            MIN (mc.segment9) product_type,
            MIN (mc.segment10) d_code,
            msib.inventory_item_status_code,
            h.transactional_curr_code currency,
            ot.NAME order_type,
            acct.cust_account_id,
            acct.account_name,
            TO_NUMBER (acct.account_number),                -- TO_NUMBER Added
            h.ordered_date order_date,
            h.header_id order_header_id,
            h.conversion_rate conversion_rate,
            h.conversion_type_code conversion_type_code,
            h.salesrep_id header_salesrep_id,
            jrs.salesrep_number orig_book_salesrep_num,
            -- TO_NUMBER Added
            jrs.salesrep_id orig_book_salesrep_id,
            jrd.source_name orig_book_salesrep_name,
            -- Added on 28-feb-2013
            (SELECT jrsnew.salesrep_number
               FROM apps.jtf_rs_salesreps jrsnew
              WHERE jrsnew.salesrep_id = xosc.salesrep_id AND org_id = h.org_id)
               latest_salesrep_number,
            xosc.salesrep_id latest_salesrep_id,
            (SELECT jrsnew.name
               FROM apps.jtf_rs_salesreps jrsnew
              WHERE jrsnew.salesrep_id = xosc.salesrep_id AND org_id = h.org_id)
               latest_salesrep_name,
            -- Added on 28-feb-2013 end
            jrd.source_name crm_salesrep_name,
            h.ship_to_org_id header_ship_country_id,
            rct.customer_trx_id,
            h.cust_po_number,
            rtx.customer_trx_line_id,
            rct.primary_salesrep_id,
            rctls.salesrep_id line_salesrep_id,
            rctls.cust_trx_line_salesrep_id,
            terr.territory_short_name header_ship_country_name,
            -- xosc.salesrep_id latest_salesrep_id,
            (SELECT TO_NUMBER (jrd.source_number)
               FROM apps.jtf_rs_defresources_v jrd,
                    apps.jtf_rs_salesreps jrsnew
              WHERE     jrsnew.salesrep_id = rctls.salesrep_id
                    AND jrd.resource_id = jrsnew.resource_id)
               employee_number,
            -- TO_NUMBER Added
            (SELECT jrd.source_name
               FROM apps.jtf_rs_defresources_v jrd,
                    apps.jtf_rs_salesreps jrsnew
              WHERE     jrsnew.salesrep_id = rctls.salesrep_id
                    AND jrd.resource_id = jrsnew.resource_id)
               employee_name,
            (SELECT jrsnew.salesrep_number
               FROM apps.jtf_rs_salesreps jrsnew
              WHERE jrsnew.salesrep_id = rctls.salesrep_id)
               salesrep_number,
            rtx.sales_order,
            rtx.sales_order_line,
            rtx.set_of_books_id,
            rtx.revenue_amount,
            rtx.extended_amount,
            rtx.quantity_invoiced,
            rtx.quantity_ordered,
            --rtx.unit_selling_price,
            rtx.unit_standard_price,
            DECODE (
               NVL (rctls.revenue_percent_split, 0),
               0, DECODE (NVL (rctls.non_revenue_percent_split, 0),
                          0, NULL,
                          'NONREVENUE'),
               DECODE (NVL (rctls.non_revenue_percent_split, 0),
                       0, 'REVENUE',
                       NULL))
               revenue_type,
            NVL (rctls.revenue_percent_split, rctls.non_revenue_percent_split),
            rtx.customer_trx_line_id,                            -- latest add
            jta.NAME,
            jta_reg.NAME,
            jta_area.NAME
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
            apps.jtf_rs_salesreps jrs,
            apps.xx_oe_sales_credits xosc,                              -- New
            apps.oe_sales_credits osc,                           -- latest add
            apps.jtf_rs_defresources_v jrd                       -- latest add
                                          ,
            jtf.jtf_terr_rsc_all jtra,
            jtf.jtf_terr_all jta,
            jtf.jtf_terr_all jta_reg,
            jtf.jtf_terr_all jta_area,
            apps.ra_cust_trx_line_gl_dist_all rctgl               -- added for
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
            -- AND mct.category_set_id = mct.category_set_id
            AND mct.category_set_name = 'Sales and Marketing'
            --AND mcs.CATEGORY_SET_ID = '5'  Replace with category set name
            AND rtx.inventory_item_id = msib.inventory_item_id
            -- AND l.invoice_interface_status_code = 'YES'
            AND rct.customer_trx_id = rtx.customer_trx_id
            AND rtx.customer_trx_line_id = rctls.customer_trx_line_id(+)
            AND rtx.customer_trx_id = rctls.customer_trx_id(+)
            --AND rct.customer_trx_id                      = rctls.customer_trx_id(+)
            AND rtx.sales_order = TO_CHAR (h.order_number)
            AND h.header_id = l.header_id
            AND mct.LANGUAGE = USERENV ('LANG')
            AND h.salesrep_id = sr.salesrep_id(+)
            AND h.ship_to_org_id = site.site_use_id
            AND site.cust_acct_site_id = acct_site.cust_acct_site_id
            AND acct_site.party_site_id = party_site.party_site_id
            AND party_site.location_id = loc.location_id
            AND l.line_id = rtx.interface_line_attribute6
            AND NVL (jrs.salesrep_id, rctls.salesrep_id) = rctls.salesrep_id
            AND l.line_id = xosc.line_id(+)                             -- New
            AND NVL (xosc.lattest_flag, 'Y') = 'Y'                      -- New
            AND NVL (jrs.salesrep_id, osc.salesrep_id) = osc.salesrep_id -- New
            AND h.header_id = osc.header_id                             -- New
            AND l.line_id = NVL (osc.line_id, l.line_id)                -- New
            AND loc.country = terr.territory_code
            AND jrd.resource_id = jrs.resource_id
            AND jtra.resource_id(+) = sr.resource_id
            AND jta.terr_id(+) = jtra.terr_id
            AND jta.parent_territory_id = jta_reg.terr_id(+)
            AND jta_reg.parent_territory_id = jta_area.terr_id(+)
            AND rtx.customer_trx_id = rctgl.customer_trx_id(+)
            AND rtx.customer_trx_line_id = rctgl.customer_trx_line_id(+)
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
            msib.description,
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
            ot.NAME,
            l.cancelled_quantity,
            l.shipping_quantity,
            ot.transaction_type_id,
            l.ship_from_org_id,
            l.creation_date,
            l.line_type_id,
            l.price_list_id,
            acct.cust_account_id,
            acct.account_name,
            acct.account_number,
            party.party_name,
            acct.cust_account_id,
            h.order_number,
            h.ordered_date,
            h.header_id,
            ot.NAME,
            party.party_number,
            msib.segment1,
            h.conversion_rate,
            h.conversion_type_code,
            h.salesrep_id,
            jrs.salesrep_id,                                        -- New Add
            jrs.salesrep_number,                                    -- New Add
            jrs.resource_id,
            -- jrs.resource_id,
            h.ship_to_org_id,
            h.cust_po_number,
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
            terr.territory_short_name,
            xosc.salesrep_id,
            jrd.source_name,                                            -- New
            rtx.sales_order,
            rtx.sales_order_line,
            rtx.set_of_books_id,
            rtx.revenue_amount,
            rtx.extended_amount,
            rtx.quantity_invoiced,
            rtx.quantity_ordered,
            --rtx.unit_selling_price,
            rtx.unit_standard_price,
            rctls.revenue_percent_split,
            rctls.non_revenue_percent_split,
            rtx.customer_trx_line_id,                            -- latest add
            jta.NAME,
            jta_reg.NAME,
            jta_area.NAME,
            rct.bill_to_customer_id,
            rct.ship_to_customer_id,
            rctgl.gl_posted_date;
