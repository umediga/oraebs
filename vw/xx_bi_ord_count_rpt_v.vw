DROP VIEW APPS.XX_BI_ORD_COUNT_RPT_V;

/* Formatted on 6/6/2016 4:59:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_ORD_COUNT_RPT_V
(
   SHIP_FROM_ORG,
   SALES_CHANNEL,
   ORDER_TYPE,
   ORDER_SOURCE,
   CUSTOMER_NAME,
   CREATED_BY,
   DATE_ORDERED,
   STATUS,
   ORDER_NUMBER,
   LINE_NUMBER,
   SHIP_FROM_ORG_ID,
   ITEM_NUMBER,
   ORDERED_QUANTITY,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_STATE,
   SHIP_TO_CITY,
   BILL_TO_STATE,
   BILL_TO_CITY,
   SHIP_TO_NAME,
   SHIP_TO_ACC_NUM,
   BILL_TO_NAME,
   BILL_TO_ACC_NUM,
   SALES_REP_ASSGN,
   DIVISION,
   D_CODE,
   EXTENDED_AMOUNT,
   SALES_REP,
   OPERATING_UNIT,
   ORG_CODE
)
AS
   SELECT DISTINCT
          ood.organization_name ship_from_organization,
          ooh.sales_channel_code sales_channel,
          ott.NAME,
          oos.NAME,
          ship_p.party_name customer_name,
          fu.user_name created_by,
          ooh.ordered_date date_ordered,
          ooh.flow_status_code status,
          ooh.order_number,
          ool.line_number,
          ood.organization_id ship_from_org_id,
          ool.ordered_item,
          ool.ordered_quantity,
          ship_loc.address1 ship_to_address1,
          ship_loc.address2 ship_to_address2,
          ship_loc.address3 ship_to_address3,
          ship_loc.address4 ship_to_address4,
          ship_loc.state,
          ship_loc.city,
          z.state,
          z.city,
          ship_p.party_name,
          ship_acc.account_number,
          z.party_name,
          z.account_number,
          z.primary_salesrep_id,
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
                  AND mic.inventory_item_id = ool.inventory_item_id
                  AND mic.organization_id = ool.ship_from_org_id)
             division,
          (SELECT mcb.segment9
             FROM mtl_item_categories mic,
                  mtl_category_sets_tl mcst,
                  mtl_category_sets_b mcsb,
                  mtl_categories_b mcb
            WHERE     mcst.category_set_id = mcsb.category_set_id
                  AND mcst.LANGUAGE = USERENV ('LANG')
                  AND mic.category_set_id = mcsb.category_set_id
                  AND mic.category_id = mcb.category_id
                  AND mcst.category_set_name = 'Sales and Marketing'
                  AND mic.inventory_item_id = ool.inventory_item_id
                  AND mic.organization_id = ool.ship_from_org_id)
             d_code,
          (ool.fulfilled_quantity * ool.unit_selling_price) extended_amount,
          y.sales_rep,
          ooh.org_id,
          ood.organization_code
     FROM oe_order_headers_all ooh,
          oe_order_lines_all ool,
          oe_order_sources oos,
          oe_transaction_types_tl ott,
          fnd_user fu,
          org_organization_definitions ood,
          hz_cust_accounts ship_acc,
          hz_cust_acct_sites_all ship_cas,
          hz_party_sites ship_ps,
          hz_parties ship_p,
          hz_locations ship_loc,
          hz_cust_site_uses_all ship_use,
          (SELECT bill_p.party_name,
                  bill_acc.account_number,
                  bill_use.primary_salesrep_id,
                  bill_use.site_use_id,
                  bill_loc.city,
                  bill_loc.state
             FROM hz_cust_accounts bill_acc,
                  hz_cust_acct_sites_all bill_cas,
                  hz_party_sites bill_ps,
                  hz_parties bill_p,
                  hz_locations bill_loc,
                  hz_cust_site_uses_all bill_use
            WHERE     bill_acc.cust_account_id = bill_cas.cust_account_id
                  AND bill_p.party_id = bill_ps.party_id
                  AND bill_cas.party_site_id = bill_ps.party_site_id
                  AND bill_ps.location_id = bill_loc.location_id
                  AND bill_use.site_use_code = 'BILL_TO'
                  AND bill_use.cust_acct_site_id = bill_cas.cust_acct_site_id)
          z,
          (  SELECT DISTINCT
                    ool.line_id,
                    osc.salesrep_id,
                    NVL (rsa.NAME, jt.resource_name) sales_rep
               FROM ra_salesreps_all rsa,
                    oe_sales_credits osc,
                    jtf_rs_resource_extns_tl jt,
                    oe_order_lines_all ool
              WHERE     rsa.salesrep_id(+) = osc.salesrep_id
                    AND osc.line_id(+) = ool.line_id
                    AND rsa.resource_id = jt.resource_id(+)
           ORDER BY ool.line_id DESC) y,
          ra_salesreps_all rsa
    --JTF_RS_RESOURCE_EXTNS_TL JRRE
    WHERE     ooh.header_id = ool.header_id(+)
          AND ooh.order_source_id = oos.order_source_id
          AND ooh.order_type_id = ott.transaction_type_id
          AND ooh.created_by = fu.user_id
          AND ool.ship_from_org_id = ood.organization_id(+)
          AND ott.LANGUAGE = USERENV ('LANG')
          AND ooh.invoice_to_org_id = z.site_use_id(+)
          AND ship_acc.cust_account_id = ship_cas.cust_account_id
          AND ship_p.party_id = ship_ps.party_id
          AND ship_cas.party_site_id = ship_ps.party_site_id
          AND ship_ps.location_id = ship_loc.location_id
          AND ship_use.site_use_code(+) = 'SHIP_TO'
          AND ship_use.cust_acct_site_id(+) = ship_cas.cust_acct_site_id
          AND ship_use.site_use_id = ooh.ship_to_org_id
          AND rsa.salesrep_id(+) = y.salesrep_id
          AND y.line_id(+) = ool.line_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_ORD_COUNT_RPT_V FOR APPS.XX_BI_ORD_COUNT_RPT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_ORD_COUNT_RPT_V FOR APPS.XX_BI_ORD_COUNT_RPT_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_ORD_COUNT_RPT_V FOR APPS.XX_BI_ORD_COUNT_RPT_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_ORD_COUNT_RPT_V FOR APPS.XX_BI_ORD_COUNT_RPT_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORD_COUNT_RPT_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORD_COUNT_RPT_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_ORD_COUNT_RPT_V TO XXINTG;
