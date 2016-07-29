DROP VIEW APPS.XXINTG_OE_ORDER_LINES_V;

/* Formatted on 6/6/2016 5:00:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_OE_ORDER_LINES_V
(
   LINE_ID,
   ORG_ID,
   HEADER_ID,
   LINE_TYPE_ID,
   LINE,
   LINE_NUMBER,
   ORDERED_ITEM,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   REQUEST_DATE,
   PROMISE_DATE,
   SCHEDULE_ARRIVAL_DATE,
   SCHEDULED_SHIP_DATE,
   UOM,
   ORDERED_QUANTITY,
   TAX_EXEMPT_NUMBER,
   CUST_PO_NUMBER,
   INVENTORY_ITEM_ID,
   TAX_CODE,
   TAX_RATE,
   LIST_PRICE,
   UNIT_SELLING_PRICE,
   DISCOUNT,
   TAX_VALUE,
   ITEM_TYPE_CODE,
   SHIPMENT_NUMBER,
   ORDERED_ITEM_ID,
   SHIPPING_INSTRUCTIONS,
   PACKING_INSTRUCTIONS,
   INVOICED_QUANTITY,
   LINE_PAYMENT_TERMS,
   LINE_TOTAL,
   EXTENDED_PRICE,
   LINE_CHARGES,
   LINE_TAXES,
   ADJUSTED_AMOUNT,
   CHARGE_PERIODICITY_CODE,
   CANCELLED_QUANTITY,
   DOCTOR_NAME,
   LINE_LAST_UPDATE_DATE,
   LINE_LEVEL_PRICE_LIST,
   HANDLING_FEE_INVOICE_AMOUNT,
   HANDLING_FEES,
   HANDLING_FEE_INV_AMT,
   LINE_ORDER_STATUS,
   NO_OF_MODIFIERS,
   MODIFIER_MAX_START_DATE,
   MODIFIER_MIN_END_DATE,
   INVOICE_NUMBER,
   INVOICE_DATE,
   INVOICE_AMOUNT,
   LINE_TYPE,
   HOLD_NAME,
   MODIFIER_NUMBER,
   MODIFIER_NAME,
   FROM_SERIAL_NUMBER,
   TO_SERIAL_NUMBER,
   DELIVERY_NUMBER,
   SHIPPED_DATE,
   PATIENT_NAME,
   RETURN_REASON,
   SHIPPED_QUANTITY,
   WAREHOUSE,
   RESERVED_QUANTITY,
   UNIT_COST,
   DEALER_NAME,
   DOCTOR_1,
   DOCTOR_2,
   DOCTOR_3,
   DOCTOR_4,
   DOCTOR_5,
   EVALUATING_DEPT,
   HOSPITAL_CONTACT,
   HOSPITAL_CONTACT_NUMBER,
   NO_OF_EVAL_DAYS,
   HOLD_TYPE,
   RELEASED_FLAG,
   SHIP_FROM_ORG_NAME,
   SHIP_TO_ADDRESS,
   PLANNER_CODE,
   SHIP_TO_CUSTOMER_NUMBER,
   SHIP_TO_SITE_NUMBER,
   BILL_TO_SITE_NUMBER,
   CREATION_DATE,
   CREDIT_CARD_TYPE,
   DATE_OF_SURGERY,
   SURGEON_NAME,
   SS_ORDER_NO,
   TRANSACTIONAL_CURRENCY,
   ORDER_LAST_UPDATE_DATE,
   ORDERED_DATE,
   ORDER_TOTAL,
   LINES_TOTAL,
   CHARGES_TOTAL,
   TAXES_TOTAL,
   ORDER_NUMBER,
   VERSION_NUMBER,
   PO_NUMBER,
   SHIP_TO_LOCATION,
   BILL_TO_LOCATION,
   SALES_REP,
   SALESREP_EMAIL,
   SALESREP_ID,
   CUSTOMER_NAME,
   CUSTOMER_NUMBER,
   FREIGHT_TERMS,
   SHIP_METHOD,
   PRICE_LIST,
   HEADER_ORDER_STATUS,
   OPERATING_UNIT,
   PAYMENT_TERMS,
   ORDER_TYPE
)
AS
   SELECT "LINE_ID",
          "ORG_ID",
          "HEADER_ID",
          "LINE_TYPE_ID",
          "LINE",
          "LINE_NUMBER",
          "ORDERED_ITEM",
          "ITEM_NUMBER",
          "ITEM_DESCRIPTION",
          "REQUEST_DATE",
          "PROMISE_DATE",
          "SCHEDULE_ARRIVAL_DATE",
          "SCHEDULED_SHIP_DATE",
          "UOM",
          "ORDERED_QUANTITY",
          "TAX_EXEMPT_NUMBER",
          "CUST_PO_NUMBER",
          "INVENTORY_ITEM_ID",
          "TAX_CODE",
          "TAX_RATE",
          "LIST_PRICE",
          "UNIT_SELLING_PRICE",
          "DISCOUNT",
          "TAX_VALUE",
          "ITEM_TYPE_CODE",
          "SHIPMENT_NUMBER",
          "ORDERED_ITEM_ID",
          "SHIPPING_INSTRUCTIONS",
          "PACKING_INSTRUCTIONS",
          "INVOICED_QUANTITY",
          "LINE_PAYMENT_TERMS",
          "LINE_TOTAL",
          "EXTENDED_PRICE",
          "LINE_CHARGES",
          "LINE_TAXES",
          "ADJUSTED_AMOUNT",
          "CHARGE_PERIODICITY_CODE",
          "CANCELLED_QUANTITY",
          "DOCTOR_NAME",
          "LINE_LAST_UPDATE_DATE",
          "LINE_LEVEL_PRICE_LIST",
          "HANDLING_FEE_INVOICE_AMOUNT",
          "HANDLING_FEES",
          "HANDLING_FEE_INV_AMT",
          "LINE_ORDER_STATUS",
          "NO_OF_MODIFIERS",
          "MODIFIER_MAX_START_DATE",
          "MODIFIER_MIN_END_DATE",
          "INVOICE_NUMBER",
          "INVOICE_DATE",
          "INVOICE_AMOUNT",
          "LINE_TYPE",
          "HOLD_NAME",
          "MODIFIER_NUMBER",
          "MODIFIER_NAME",
          "FROM_SERIAL_NUMBER",
          "TO_SERIAL_NUMBER",
          "DELIVERY_NUMBER",
          "SHIPPED_DATE",
          "PATIENT_NAME",
          "RETURN_REASON",
          "SHIPPED_QUANTITY",
          "WAREHOUSE",
          "RESERVED_QUANTITY",
          "UNIT_COST",
          "DEALER_NAME",
          "DOCTOR_1",
          "DOCTOR_2",
          "DOCTOR_3",
          "DOCTOR_4",
          "DOCTOR_5",
          "EVALUATING_DEPT",
          "HOSPITAL_CONTACT",
          "HOSPITAL_CONTACT_NUMBER",
          "NO_OF_EVAL_DAYS",
          "HOLD_TYPE",
          "RELEASED_FLAG",
          "SHIP_FROM_ORG_NAME",
          "SHIP_TO_ADDRESS",
          "PLANNER_CODE",
          "SHIP_TO_CUSTOMER_NUMBER",
          "SHIP_TO_SITE_NUMBER",
          "BILL_TO_SITE_NUMBER",
          "CREATION_DATE",
          "CREDIT_CARD_TYPE",
          "DATE_OF_SURGERY",
          "SURGEON_NAME",
          "SS_ORDER_NO",
          "TRANSACTIONAL_CURRENCY",
          "ORDER_LAST_UPDATE_DATE",
          "ORDERED_DATE",
          "ORDER_TOTAL",
          "LINES_TOTAL",
          "CHARGES_TOTAL",
          "TAXES_TOTAL",
          "ORDER_NUMBER",
          "VERSION_NUMBER",
          "PO_NUMBER",
          "SHIP_TO_LOCATION",
          "BILL_TO_LOCATION",
          "SALES_REP",
          "SALESREP_EMAIL",
          "SALESREP_ID",
          "CUSTOMER_NAME",
          "CUSTOMER_NUMBER",
          "FREIGHT_TERMS",
          "SHIP_METHOD",
          "PRICE_LIST",
          "HEADER_ORDER_STATUS",
          "OPERATING_UNIT",
          "PAYMENT_TERMS",
          "ORDER_TYPE"
     FROM (SELECT /*+ INDEX(oe_order_headers_all OE_ORDER_HEADERS_U1) */
                 l.line_id,
                  l.org_id,
                  l.header_id,
                  l.line_type_id,
                  oe_order_misc_pub.get_concat_line_number (l.line_id) line,
                  l.line_number,
                  l.ordered_item,
                  DECODE (l.item_identifier_type,
                          'CUST', c.customer_item_number,
                          'INT', itemskfv.concatenated_segments,
                          NULL, itemskfv.concatenated_segments,
                          l.ordered_item)
                     item_number,
                  DECODE (
                     l.item_identifier_type,
                     'CUST', NVL (c.customer_item_desc, items.description),
                     'INT', items.description,
                     NULL, items.description,
                     items.description)
                     item_description,
                  TO_CHAR (l.request_date, 'DD-MON-YYYY HH24:MI:SS')
                     request_date,
                  l.promise_date,
                  l.schedule_arrival_date,
                  TO_CHAR (l.schedule_ship_date, 'DD-MON-YYYY HH24:MI:SS')
                     scheduled_ship_date,
                  uom.unit_of_measure_tl uom,
                  DECODE (l.line_category_code,
                          'RETURN', (-1) * ordered_quantity,
                          ordered_quantity)
                     ordered_quantity,
                  l.tax_exempt_number,
                  l.cust_po_number,
                  l.inventory_item_id,
                  l.tax_code,
                  l.tax_rate,
                  TO_CHAR (
                     l.unit_list_price,
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     list_price,
                  TO_CHAR (
                     l.unit_selling_price,
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     unit_selling_price,
                  TO_CHAR (
                     oe_oe_totals_summary.get_discount (l.unit_list_price,
                                                        l.unit_selling_price),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     discount,
                  l.tax_value,
                  l.item_type_code,
                  l.shipment_number,
                  l.ordered_item_id,
                  l.shipping_instructions,
                  l.packing_instructions,
                  l.invoiced_quantity,
                  term.NAME line_payment_terms,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    l.line_id,
                                                    'ALL'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     line_total,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    l.line_id,
                                                    'LINES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     extended_price,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    l.line_id,
                                                    'CHARGES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     line_charges,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    l.line_id,
                                                    'TAXES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     line_taxes,
                  (  SELECT SUM (adjusted_amount)
                       FROM oe_price_adjustments_v opa
                      WHERE     opa.header_id = h.header_id
                            AND opa.line_id = l.line_id
                            AND applied_flag = 'Y'
                            AND list_line_type_code <> 'FREIGHT_CHARGE'
                   GROUP BY opa.line_id)
                     adjusted_amount,
                  l.charge_periodicity_code,
                  l.cancelled_quantity,
                  l.attribute1 doctor_name,
                  TO_CHAR (l.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
                     line_last_update_date,
                  pl2.NAME line_level_price_list,
                  NVL (opa.invoiced_amount, 0.00) handling_fee_invoice_amount,
                  qp_qp_form_pricing_attr.get_charge_name (
                     pl2.list_header_id,
                     opa.charge_type_code,
                     opa.charge_subtype_code,
                     opa.list_line_type_code)
                     handling_fees,
                  opa.invoiced_amount handling_fee_inv_amt,
                  l.flow_status_code AS line_order_status,
                  (SELECT COUNT (*)
                     FROM oe_price_adjustments_v opa
                    WHERE     opa.header_id = h.header_id
                          AND line_id = l.line_id
                          AND opa.applied_flag = 'Y'
                          AND opa.list_line_type_code <> 'FREIGHT_CHARGE')
                     no_of_modifiers,
                  (SELECT MAX (start_date_active)
                     FROM qp_list_headers qlh
                    WHERE NAME IN
                             (SELECT opa.adjustment_name
                                FROM oe_price_adjustments_v opa
                               WHERE     opa.header_id = h.header_id
                                     AND opa.line_id = l.line_id
                                     AND applied_flag = 'Y'
                                     AND list_line_type_code <>
                                            'FREIGHT_CHARGE'))
                     modifier_max_start_date,
                  (SELECT MIN (end_date_active)
                     FROM qp_list_headers qlh
                    WHERE NAME IN
                             (SELECT opa.adjustment_name
                                FROM oe_price_adjustments_v opa
                               WHERE     opa.header_id = h.header_id
                                     AND opa.line_id = l.line_id
                                     AND applied_flag = 'Y'
                                     AND list_line_type_code <>
                                            'FREIGHT_CHARGE'))
                     modifier_min_end_date,
                  (SELECT rcta.trx_number
                     FROM ra_customer_trx_all rcta
                    WHERE     rcta.interface_header_attribute1 =
                                 TO_CHAR (h.order_number)
                          AND rcta.sold_to_customer_id = h.sold_to_org_id
                          AND ROWNUM < 2)
                     invoice_number,
                  (SELECT TO_CHAR (rcta.trx_date, 'DD-MON-YYYY')
                     FROM ra_customer_trx_all rcta
                    WHERE     rcta.interface_header_attribute1 =
                                 TO_CHAR (h.order_number)
                          AND rcta.sold_to_customer_id = h.sold_to_org_id
                          AND ROWNUM < 2)
                     invoice_date,
                  (SELECT SUM (rctla.revenue_amount)
                     FROM ra_customer_trx_all rcta,
                          ra_customer_trx_lines_all rctla
                    WHERE     rcta.interface_header_attribute1 =
                                 TO_CHAR (h.order_number)
                          AND rcta.customer_trx_id = rctla.customer_trx_id
                          AND l.line_id = rctla.interface_line_attribute6
                          AND rcta.sold_to_customer_id = h.sold_to_org_id)
                     invoice_amount,
                  lt1.NAME line_type,
                  xxintg_oe_so_extract_pkg.get_hold_name (h.header_id,
                                                          l.line_id)
                     hold_name,
                  xxintg_oe_so_extract_pkg.get_modifier_number (h.header_id,
                                                                l.line_id)
                     modifier_number,
                  xxintg_oe_so_extract_pkg.get_modifier_name (h.header_id,
                                                              l.line_id)
                     modifier_name,
                  (SELECT wsn.fm_serial_number
                     FROM wsh_delivery_details wdd,
                          wsh_delivery_assignments wda,
                          wsh_new_deliveries wnd,
                          wsh_serial_numbers wsn
                    WHERE     wdd.source_line_id = l.line_id
                          AND wdd.source_header_id = l.header_id
                          AND wdd.delivery_detail_id = wda.delivery_detail_id
                          AND wda.delivery_id = wnd.delivery_id
                          AND wda.delivery_detail_id = wsn.delivery_detail_id
                          AND ROWNUM < 2)
                     from_serial_number,
                  (SELECT wsn.to_serial_number
                     FROM wsh_delivery_details wdd,
                          wsh_delivery_assignments wda,
                          wsh_new_deliveries wnd,
                          wsh_serial_numbers wsn
                    WHERE     wdd.source_line_id = l.line_id
                          AND wdd.source_header_id = l.header_id
                          AND wdd.delivery_detail_id = wda.delivery_detail_id
                          AND wda.delivery_id = wnd.delivery_id
                          AND wda.delivery_detail_id = wsn.delivery_detail_id
                          AND ROWNUM < 2)
                     to_serial_number,
                  (SELECT wnd.NAME
                     FROM wsh_delivery_details wdd,
                          wsh_delivery_assignments wda,
                          wsh_new_deliveries wnd
                    WHERE     wdd.source_line_id = l.line_id
                          AND wdd.source_header_id = l.header_id
                          AND wdd.delivery_detail_id = wda.delivery_detail_id
                          AND wda.delivery_id = wnd.delivery_id
                          AND ROWNUM < 2)
                     delivery_number,
                  (SELECT TO_CHAR (wnd.initial_pickup_date,
                                   'DD-MON-YYYY HH24:MI:SS')
                     FROM wsh_delivery_details wdd,
                          wsh_delivery_assignments wda,
                          wsh_new_deliveries wnd
                    WHERE     wdd.source_line_id = l.line_id
                          AND wdd.source_header_id = l.header_id
                          AND wdd.delivery_detail_id = wda.delivery_detail_id
                          AND wda.delivery_id = wnd.delivery_id
                          AND ROWNUM < 2)
                     shipped_date,
                  l.attribute6 AS patient_name,
                  (SELECT DISTINCT meaning
                     FROM fnd_lookup_values_vl
                    WHERE     lookup_type = 'CREDIT_MEMO_REASON'
                          AND (view_application_id = 222)
                          AND (security_group_id = 0)
                          AND lookup_code = l.return_reason_code)
                     return_reason,
                  (  SELECT SUM (wdd1.shipped_quantity)
                       FROM wsh_delivery_details wdd1
                      WHERE     wdd1.source_line_id = l.line_id
                            AND wdd1.source_header_id = l.header_id
                            AND inventory_item_id = l.inventory_item_id
                            AND wdd1.source_code = 'OE'
                   GROUP BY source_line_id)
                     shipped_quantity,
                  (SELECT mp.organization_code
                     FROM mtl_parameters mp
                    WHERE mp.organization_id = l.ship_from_org_id)
                     warehouse,
                  mr.reservation_quantity reserved_quantity,
                  cic.item_cost unit_cost,
                  --- Header Information ---
                  NULL dealer_name,
                  NULL doctor_1,
                  NULL doctor_2,
                  NULL doctor_3,
                  NULL doctor_4,
                  NULL doctor_5,
                  NULL evaluating_dept,
                  NULL hospital_contact,
                  NULL hospital_contact_number,
                  NULL no_of_eval_days,
                  (DECODE (
                      xxintg_oe_so_extract_pkg.get_hold_name (h.header_id,
                                                              l.line_id),
                      NULL, 'None',
                      xxintg_oe_so_extract_pkg.get_hold_name (h.header_id,
                                                              l.line_id)))
                     hold_type,
                  (SELECT released_flag
                     FROM oe_order_holds_all
                    WHERE     header_id = l.header_id
                          AND line_id = l.line_id
                          AND ROWNUM < 2)
                     released_flag,
                  (SELECT mp.organization_name
                     FROM org_organization_definitions mp
                    WHERE     mp.organization_id = l.ship_from_org_id
                          AND ROWNUM < 2)
                     ship_from_org_name,
                  (SELECT (   address1
                           || ','
                           || address2
                           || ','
                           || address3
                           || ','
                           || address4
                           || ','
                           || city
                           || ','
                           || postal_code
                           || ','
                           || country)
                             ship_to_address
                     FROM hz_locations
                    WHERE location_id =
                             (SELECT hps.location_id
                                FROM hz_cust_accounts_all hca,
                                     hz_cust_site_uses_all hcsua,
                                     hz_cust_acct_sites_all hcasa,
                                     hz_party_sites hps
                               WHERE     hcsua.site_use_id = h.ship_to_org_id
                                     AND hca.cust_account_id =
                                            hcasa.cust_account_id
                                     AND hcasa.cust_acct_site_id =
                                            hcsua.cust_acct_site_id
                                     AND hcsua.site_use_code = 'SHIP_TO'
                                     AND hps.party_site_id =
                                            hcasa.party_site_id))
                     ship_to_address,
                  itemskfv.planner_code,
                  (SELECT hca.account_number customer_no
                     FROM hz_cust_accounts_all hca,
                          hz_cust_site_uses_all hcsua,
                          hz_cust_acct_sites_all hcasa
                    WHERE     hcsua.site_use_id = h.ship_to_org_id
                          AND hca.cust_account_id = hcasa.cust_account_id
                          AND hcasa.cust_acct_site_id =
                                 hcsua.cust_acct_site_id
                          AND hcsua.site_use_code = 'SHIP_TO')
                     ship_to_customer_number,
                  (SELECT hps.party_site_number
                     FROM hz_cust_accounts_all hca,
                          hz_cust_site_uses_all hcsua,
                          hz_cust_acct_sites_all hcasa,
                          hz_party_sites hps
                    WHERE     hcsua.site_use_id = h.ship_to_org_id
                          AND hca.cust_account_id = hcasa.cust_account_id
                          AND hcasa.cust_acct_site_id =
                                 hcsua.cust_acct_site_id
                          AND hcsua.site_use_code = 'SHIP_TO'
                          AND hps.party_site_id = hcasa.party_site_id)
                     ship_to_site_number,
                  (SELECT hps.party_site_number
                     FROM hz_cust_accounts_all hca,
                          hz_cust_site_uses_all hcsua,
                          hz_cust_acct_sites_all hcasa,
                          hz_party_sites hps
                    WHERE     hcsua.site_use_id = h.invoice_to_org_id
                          AND hca.cust_account_id = hcasa.cust_account_id
                          AND hcasa.cust_acct_site_id =
                                 hcsua.cust_acct_site_id
                          AND hcsua.site_use_code = 'BILL_TO'
                          AND hps.party_site_id = hcasa.party_site_id)
                     bill_to_site_number,
                  TO_CHAR (h.creation_date, 'DD-MON-YYYY HH24:MI:SS')
                     creation_date,
                  h.credit_card_code credit_card_type,
                  h.attribute7 date_of_surgery,
                  DECODE (
                     TRIM (
                           xxhim.doctors_last_name
                        || ', '
                        || xxhim.doctors_first_name
                        || ' '
                        || xxhim.doctors_middle_name),
                     ',', NULL,
                        xxhim.doctors_last_name
                     || ', '
                     || xxhim.doctors_first_name
                     || ' '
                     || xxhim.doctors_middle_name)
                     AS surgeon_name,
                  h.orig_sys_document_ref ss_order_no,
                  h.transactional_curr_code transactional_currency,
                  TO_CHAR (h.last_update_date, 'DD-MON-YYYY HH24:MI:SS')
                     order_last_update_date,
                  TO_CHAR (h.ordered_date, 'DD-MON-YYYY HH24:MI:SS')
                     ordered_date,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id, NULL, 'ALL'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     order_total,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    NULL,
                                                    'LINES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     lines_total,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    NULL,
                                                    'CHARGES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     charges_total,
                  TO_CHAR (
                     oe_totals_grp.get_order_total (h.header_id,
                                                    NULL,
                                                    'TAXES'),
                     fnd_currency.safe_get_format_mask (
                        h.transactional_curr_code,
                        30))
                     taxes_total,
                  h.order_number,
                  h.version_number,
                  h.cust_po_number po_number,
                  ship_su.LOCATION ship_to_location,
                  bill_su.LOCATION bill_to_location,
                  jextn.resource_name sales_rep,
                  jextn.source_email salesrep_email,
                  h.salesrep_id,
                  cust.party_name customer_name,
                  custacct.account_number customer_number,
                  frlkup.meaning freight_terms,
                  smlkup.meaning ship_method,
                  pl.NAME price_list,
                  h.flow_status_code header_order_status,
                  (SELECT hou.NAME
                     FROM hr_organization_units hou
                    WHERE hou.organization_id = h.org_id)
                     operating_unit,
                  term1.NAME payment_terms,
                  (SELECT NAME
                     FROM oe_transaction_types_tl t,
                          oe_transaction_types_all ot
                    WHERE     t.transaction_type_id = ot.transaction_type_id
                          AND h.order_type_id = ot.transaction_type_id
                          AND t.LANGUAGE = USERENV ('lang'))
                     order_type
             FROM oe_order_headers_all h,
                  oe_order_lines_all l,
                  ra_terms_tl term,
                  mtl_system_items_tl items,
                  mtl_system_items_kfv itemskfv,
                  mtl_customer_items c,
                  mtl_units_of_measure_tl uom,
                  oe_transaction_types_all lt,
                  oe_transaction_types_tl lt1,
                  qp_list_headers_tl pl2,
                  (SELECT op.charge_type_code,
                          op.charge_subtype_code,
                          op.list_line_type_code,
                          op.header_id,
                          op.line_id,
                          NVL (op.invoiced_amount, 0.00) invoiced_amount
                     FROM oe_price_adjustments op
                    WHERE op.invoiced_flag = 'Y') opa,
                  mtl_reservations mr,
                  (SELECT inventory_item_id, organization_id, item_cost
                     FROM cst_item_costs
                    WHERE cost_type_id = 1) cic,
                  hz_cust_site_uses_all ship_su,
                  hz_cust_site_uses_all bill_su,
                  jtf_rs_salesreps sr,
                  jtf_rs_resource_extns_vl jextn,
                  hz_parties cust,
                  hz_cust_accounts custacct,
                  oe_lookups frlkup,
                  fnd_lookup_values smlkup,
                  qp_list_headers_tl pl,
                  ra_terms_tl term1,
                  XXINTG.xxintg_hcp_int_main xxhim
            WHERE     l.item_type_code <> 'INCLUDED'
                  AND l.header_id = h.header_id
                  AND l.line_type_id = lt.transaction_type_id
                  AND lt.transaction_type_code = 'LINE'
                  AND l.payment_term_id = term.term_id(+)
                  AND term.LANGUAGE(+) = USERENV ('LANG')
                  AND l.inventory_item_id = items.inventory_item_id(+)
                  AND l.inventory_item_id = itemskfv.inventory_item_id(+)
                  AND items.organization_id = itemskfv.organization_id
                  AND items.LANGUAGE = USERENV ('LANG')
                  AND oe_sys_parameters.VALUE ('MASTER_ORGANIZATION_ID',
                                               l.org_id) =
                         items.organization_id
                  AND l.ordered_item_id = c.customer_item_id(+)
                  AND l.order_quantity_uom = uom.uom_code(+)
                  AND uom.LANGUAGE(+) = USERENV ('LANG')
                  AND l.price_list_id = pl2.list_header_id(+)
                  AND pl2.LANGUAGE(+) = USERENV ('LANG')
                  AND l.header_id = opa.header_id(+)
                  AND l.line_id = opa.line_id(+)
                  AND lt1.transaction_type_id = l.line_type_id
                  AND lt1.LANGUAGE(+) = USERENV ('LANG')
                  AND mr.inventory_item_id(+) = l.inventory_item_id
                  AND mr.demand_source_line_id(+) = l.line_id
                  AND mr.organization_id(+) = l.ship_from_org_id
                  AND l.inventory_item_id = cic.inventory_item_id(+)
                  AND l.ship_from_org_id = cic.organization_id(+)
                  AND h.ship_to_org_id = ship_su.site_use_id(+)
                  AND bill_su.site_use_id(+) = h.invoice_to_org_id
                  AND h.salesrep_id = sr.salesrep_id(+)
                  AND NVL (h.org_id, -99) = NVL (sr.org_id(+), -99)
                  AND sr.resource_id = jextn.resource_id(+)
                  AND h.sold_to_org_id = custacct.cust_account_id(+)
                  AND custacct.party_id = cust.party_id(+)
                  AND h.freight_terms_code = frlkup.lookup_code(+)
                  AND frlkup.lookup_type(+) = 'FREIGHT_TERMS'
                  AND frlkup.enabled_flag(+) = 'Y'
                  AND h.shipping_method_code = smlkup.lookup_code(+)
                  AND smlkup.LANGUAGE(+) = USERENV ('LANG')
                  AND smlkup.view_application_id(+) = 3
                  AND smlkup.lookup_type(+) = 'SHIP_METHOD'
                  AND h.price_list_id = pl.list_header_id(+)
                  AND pl.LANGUAGE(+) = USERENV ('LANG')
                  AND h.payment_term_id = term1.term_id(+)
                  AND term1.language(+) = USERENV ('LANG')
                  AND TO_CHAR (xxhim.rec_id(+)) = h.attribute8
                  AND NVL (xxhim.active_flag, 'Y') = 'Y'
                  AND NVL (xxhim.end_date, SYSDATE) >= SYSDATE);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_OE_ORDER_LINES_V FOR APPS.XXINTG_OE_ORDER_LINES_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_OE_ORDER_LINES_V FOR APPS.XXINTG_OE_ORDER_LINES_V;