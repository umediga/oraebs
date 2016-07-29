DROP VIEW APPS.XX_BI_OE_CONSHIP_REP_V;

/* Formatted on 6/6/2016 4:59:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_CONSHIP_REP_V
(
   ORDER_NUMBER,
   STATUS,
   CREATED_BY,
   CREATION_DATE,
   ORDER_TYPE,
   ORDERED_DATE,
   CUST_PO_NUMBER,
   ACCOUNT_NAME,
   ACCOUNT_NUMBER,
   SHIP_TO_LOCATION,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_ADDRESS5,
   SHIP_TO_ACCOUNT_NAME,
   CITY,
   STATE,
   POSTAL_CODE,
   COUNTRY,
   BILL_TO_LOCATION,
   SALESPERSON,
   ATTN_CONTACT_DEPT,
   ATTN_COMPANY,
   ORDERED_BY,
   EVALUATING_DEPT,
   HCP_PERFORMING_EVAL,
   NO_OF_EVAL_DAYS,
   FIRST_EXTN_DAYS,
   SECOND_EXTN_DAYS,
   PHYSICIAN_2,
   PHYSICIAN_3,
   PHYSICIAN_4,
   PHYSICIAN_5,
   PHYSICIAN_6,
   PHYSICIAN_7,
   PHYSICIAN_8,
   PHYSICIAN_9,
   PHYSICIAN_10,
   SALES_CHANNEL_CODE,
   ITEM_NAME,
   LINE_CATEGORY_CODE,
   ORDERED_QUANTITY,
   LINE_STATUS,
   ACTUAL_SHIP_DATE,
   SHIPPING_METHOD,
   SHIPMENT_PRIORITY,
   TRACKING_NUMBER,
   WAYBILL,
   FREIGHT_COST,
   SERIAL_FROM,
   SERAIL_TO,
   RETURN_SERIAL_NUMBER,
   TOTAL_APPROVED_DURATION,
   RETURN_DUE_DATE,
   ACTUAL_DURATION,
   LINE_TYPE,
   ACTUAL_SHIPMENT_DATE,
   ACTUAL_RETURN_DATE
)
AS
   SELECT DISTINCT
          ooh.order_number,
          ooh.flow_status_code status,
          fu.user_name created_by,
          ooh.ordered_date creation_date,
          ott.NAME order_type,
          ooh.ordered_date,
          ooh.cust_po_number,
          bill_acc.account_name,
          bill_acc.account_number,
          ship_use.site_use_id ship_to_location,
          ship_loc.address1 ship_to_address1,
          ship_loc.address2 ship_to_address2,
          ship_loc.address3 ship_to_address3,
          ship_loc.address4 ship_to_address4,
             DECODE (ship_loc.city, NULL, NULL, ship_loc.city || ', ')
          || DECODE (ship_loc.state,
                     NULL, ship_loc.province || ', ',
                     ship_loc.state || ', ')
          || DECODE (ship_loc.postal_code,
                     NULL, NULL,
                     ship_loc.postal_code || ', ')
          || DECODE (ship_loc.country, NULL, NULL, ship_loc.country)
             ship_to_address5,
          ship_acc.account_name,
          ship_loc.city,
          ship_loc.state,
          ship_loc.postal_code,
          ship_loc.country,
          bill_use.site_use_id bill_to_location,
          --BILL_LOC.ADDRESS1 SHIP_TO_ADDRESS1,
          --BILL_LOC.ADDRESS2 SHIP_TO_ADDRESS2,
          --BILL_LOC.ADDRESS3 SHIP_TO_ADDRESS3,
          --BILL_LOC.ADDRESS4 SHIP_TO_ADDRESS4,
          --BILL_LOC.CITY,
          --BILL_LOC.STATE,
          --BILL_LOC.POSTAL_CODE,
          --BILL_LOC.COUNTRY,
          rsa.NAME salesperson,
          ooh.attribute1,
          ooh.attribute20,
          ooh.attribute2,
          ohai.segment1 evaluating_dept,
          ohai.segment11 hcp_performing_eval,
          ohai.segment2,
          ohai.segment3,
          ohai.segment4,
          ohai.segment12 physician_2,
          ohai.segment13 physician_3,
          ohai.segment14 physician_4,
          ohai.segment15 physician_5,
          ohai.segment16 physician_6,
          ohai.segment17 physician_7,
          ohai.segment18 physician_8,
          ohai.segment19 physician_9,
          ohai.segment20 physician_10,
          ooh.sales_channel_code,
          ool.ordered_item,
          (SELECT DECODE (
                     (LISTAGG (ola1.LINE_CATEGORY_CODE, ',')
                         WITHIN GROUP (ORDER BY ola1.LINE_CATEGORY_CODE DESC)),
                     NULL, 'ORDER',
                     'RETURN', 'HYBRID')
             FROM oe_order_lines_all ola1
            WHERE     ola1.header_id = ooh.header_id
                  AND ola1.reference_line_id = ool.line_id
                  AND ROWNUM = 1)
             "Line Category Code",
          DECODE (wsn.fm_serial_number,
                  NULL, ret.ordered_quantity,
                  wsn.fm_serial_number, 1)
             ordered_quantity,
          ool.flow_status_code,
          ool.actual_shipment_date,
          ool.shipping_method_code,
          ool.shipment_priority_code,
          wd.tracking_number,
          d.waybill,
          (SELECT unit_amount
             FROM wsh_freight_costs
            WHERE delivery_id = d.delivery_id AND ROWNUM = 1)
             freight_cost,
          wsn.fm_serial_number,
          wsn.to_serial_number,
          ret.serial_number Return_serial_number,
            TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment2, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment3, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment4, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
             AS total_approved_duration,
            ool.actual_shipment_date
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment2, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment3, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment4, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
             AS return_due_date,
          ret.actual_duration,
          ott1.NAME,
          ool.actual_shipment_date "Actual shipment date",
          ret.actual_shipment_date "Actual return date"
     FROM oe_order_headers_all ooh,
          oe_order_lines_all ool,
          oe_transaction_types_tl ott,
          oe_transaction_types_tl ott1,
          fnd_user fu,
          ra_salesreps_all rsa,
          xxintg.xxintg_om_hdr_add_info ohai,
          hz_cust_accounts ship_acc,
          hz_cust_acct_sites_all ship_cas,
          hz_party_sites ship_ps,
          hz_parties ship_p,
          hz_locations ship_loc,
          hz_cust_site_uses_all ship_use,
          hz_cust_accounts bill_acc,
          hz_cust_acct_sites_all bill_cas,
          hz_party_sites bill_ps,
          hz_parties bill_p,
          hz_locations bill_loc,
          hz_cust_site_uses_all bill_use,
          wsh_delivery_details wd,
          wsh_delivery_assignments wda,
          wsh_new_deliveries d,
          wsh_serial_numbers wsn,
          (SELECT ool.header_id,
                  ool.reference_line_id,
                  ooh.order_number,
                  ooh.flow_status_code status,
                  fu.user_name created_by,
                  ooh.ordered_date creation_date,
                  ott.NAME order_type,
                  ooh.ordered_date,
                  ooh.cust_po_number,
                  bill_acc.account_name,
                  bill_acc.account_number,
                  ship_use.site_use_id ship_to_location,
                  ship_loc.address1 ship_to_address1,
                  ship_loc.address2 ship_to_address2,
                  ship_loc.address3 ship_to_address3,
                  ship_loc.address4 ship_to_address4,
                     DECODE (ship_loc.city,
                             NULL, NULL,
                             ship_loc.city || ', ')
                  || DECODE (ship_loc.state,
                             NULL, ship_loc.province || ', ',
                             ship_loc.state || ', ')
                  || DECODE (ship_loc.postal_code,
                             NULL, NULL,
                             ship_loc.postal_code || ', ')
                  || DECODE (ship_loc.country, NULL, NULL, ship_loc.country)
                     ship_to_address5,
                  ship_acc.account_name,
                  ship_loc.city,
                  ship_loc.state,
                  ship_loc.postal_code,
                  ship_loc.country,
                  bill_use.site_use_id bill_to_location,
                  --BILL_LOC.ADDRESS1 SHIP_TO_ADDRESS1,
                  --BILL_LOC.ADDRESS2 SHIP_TO_ADDRESS2,
                  --BILL_LOC.ADDRESS3 SHIP_TO_ADDRESS3,
                  --BILL_LOC.ADDRESS4 SHIP_TO_ADDRESS4,
                  --BILL_LOC.CITY,
                  --BILL_LOC.STATE,
                  --BILL_LOC.POSTAL_CODE,
                  --BILL_LOC.COUNTRY,
                  rsa.NAME salesperson,
                  ooh.attribute1,
                  ooh.attribute20,
                  ooh.attribute2,
                  ohai.segment1 evaluating_dept,
                  ohai.segment11 hcp_performing_eval,
                  ohai.segment2,
                  ohai.segment3,
                  ohai.segment4,
                  ohai.segment12 physician_2,
                  ohai.segment13 physician_3,
                  ohai.segment14 physician_4,
                  ohai.segment15 physician_5,
                  ohai.segment16 physician_6,
                  ohai.segment17 physician_7,
                  ohai.segment18 physician_8,
                  ohai.segment19 physician_9,
                  ohai.segment20 physician_10,
                  ooh.sales_channel_code,
                  ool.ordered_item,
                  ool.line_category_code,
                  ool.ordered_quantity,
                  ool.flow_status_code,
                  ool.actual_shipment_date,
                  ool.shipping_method_code,
                  ool.shipment_priority_code,
                  NULL tracking_number,
                  NULL waybill,
                  NULL freight_cost,
                  NULL,
                  NULL,
                  mut.serial_number,
                  NULL total_approved_duration,
                  NULL return_due_date,
                  ROUND (  ool.actual_shipment_date
                         - (SELECT ool1.actual_shipment_date
                              FROM oe_order_lines_all ool1
                             WHERE ool1.line_id = ool.reference_line_id))
                     AS actual_duration,
                  ott1.NAME,
                  ool.actual_shipment_date "Actual return date"
             FROM oe_order_headers_all ooh,
                  oe_order_lines_all ool,
                  oe_transaction_types_tl ott,
                  oe_transaction_types_tl ott1,
                  fnd_user fu,
                  ra_salesreps_all rsa,
                  xxintg.xxintg_om_hdr_add_info ohai,
                  hz_cust_accounts ship_acc,
                  hz_cust_acct_sites_all ship_cas,
                  hz_party_sites ship_ps,
                  hz_parties ship_p,
                  hz_locations ship_loc,
                  hz_cust_site_uses_all ship_use,
                  hz_cust_accounts bill_acc,
                  hz_cust_acct_sites_all bill_cas,
                  hz_party_sites bill_ps,
                  hz_parties bill_p,
                  hz_locations bill_loc,
                  hz_cust_site_uses_all bill_use,
                  mtl_material_transactions mmt,
                  mtl_unit_transactions_all_v mut,
                  mtl_sales_orders mso,
                  mfg_lookups ml
            WHERE     ooh.header_id = ool.header_id
                  AND ooh.order_type_id = ott.transaction_type_id
                  --AND OOL.LINE_TYPE_ID = OTT.TRANSACTION_TYPE_ID
                  AND ott.LANGUAGE = USERENV ('LANG')
                  AND ott.LANGUAGE = 'US'
                  AND ooh.created_by = fu.user_id
                  AND ool.line_type_id = ott1.transaction_type_id
                  AND ott1.LANGUAGE = 'US'
                  AND ooh.salesrep_id = rsa.salesrep_id
                  AND ooh.attribute11 = TO_CHAR (ohai.code_combination_id(+))
                  AND ship_acc.cust_account_id = ship_cas.cust_account_id
                  AND ship_p.party_id = ship_ps.party_id
                  AND ship_cas.party_site_id = ship_ps.party_site_id
                  AND ship_ps.location_id = ship_loc.location_id
                  AND ship_use.site_use_code(+) = 'SHIP_TO'
                  AND ship_use.cust_acct_site_id(+) =
                         ship_cas.cust_acct_site_id
                  AND ship_use.site_use_id = ooh.ship_to_org_id
                  AND bill_acc.cust_account_id = bill_cas.cust_account_id
                  AND bill_p.party_id = bill_ps.party_id
                  AND bill_cas.party_site_id = bill_ps.party_site_id
                  AND bill_ps.location_id = bill_loc.location_id
                  AND bill_use.site_use_code = 'BILL_TO'
                  AND bill_use.cust_acct_site_id = bill_cas.cust_acct_site_id
                  AND ooh.invoice_to_org_id = bill_use.site_use_id(+)
                  AND ool.line_category_code = 'RETURN'
                  AND ool.ship_from_org_id = mut.organization_id
                  AND ool.inventory_item_id = mut.inventory_item_id
                  AND mut.inventory_item_id = mmt.inventory_item_id
                  AND mmt.trx_source_line_id = ool.line_id
                  AND ool.inventory_item_id = mmt.inventory_item_id
                  AND mso.segment1 = ooh.order_number
                  AND mso.sales_order_id = mmt.transaction_source_id
                  AND mmt.transaction_id = mut.transaction_id
                  AND mmt.organization_id = ool.ship_from_org_id
                  AND mmt.transaction_type_id = 15
                  AND ml.lookup_code = mmt.transaction_action_id
                  AND ml.lookup_type = 'MTL_TRANSACTION_ACTION') ret
    WHERE     ooh.header_id = ool.header_id
          AND ooh.order_type_id = ott.transaction_type_id
          --AND OOL.LINE_TYPE_ID = OTT.TRANSACTION_TYPE_ID
          AND ott.LANGUAGE = USERENV ('LANG')
          AND ott.LANGUAGE = 'US'
          AND ool.line_type_id = ott1.transaction_type_id
          AND ott1.LANGUAGE = 'US'
          AND ooh.created_by = fu.user_id
          AND ooh.salesrep_id = rsa.salesrep_id
          AND ooh.attribute11 = TO_CHAR (ohai.code_combination_id(+))
          AND ship_acc.cust_account_id = ship_cas.cust_account_id
          AND ship_p.party_id = ship_ps.party_id
          AND ship_cas.party_site_id = ship_ps.party_site_id
          AND ship_ps.location_id = ship_loc.location_id
          AND ship_use.site_use_code(+) = 'SHIP_TO'
          AND ship_use.cust_acct_site_id(+) = ship_cas.cust_acct_site_id
          AND ship_use.site_use_id = ooh.ship_to_org_id
          AND bill_acc.cust_account_id = bill_cas.cust_account_id
          AND bill_p.party_id = bill_ps.party_id
          AND bill_cas.party_site_id = bill_ps.party_site_id
          AND bill_ps.location_id = bill_loc.location_id
          AND bill_use.site_use_code = 'BILL_TO'
          AND bill_use.cust_acct_site_id = bill_cas.cust_acct_site_id
          AND ooh.invoice_to_org_id = bill_use.site_use_id(+)
          AND wd.source_header_id = ooh.header_id
          AND ool.line_id = wd.source_line_id
          AND wd.released_status = 'C'
          AND d.delivery_type = 'STANDARD'
          AND wd.delivery_detail_id = wda.delivery_detail_id
          AND wda.delivery_id = d.delivery_id
          AND wd.delivery_detail_id = wsn.delivery_detail_id(+)
          AND ret.header_id(+) = ool.header_id
          -- and nvl(ret.serial_number,1)= nvl(wsn.fm_serial_number,1)
          AND NVL (ret.serial_number, wsn.fm_serial_number) =
                 wsn.fm_serial_number
          AND ool.line_id = NVL (ret.reference_line_id, ool.line_id)
          AND ott.name IN ('ILS Eval Order', 'ILS Rental Order')
   -- and ooh.order_number=150547
   --118177
   UNION
   SELECT DISTINCT
          ooh.order_number,
          ooh.flow_status_code status,
          fu.user_name created_by,
          ooh.ordered_date creation_date,
          ott.NAME order_type,
          ooh.ordered_date,
          ooh.cust_po_number,
          bill_acc.account_name,
          bill_acc.account_number,
          ship_use.site_use_id ship_to_location,
          ship_loc.address1 ship_to_address1,
          ship_loc.address2 ship_to_address2,
          ship_loc.address3 ship_to_address3,
          ship_loc.address4 ship_to_address4,
             DECODE (ship_loc.city, NULL, NULL, ship_loc.city || ', ')
          || DECODE (ship_loc.state,
                     NULL, ship_loc.province || ', ',
                     ship_loc.state || ', ')
          || DECODE (ship_loc.postal_code,
                     NULL, NULL,
                     ship_loc.postal_code || ', ')
          || DECODE (ship_loc.country, NULL, NULL, ship_loc.country)
             ship_to_address5,
          ship_acc.account_name,
          ship_loc.city,
          ship_loc.state,
          ship_loc.postal_code,
          ship_loc.country,
          bill_use.site_use_id bill_to_location,
          --BILL_LOC.ADDRESS1 SHIP_TO_ADDRESS1,
          --BILL_LOC.ADDRESS2 SHIP_TO_ADDRESS2,
          --BILL_LOC.ADDRESS3 SHIP_TO_ADDRESS3,
          --BILL_LOC.ADDRESS4 SHIP_TO_ADDRESS4,
          --BILL_LOC.CITY,
          --BILL_LOC.STATE,
          --BILL_LOC.POSTAL_CODE,
          --BILL_LOC.COUNTRY,
          rsa.NAME salesperson,
          ooh.attribute1,
          ooh.attribute20,
          ooh.attribute2,
          ohai.segment1 evaluating_dept,
          ohai.segment11 hcp_performing_eval,
          ohai.segment2,
          ohai.segment3,
          ohai.segment4,
          ohai.segment12 physician_2,
          ohai.segment13 physician_3,
          ohai.segment14 physician_4,
          ohai.segment15 physician_5,
          ohai.segment16 physician_6,
          ohai.segment17 physician_7,
          ohai.segment18 physician_8,
          ohai.segment19 physician_9,
          ohai.segment20 physician_10,
          ooh.sales_channel_code,
          ool.ordered_item,
          (SELECT DECODE (
                     (LISTAGG (ola1.LINE_CATEGORY_CODE, ',')
                         WITHIN GROUP (ORDER BY ola1.LINE_CATEGORY_CODE DESC)),
                     NULL, 'ORDER',
                     'RETURN', 'HYBRID')
             FROM oe_order_lines_all ola1
            WHERE     ola1.header_id = ooh.header_id
                  AND ola1.reference_line_id = ool.line_id
                  AND ROWNUM = 1)
             "Line Category Code",
          DECODE (wsn.fm_serial_number,
                  NULL, ret.ordered_quantity,
                  wsn.fm_serial_number, 1)
             ordered_quantity,
          ool.flow_status_code,
          ool.actual_shipment_date,
          ool.shipping_method_code,
          ool.shipment_priority_code,
          wd.tracking_number,
          d.waybill,
          (SELECT unit_amount
             FROM wsh_freight_costs
            WHERE delivery_id = d.delivery_id AND ROWNUM = 1)
             freight_cost,
          wsn.fm_serial_number,
          wsn.to_serial_number,
          NULL,
            TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment2, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment3, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment4, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
             AS total_approved_duration,
            ool.actual_shipment_date
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment2, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment3, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
          + TO_NUMBER (REGEXP_REPLACE (NVL (ohai.segment4, 0),
                                       '[^0-9]',
                                       '0',
                                       1))
             AS return_due_date,
          ROUND (  ret.actual_shipment_date
                 - (SELECT ool1.actual_shipment_date
                      FROM oe_order_lines_all ool1
                     WHERE ool1.line_id = ret.reference_line_id))
             AS actual_duration,
          ott1.NAME,
          ool.actual_shipment_date "Actual shipment date",
          ret.actual_shipment_date "Actual return date"
     FROM oe_order_headers_all ooh,
          oe_order_lines_all ool,
          oe_transaction_types_tl ott,
          oe_transaction_types_tl ott1,
          fnd_user fu,
          ra_salesreps_all rsa,
          xxintg.xxintg_om_hdr_add_info ohai,
          hz_cust_accounts ship_acc,
          hz_cust_acct_sites_all ship_cas,
          hz_party_sites ship_ps,
          hz_parties ship_p,
          hz_locations ship_loc,
          hz_cust_site_uses_all ship_use,
          hz_cust_accounts bill_acc,
          hz_cust_acct_sites_all bill_cas,
          hz_party_sites bill_ps,
          hz_parties bill_p,
          hz_locations bill_loc,
          hz_cust_site_uses_all bill_use,
          wsh_delivery_details wd,
          wsh_delivery_assignments wda,
          wsh_new_deliveries d,
          wsh_serial_numbers wsn,
          (SELECT ool.header_id,
                  ool.actual_shipment_date,
                  ool.reference_line_id,
                  ool.ordered_quantity
             FROM oe_order_lines_all ool,
                  oe_order_headers_all ooh,
                  oe_transaction_types_tl ott
            WHERE                                    --order_number=369362 and
                 ooh  .order_type_id = ott.transaction_type_id
                  AND ooh.header_id = ool.header_id
                  AND ott.LANGUAGE = USERENV ('LANG')
                  AND ott.LANGUAGE = 'US'
                  AND ott.name IN ('ILS Eval Order', 'ILS Rental Order')
                  AND ool.line_category_code = 'RETURN') ret
    WHERE     ooh.header_id = ool.header_id
          AND ooh.order_type_id = ott.transaction_type_id
          --AND OOL.LINE_TYPE_ID = OTT.TRANSACTION_TYPE_ID
          AND ott.LANGUAGE = USERENV ('LANG')
          AND ott.LANGUAGE = 'US'
          AND ool.line_type_id = ott1.transaction_type_id
          AND ott1.LANGUAGE = 'US'
          AND ooh.created_by = fu.user_id
          AND ooh.salesrep_id = rsa.salesrep_id
          AND ooh.attribute11 = TO_CHAR (ohai.code_combination_id(+))
          AND ship_acc.cust_account_id = ship_cas.cust_account_id
          AND ship_p.party_id = ship_ps.party_id
          AND ship_cas.party_site_id = ship_ps.party_site_id
          AND ship_ps.location_id = ship_loc.location_id
          AND ship_use.site_use_code(+) = 'SHIP_TO'
          AND ship_use.cust_acct_site_id(+) = ship_cas.cust_acct_site_id
          AND ship_use.site_use_id = ooh.ship_to_org_id
          AND bill_acc.cust_account_id = bill_cas.cust_account_id
          AND bill_p.party_id = bill_ps.party_id
          AND bill_cas.party_site_id = bill_ps.party_site_id
          AND bill_ps.location_id = bill_loc.location_id
          AND bill_use.site_use_code = 'BILL_TO'
          AND bill_use.cust_acct_site_id = bill_cas.cust_acct_site_id
          AND ooh.invoice_to_org_id = bill_use.site_use_id(+)
          AND wd.source_header_id = ooh.header_id
          AND ool.line_id = wd.source_line_id
          AND wd.released_status = 'C'
          AND d.delivery_type = 'STANDARD'
          --  and ool.line_category_code='ORDER'
          AND wd.delivery_detail_id = wda.delivery_detail_id
          AND wda.delivery_id = d.delivery_id
          AND wd.delivery_detail_id = wsn.delivery_detail_id(+)
          AND wsn.fm_serial_number IS NULL
          AND ott.name IN ('ILS Eval Order', 'ILS Rental Order')
          AND ret.header_id = ool.header_id
          AND ool.line_id = ret.reference_line_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_CONSHIP_REP_V FOR APPS.XX_BI_OE_CONSHIP_REP_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_CONSHIP_REP_V FOR APPS.XX_BI_OE_CONSHIP_REP_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_CONSHIP_REP_V FOR APPS.XX_BI_OE_CONSHIP_REP_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_OE_CONSHIP_REP_V TO ETLEBSUSER;
