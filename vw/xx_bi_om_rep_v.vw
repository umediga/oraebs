DROP VIEW APPS.XX_BI_OM_REP_V;

/* Formatted on 6/6/2016 4:59:15 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OM_REP_V
(
   OPERATING_UNIT,
   ORDER_NUMBER,
   ORDERED_DATE,
   ORDER_HEADER_TYPE,
   ORDER_TYPE_DESC,
   TRANSACTIONAL_CURR_CODE,
   CUST_PO_NUMBER,
   CANCELLED_FLAG,
   OPEN_FLAG,
   BOOKED_FLAG,
   SALES_REP,
   ORDER_HEADER_STATUS,
   BOOKED_DATE,
   SHIP_TO_CUST_NAME,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_CITY,
   SHIP_TO_COUNTY,
   SHIP_TO_POSTAL_CODE,
   BILL_TO_CUST_NAME,
   BILL_TO_ADDRESS1,
   BILL_TO_ADDRESS2,
   BILL_TO_ADDRESS3,
   BILL_TO_ADDRESS4,
   BILL_TO_CITY,
   BILL_TO_COUNTY,
   BILL_TO_POSTAL_CODE,
   DELIVER_TO_CUST_NAME,
   DELIVER_TO_ADDRESS1,
   DELIVER_TO_ADDRESS2,
   DELIVER_TO_ADDRESS3,
   DELIVER_TO_ADDRESS4,
   DELIVER_TO_CITY,
   DELIVER_TO_COUNTY,
   DELIVER_TO_POSTAL_CODE,
   INVOICE_TO_ORG_ID,
   FREIGHT_TERMS_CODE,
   FOB_POINT_CODE,
   FREIGHT_CARRIER_CODE,
   SHIPMENT_PRIORITY,
   SHIPMENT_METHOD,
   ORDER_LINE_TYPE,
   ORDER_LINE_TYPE_DESC,
   LINE_NUMBER,
   SHIPMENT_NUMBER,
   ORDERED_ITEM,
   REQUEST_DATE,
   PROMISE_DATE,
   SCHEDULE_SHIP_DATE,
   CANCELLED_QUANTITY,
   SHIPPED_QUANTITY,
   ORDERED_QUANTITY,
   FULFILLED_QUANTITY,
   SHIPPING_QUANTITY,
   SHIP_FROM_ORG,
   SHIP_FROM_ORG_NAME,
   UNIT_SELLING_PRICE,
   UNIT_LIST_PRICE,
   SUBINVENTORY_CODE,
   LOCATOR_ID,
   TRANSACTION_TYPE_ID,
   TRANSACTION_ACTION_ID,
   TRANSACTION_SOURCE_TYPE_ID,
   TRANSACTION_SOURCE_ID,
   TRANSACTION_QUANTITY,
   TRANSACTION_DATE,
   ACTUAL_COST
)
AS
   SELECT hou.name,
          ooa.order_number,
          ooa.ordered_date,
          ooth.name order_header_type,
          ooth.description order_type_desc,
          ooa.TRANSACTIONAL_CURR_CODE,
          ooa.CUST_PO_NUMBER,
          ooa.CANCELLED_FLAG,
          ooa.OPEN_FLAG,
          ooa.BOOKED_FLAG,
          jrs.resource_name sales_rep,
          ooa.FLOW_STATUS_CODE order_header_status,
          ooa.booked_date,
          ship_to.party_name ship_to_cust_name,
          ship_to.address1 ship_to_address1,
          ship_to.address2 ship_to_address2,
          ship_to.address3 ship_to_address3,
          ship_to.address4 ship_to_address4,
          ship_to.city ship_to_city,
          ship_to.county ship_to_county,
          ship_to.postal_code ship_to_postal_code,
          bill_to.party_name bill_to_cust_name,
          bill_to.address1 bill_to_address1,
          bill_to.address2 bill_to_address2,
          bill_to.address3 bill_to_address3,
          bill_to.address4 bill_to_address4,
          bill_to.city bill_to_city,
          bill_to.county bill_to_county,
          bill_to.postal_code bill_to_postal_code,
          deliver_to.party_name deliver_to_cust_name,
          deliver_to.address1 deliver_to_address1,
          deliver_to.address2 deliver_to_address2,
          deliver_to.address3 deliver_to_address3,
          deliver_to.address4 deliver_to_address4,
          deliver_to.city deliver_to_city,
          deliver_to.county deliver_to_county,
          deliver_to.postal_code deliver_to_postal_code,
          ooa.INVOICE_TO_ORG_ID,
          ooa.FREIGHT_TERMS_CODE,
          ooa.FOB_POINT_CODE,
          ooa.FREIGHT_CARRIER_CODE,
          flv.meaning shipment_priority,
          car.meaning shipment_method,
          ootl.name order_line_type,
          ootl.description order_line_type_desc,
          ool.line_number,
          ool.shipment_number,
          ool.ordered_item,
          ool.request_date,
          ool.promise_date,
          ool.schedule_ship_date,
          ool.cancelled_quantity,
          ool.shipped_quantity,
          ool.ordered_quantity,
          ool.fulfilled_quantity,
          ool.shipping_quantity,
          ood.organization_code ship_from_org,
          ood.organization_name ship_from_org_name,
          ool.unit_selling_price,
          ool.unit_list_price,
          mmt.SUBINVENTORY_CODE,
          mmt.LOCATOR_ID,
          mmt.TRANSACTION_TYPE_ID,
          mmt.TRANSACTION_ACTION_ID,
          mmt.TRANSACTION_SOURCE_TYPE_ID,
          mmt.TRANSACTION_SOURCE_ID,
          mmt.TRANSACTION_QUANTITY,
          mmt.TRANSACTION_DATE,
          mmt.ACTUAL_COST
     FROM oe_order_headers_all ooa,
          hr_operating_units hou,
          oe_transaction_types_tl ooth,
          oe_order_lines_all ool,
          oe_transaction_types_tl ootl,
          ra_salesreps_all rsa,
          jtf_rs_resource_extns_tl jrs,
          fnd_lookup_values flv,
          fnd_lookup_values car,
          org_organization_definitions ood,
          (SELECT a.cust_acct_site_id,
                  a.cust_account_id,
                  a.party_site_id,
                  b.account_number,
                  b.account_name,
                  d.address1,
                  d.address2,
                  d.address3,
                  d.address4,
                  d.city,
                  d.county,
                  d.postal_code,
                  hp.party_number,
                  hp.party_name
             FROM hz_cust_acct_sites_all a,
                  hz_cust_accounts b,
                  hz_party_sites c,
                  hz_locations d,
                  hz_parties hp
            WHERE     a.cust_account_id = b.cust_account_id
                  AND a.party_site_id = c.party_site_id
                  AND c.location_id = d.location_id
                  AND c.party_id = hp.party_id) ship_to,
          (SELECT a.cust_acct_site_id,
                  a.cust_account_id,
                  a.party_site_id,
                  b.account_number,
                  b.account_name,
                  d.address1,
                  d.address2,
                  d.address3,
                  d.address4,
                  d.city,
                  d.county,
                  d.postal_code,
                  hp.party_number,
                  hp.party_name
             FROM hz_cust_acct_sites_all a,
                  hz_cust_accounts b,
                  hz_party_sites c,
                  hz_locations d,
                  hz_parties hp
            WHERE     a.cust_account_id = b.cust_account_id
                  AND a.party_site_id = c.party_site_id
                  AND c.location_id = d.location_id
                  AND c.party_id = hp.party_id) bill_to,
          (SELECT a.cust_acct_site_id,
                  a.cust_account_id,
                  a.party_site_id,
                  b.account_number,
                  b.account_name,
                  d.address1,
                  d.address2,
                  d.address3,
                  d.address4,
                  d.city,
                  d.county,
                  d.postal_code,
                  hp.party_number,
                  hp.party_name
             FROM hz_cust_acct_sites_all a,
                  hz_cust_accounts b,
                  hz_party_sites c,
                  hz_locations d,
                  hz_parties hp
            WHERE     a.cust_account_id = b.cust_account_id
                  AND a.party_site_id = c.party_site_id
                  AND c.location_id = d.location_id
                  AND c.party_id = hp.party_id) deliver_to,
          mtl_material_transactions mmt
    WHERE     ooth.language = USERENV ('LANG')
          AND ootl.language = USERENV ('LANG')
          AND flv.language = USERENV ('LANG')
          AND flv.lookup_type = 'SHIPMENT_PRIORITY'
          AND car.lookup_type = 'SHIP_METHOD'
          AND flv.enabled_flag = 'Y'
          AND jrs.language = USERENV ('LANG')
          AND car.language = USERENV ('LANG')
          AND ooa.org_id = hou.organization_id
          AND ooa.order_type_id = ooth.transaction_type_id
          AND ooa.org_id = ool.org_id
          AND ooa.header_id = ool.header_id
          AND ool.line_type_id = ootl.transaction_type_id
          AND ooa.salesrep_id = rsa.salesrep_id
          AND rsa.resource_id = jrs.resource_id
          AND ooa.shipment_priority_code = flv.lookup_code
          AND ooa.shipping_method_code = car.lookup_code
          AND ool.ship_from_org_id = ood.organization_id
          AND ooa.ship_to_org_id = ship_to.cust_acct_site_id(+)
          AND ooa.invoice_to_org_id = bill_to.cust_acct_site_id(+)
          AND ooa.deliver_to_org_id = deliver_to.cust_acct_site_id(+)
          AND ool.inventory_item_id = mmt.inventory_item_id(+)
          AND ool.ship_from_org_id = mmt.organization_id(+)
          AND ool.line_id = mmt.trx_source_line_id(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OM_REP_V FOR APPS.XX_BI_OM_REP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OM_REP_V FOR APPS.XX_BI_OM_REP_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OM_REP_V FOR APPS.XX_BI_OM_REP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OM_REP_V FOR APPS.XX_BI_OM_REP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OM_REP_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OM_REP_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OM_REP_V TO XXINTG;
