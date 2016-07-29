DROP VIEW APPS.XX_BI_OPEN_PROCESSED_ORDERS_V;

/* Formatted on 6/6/2016 4:59:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OPEN_PROCESSED_ORDERS_V
(
   OPERATING_UNIT,
   ORDER_NUMBER,
   ACCOUNT_NAME,
   ACCOUNT_NUMBER,
   NAME,
   FLOW_STATUS_CODE,
   ORDERED_DATE,
   CUSTOMER_REQUEST_DATE,
   CUSTOMER_PO_NUMBER,
   TERRITORY,
   SALES_REP,
   CS_REP,
   ORDER_PRIORITY,
   SURGERY_PROCEDURE_TYPE,
   SURGEON_NAME,
   DIVISION,
   CSR_NOTE,
   ITEM_NUMBER,
   DESCRIPTION,
   UOM,
   ORDERED_QUANTITY,
   EXTENDED_AMOUNT,
   PRICE_LIST,
   LINE_TYPE,
   WAREHOUSE,
   SHIP_COMPLETE,
   AGREEMENT,
   ZIP_CODE,
   ORG_CODE,
   PROMO_CODE
)
AS
   SELECT hou.NAME operating_unit,
          ooha.order_number,
          hca.account_name,
          hca.account_number,
          ott.NAME,
          ooha.flow_status_code,
          ooha.ordered_date,
          oola.request_date customer_request_date,
          ooha.cust_po_number customer_po_number,
          NULL territory,
          jrs.resource_name sales_rep,
          (SELECT user_name
             FROM fnd_user
            WHERE user_id = ooha.created_by)
             cs_rep,
          flv.meaning order_priority,
          ooha.attribute15 surgery_procedure_type,
          ooha.attribute8 surgeon_name,
          xx_mtl_item_categories (oola.inventory_item_id,
                                  'Sales and Marketing',
                                  oola.ship_from_org_id,
                                  'DIV')
             division,
          apps.xx_ont_csr_internal_txt (ooha.header_id) csr_note,
          msib.segment1 item_number,
          msib.description,
          oola.order_quantity_uom uom,
          oola.ordered_quantity,
          (SELECT ROUND (oe_oe_totals_summary.config_totals (oola.line_id),
                         2)
             FROM DUAL)
             extended_amount,
          qlh.NAME price_list,
          ottl.NAME line_type,
          a.organization_name warehouse,
          (SELECT os.set_name
             FROM oe_sets os
            WHERE os.set_id = oola.ship_set_id)
             ship_set_name,
          NULL agreement,
          (SELECT ship_loc.postal_code
             FROM hz_cust_accounts ship_acc,
                  hz_cust_acct_sites_all ship_cas,
                  hz_party_sites ship_ps,
                  hz_parties ship_p,
                  hz_locations ship_loc,
                  hz_cust_site_uses_all ship_use
            WHERE     ship_acc.cust_account_id = ship_cas.cust_account_id
                  AND ship_p.party_id = ship_ps.party_id
                  AND ship_cas.party_site_id = ship_ps.party_site_id
                  AND ship_ps.location_id = ship_loc.location_id
                  AND ship_use.site_use_code(+) = 'DELIVER_TO'
                  AND ship_use.cust_acct_site_id(+) =
                         ship_cas.cust_acct_site_id
                  AND ship_use.site_use_id = ooha.deliver_to_org_id)
             zip_code,
          a.organization_code,
          ooha.attribute17
     FROM oe_transaction_types_tl ott,
          oe_order_headers_all ooha,
          fnd_lookup_values flv,
          oe_order_lines_all oola,
          oe_transaction_types_tl ottl,
          mtl_system_items_b msib,
          ra_salesreps_all rsa,
          jtf_rs_resource_extns_tl jrs,
          apps.qp_list_headers qlh,
          hz_cust_accounts_all hca,
          hr_operating_units hou,
          org_organization_definitions a
    WHERE     ott.LANGUAGE = 'US'
          AND flv.LANGUAGE = 'US'
          AND flv.lookup_type = 'SHIPMENT_PRIORITY'
          AND flv.enabled_flag = 'Y'
          AND jrs.LANGUAGE = USERENV ('LANG')
          AND ottl.LANGUAGE = USERENV ('LANG')
          AND ooha.shipment_priority_code = flv.lookup_code
          AND ooha.order_type_id = ott.transaction_type_id
          AND ooha.header_id = oola.header_id
          AND oola.line_type_id = ottl.transaction_type_id
          AND ooha.org_id = oola.org_id
          AND oola.ship_from_org_id = a.organization_id
          AND oola.inventory_item_id = msib.inventory_item_id
          AND oola.ship_from_org_id = msib.organization_id
          AND ooha.salesrep_id = rsa.salesrep_id
          AND rsa.resource_id = jrs.resource_id
          AND oola.price_list_id = qlh.list_header_id(+)
          AND ooha.sold_to_org_id = hca.cust_account_id
          AND ooha.org_id = hou.organization_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OPEN_PROCESSED_ORDERS_V FOR APPS.XX_BI_OPEN_PROCESSED_ORDERS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OPEN_PROCESSED_ORDERS_V FOR APPS.XX_BI_OPEN_PROCESSED_ORDERS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OPEN_PROCESSED_ORDERS_V FOR APPS.XX_BI_OPEN_PROCESSED_ORDERS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OPEN_PROCESSED_ORDERS_V FOR APPS.XX_BI_OPEN_PROCESSED_ORDERS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OPEN_PROCESSED_ORDERS_V TO ETLEBSUSER;
