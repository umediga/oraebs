DROP VIEW APPS.XXIEX_US_ORDERS_ON_HOLD_V;

/* Formatted on 6/6/2016 5:00:25 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXIEX_US_ORDERS_ON_HOLD_V
(
   HEADER_ID,
   ORG_ID,
   ORDER_NUMBER,
   PARTY_NAME,
   ACCOUNT_NUMBER,
   STATE,
   SHIP_FROM_ORG_ID,
   JDE_ACCOUNT_NUMBER,
   SALES_CHANNEL_CODE,
   SITE_USE_ID,
   OVERALL_CREDIT_LIMIT,
   ORDER_TOTAL,
   PAYMENT_TERMS,
   AR_BALANCE,
   CUST_ACCOUNT_ID,
   ORDER_TYPE,
   OPEN_ORDERS_TOTAL,
   COUNTRY,
   HOLD_AGE,
   PREPAID_HOLD_AGE,
   PARTY_ID,
   OPERATING_UNIT,
   ORDER_CURRENCY,
   SHIP_METHOD_CODE,
   CARREIER_NAME,
   SHIPMENT_PRIORIRY,
   EMERGENCY_SHIPMENT
)
AS
   SELECT oeh.header_id,
          oeh.org_id,
          oeh.order_number,
          xcv.customer_name party_name,
          xcv.customer_number account_number,
          xcv.state,
          NVL (oeh.ship_from_org_id,
               (SELECT MAX (ship_from_org_id)
                  FROM oe_order_lines oel
                 WHERE oeh.header_id = oel.header_id))
             ship_from_org_id,
          xcv.orig_system_reference jde_account_number,
          xcv.sales_channel_code,
          xcv.site_use_id,
          hzp_cust_pkg.arxvamai_overall_cr_limit (
             xcv.cust_account_id,
             oeh.transactional_curr_code,
             NULL)
             overall_credit_limit,
          oe_totals_grp.get_order_total (oeh.header_id, NULL, 'ALL')
             order_total,
          terms.name payment_terms,
          (SELECT SUM (NVL (ps.acctd_amount_due_remaining, 0)) ar_balance
             FROM ar_payment_schedules_all ps,
                  hz_cust_accounts ca,
                  iex_delinquencies_all del,
                  ar_system_parameters_all sp
            WHERE     ps.customer_id = ca.cust_account_id
                  AND ps.status = 'OP'
                  AND del.payment_schedule_id(+) = ps.payment_schedule_id
                  AND ps.org_id = sp.org_id
                  AND ca.cust_account_id = xcv.cust_account_id)
             ar_balance,
          xcv.cust_account_id,
          oet.name order_type,
          (SELECT   (SELECT NVL (
                               SUM (
                                    NVL (l.unit_selling_price, 0)
                                  * NVL (l.ordered_quantity, 0)
                                  * NVL (h.conversion_rate, 1)),
                               0)
                               l_total1_credit
                       FROM oe_order_lines_all l,
                            oe_order_headers_all h,
                            hz_cust_site_uses_all su,
                            hz_party_sites party_site,
                            hz_locations loc,
                            hz_cust_acct_sites_all acct_site
                      WHERE     h.invoice_to_org_id = su.site_use_id
                            AND acct_site.cust_account_id =
                                   xcv.cust_account_id
                            AND acct_site.cust_acct_site_id =
                                   su.cust_acct_site_id
                            AND acct_site.party_site_id =
                                   party_site.party_site_id
                            AND loc.location_id = party_site.location_id
                            AND l.header_id = h.header_id
                            AND l.line_category_code = 'ORDER'
                            AND l.booked_flag = 'Y'
                            AND l.cancelled_flag = 'N'
                            AND h.cancelled_flag = 'N'
                            AND NVL (l.invoice_interface_status_code, 'X') NOT IN
                                   ('PARTIAL', 'YES'))
                  + (SELECT NVL (
                               SUM (
                                    NVL (l.unit_selling_price, 0)
                                  * (  NVL (l.ordered_quantity, 0)
                                     - NVL (l.shipped_quantity, 0))
                                  * NVL (h.conversion_rate, 1)),
                               0)
                               l_total3_credit
                       FROM oe_order_lines_all l,
                            oe_order_headers_all h,
                            hz_cust_site_uses_all su,
                            hz_party_sites party_site,
                            hz_locations loc,
                            hz_cust_acct_sites_all acct_site
                      WHERE     acct_site.cust_account_id =
                                   xcv.cust_account_id
                            AND acct_site.cust_acct_site_id =
                                   su.cust_acct_site_id
                            AND acct_site.party_site_id =
                                   party_site.party_site_id
                            AND loc.location_id = party_site.location_id
                            AND su.site_use_id = h.invoice_to_org_id
                            AND l.header_id = h.header_id
                            AND l.line_category_code = 'ORDER'
                            AND l.invoice_interface_status_code = 'PARTIAL'
                            AND l.booked_flag = 'Y'
                            AND l.cancelled_flag = 'N'
                            AND h.cancelled_flag = 'N')
                     open_orders_total
             FROM DUAL)
             open_orders_total,
          xcv.country,
          (SELECT DISTINCT TRUNC (SYSDATE) - TRUNC (MIN (hold.creation_date))
             FROM oe_order_holds_all hold, oe_hold_sources_all ohs
            WHERE     oeh.header_id = hold.header_id
                  AND hold.hold_source_id = ohs.hold_source_id
                  AND ohs.hold_id = 1
                  AND hold.released_flag = 'N')
             hold_age,
          (SELECT DISTINCT TRUNC (SYSDATE) - TRUNC (MIN (hold.creation_date))
             FROM oe_order_holds_all hold, oe_hold_sources_all ohs
            WHERE     oeh.header_id = hold.header_id
                  AND hold.hold_source_id = ohs.hold_source_id
                  AND ohs.hold_id = (SELECT hold_id
                                       FROM oe_hold_definitions
                                      WHERE name = 'Pre-Pay Order Hold')
                  AND hold.released_flag = 'N')
             prepaid_hold_age,
          xcv.party_id,
          hu.name,
          oeh.transactional_curr_code,
          (SELECT meaning
             FROM oe_ship_methods_v mth
            WHERE     mth.lookup_type = 'SHIP_METHOD'
                  AND mth.lookup_code = oeh.shipping_method_code)
             ship_method_code,
          (SELECT carrier_name
             FROM wsh_carriers_v wsc
            WHERE wsc.freight_code = oeh.freight_carrier_code)
             carrier_name,
          (SELECT meaning
             FROM oe_lookups lk
            WHERE     lk.lookup_type = 'SHIPMENT_PRIORITY'
                  AND lk.lookup_code = oeh.shipment_priority_code)
             shipment_priority,
          (SELECT CASE
                     WHEN COUNT (DISTINCT oel.inventory_item_id) > 0 THEN 'Y'
                     ELSE 'N'
                  END
             FROM oe_order_lines_all oel,
                  fnd_lookup_values_vl flv,
                  mtl_system_items_b msi
            WHERE     flv.lookup_type = 'XXINTG_ITEMS_CREDIT_CHK'
                  AND oel.header_id = oeh.header_Id
                  AND oel.inventory_item_id = msi.inventory_item_id
                  AND msi.organization_id = 83
                  AND msi.segment1 = flv.lookup_code
                  AND TRUNC (SYSDATE) BETWEEN TRUNC (
                                                 NVL (flv.start_date_active,
                                                      SYSDATE))
                                          AND TRUNC (
                                                 NVL (flv.end_date_active,
                                                      SYSDATE + 1))
                  AND flv.enabled_flag = 'Y')
             emergency_shipments
     FROM oe_order_headers_all oeh,
          xxintg_customers_v xcv,
          oe_ra_terms_v terms,
          oe_transaction_types_tl oet,
          oe_transaction_types_all oetl,
          hr_operating_units hu
    WHERE     EXISTS
                 (SELECT 1
                    FROM oe_order_holds_all hld, oe_hold_sources_all ohs
                   WHERE     hld.header_id = oeh.header_id
                         AND hld.hold_source_id = ohs.hold_source_id
                         AND ohs.hold_id IN
                                (SELECT hold_id
                                   FROM apps.oe_hold_definitions
                                  WHERE name IN
                                           ('Credit Check Failure',
                                            'Pre-Pay Order Hold'))
                         AND hld.released_flag = 'N')
          AND oeh.invoice_to_org_id = xcv.site_use_id
          AND xcv.site_use_code = 'BILL_TO'
          AND oeh.payment_term_id = terms.term_id(+)
          AND oeh.cancelled_flag = 'N'
          AND oeh.order_type_id = oet.transaction_type_id
          AND oet.transaction_type_id = oetl.transaction_type_id
          AND oet.language = USERENV ('LANG')
          AND hu.organization_id = oeh.org_id
          AND oeh.org_id IN (SELECT organization_id
                               FROM mo_glob_org_access_tmp);


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXIEX_US_ORDERS_ON_HOLD_V FOR APPS.XXIEX_US_ORDERS_ON_HOLD_V;


GRANT SELECT ON APPS.XXIEX_US_ORDERS_ON_HOLD_V TO XXAPPSREAD;
