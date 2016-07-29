DROP VIEW APPS.XX_AR_INVOICE_HEADERS_WS_V;

/* Formatted on 6/6/2016 5:00:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_AR_INVOICE_HEADERS_WS_V
(
   PUBLISH_BATCH_ID,
   DOCUMENT_TYPE,
   INVOICE_NAME,
   TRANSACTION_DATE,
   BILL_TO_CUSTOMER_CODE_INT,
   BILL_TO_CUSTOMER_NAME,
   BILL_TO_ADDRESS1,
   BILL_TO_ADDRESS2,
   BILL_TO_ADDRESS3,
   BILL_TO_ADDRESS4,
   BILL_TO_CITY,
   BILL_TO_POSTAL_CODE,
   BILL_TO_COUNTRY,
   BILL_TO_STATE,
   BILL_TO_PROVINCE,
   BILL_TO_COUNTY,
   BILL_TO_CUSTOMER_SIC_CODE,
   BILL_TO_CUSTOMER_SALES_CHANNEL,
   SITE_USE_CODE,
   SHIP_TO_CUSTOMER_CODE_INT,
   SHIP_TO_CUSTOMER_NAME,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_CITY,
   SHIP_TO_POSTAL_CODE,
   SHIP_TO_COUNTRY,
   SHIP_TO_STATE,
   SHIP_TO_PROVINCE,
   SHIP_TO_COUNTY,
   SHIP_TO_CUSTOMER_SIC_CODE,
   SHIP_TO_CUSTOMER_SALES_CHANNEL,
   SOLD_TO_CUSTOMER_CODE_INT,
   SOLD_TO_CUSTOMER_NAME,
   SOLD_TO_ADDRESS1,
   SOLD_TO_ADDRESS2,
   SOLD_TO_ADDRESS3,
   SOLD_TO_ADDRESS4,
   SOLD_TO_CITY,
   SOLD_TO_POSTAL_CODE,
   SOLD_TO_COUNTRY,
   SOLD_TO_STATE,
   SOLD_TO_PROVINCE,
   SOLD_TO_COUNTY,
   SOLD_TO_CUSTOMER_SIC_CODE,
   SOLD_TO_CUSTOMER_SALES_CHANNEL,
   TRANSACTION_NUMBER,
   CREDITED_INVOICE_NUMBER,
   REFERENCE_INVOICE_NUMBER,
   PARENT_INVOICE_NUMBER,
   SHIPMENT_DATE,
   PURCHASE_ORDER_NUMBER,
   CREATION_DATE,
   PURCHASE_ORDER_REVISION_NUMBER,
   COMMITMENT_START_DATE,
   PURCHASE_ORDER_DATE,
   COMMITMENT_END_DATE,
   INV_TRANSACTION_DATE,
   LAST_UPDATE_DATE,
   CREDIT_MEMO_REASON,
   TRANSMISSION_LEAD_DAYS,
   TRANSACTION_SOURCE,
   INSTALLMENT_NUMBER,
   SHIPMENT_WAYBILL_NUMBER,
   SHIP_VIA,
   SHIPMENT_FOB_POINT,
   CURRENCY_CODE,
   CURRENCY_EXCHANGE_RATE,
   PAYMENT_TERM_NAME,
   PRIMARY_SALESREP_NAME,
   COMMENTS,
   BILL_TO_ADDRESS_ID,
   BILL_TO_CUSTOMER_LOCATION,
   BILL_TO_CUSTOMER_NUMBER,
   SHIP_TO_ADDRESS_ID,
   SHIP_TO_CUSTOMER_LOCATION,
   SHIP_TO_CUSTOMER_NUMBER,
   SOLD_TO_ADDRESS_ID,
   SOLD_TO_CUSTOMER_LOCATION,
   SOLD_TO_CUSTOMER_NUMBER,
   CUSTOMER_TRX_ID,
   PAYMENT_TERM_ID,
   BILL_TO_CUSTOMER_ID,
   BILL_TO_SITE_USE_ID,
   SHIP_TO_CUSTOMER_ID,
   SHIP_TO_SITE_USE_ID,
   SOLD_TO_CUSTOMER_ID,
   SOLD_TO_SITE_USE_ID,
   TERM_DUE_CUTOFF_DAY,
   TERM_DUE_DATE,
   TERM_DUE_DAYS,
   TERM_DUE_DAY_OF_MONTH,
   TERM_DUE_MONTHS_FORWARD,
   TERM_DUE_PERCENT,
   TOTAL_AMOUNT_DUE,
   DISCOUNTED_AMOUNT,
   AMOUNT_TAX_DUE,
   AMOUNT_FREIGHT_DUE,
   AMOUNT_LINE_ITEMS_DUE,
   RECEIVABLES_CHARGES_REMAINING,
   BILL_OF_LADING_NUMBER,
   SHIPMENT_NUMBER,
   ATTRIBUTE_CATEGORY,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15,
   INTERFACE_HEADER_CONTEXT,
   INTERFACE_HEADER_ATTRIBUTE1,
   INTERFACE_HEADER_ATTRIBUTE2,
   INTERFACE_HEADER_ATTRIBUTE3,
   INTERFACE_HEADER_ATTRIBUTE4,
   INTERFACE_HEADER_ATTRIBUTE5,
   INTERFACE_HEADER_ATTRIBUTE6,
   INTERFACE_HEADER_ATTRIBUTE7,
   INTERFACE_HEADER_ATTRIBUTE8,
   INTERFACE_HEADER_ATTRIBUTE9,
   INTERFACE_HEADER_ATTRIBUTE10,
   INTERFACE_HEADER_ATTRIBUTE11,
   INTERFACE_HEADER_ATTRIBUTE12,
   INTERFACE_HEADER_ATTRIBUTE13,
   INTERFACE_HEADER_ATTRIBUTE14,
   INTERFACE_HEADER_ATTRIBUTE15,
   TOTAL_LINES_COUNT,
   TOTAL_LINES_AMOUNT,
   REQUEST_ID,
   REMIT_TO_ADDRESS1,
   REMIT_TO_ADDRESS2,
   REMIT_TO_CITY,
   REMIT_TO_STATE,
   REMIT_TO_POSTAL_CODE,
   REMIT_TO_COUNTRY,
   TERMS_TYPE_CODE,
   TERMS_DISCOUNT_PERCENT,
   TERMS_DISCOUNT_DUE_DATE,
   TERMS_DISCOUNT_DAYS,
   TERMS_NET_DAYS,
   TERMS_DISCOUNT_AMOUNT,
   ORDER_HEADER_ID,
   FREIGHT_TERMS_CODE,
   FOB_POINT_CODE,
   FOB_POINT_MEANING,
   AR_NOTES,
   TRANSLATED_CUSTOMER_NAME,
   EDI_LOCATION_CODE,
   TRACKING_NUMBER,
   TERM_DESCRIPTION,
   REMIT_TO_ACCOUNT_NUMBER,
   REMIT_TO_ACCOUNT_NAME,
   VENDOR_ID,
   FREIGHT_ORIGINAL,
   MODE_OF_TRANSPORT,
   SHIP_METHOD_MEANING,
   FREIGHT_CARRIER_CODE,
   BILL_TO_EDI_LOCATION_CODE,
   DELIVER_TO_ORG_ID,
   DELIVER_TO_CUSTOMER_NAME,
   DELIVER_TO_ADDRESS1,
   DELIVER_TO_ADDRESS2,
   DELIVER_TO_CITY,
   DELIVER_TO_STATE,
   DELIVER_TO_POSTAL_CODE,
   DELIVER_TO_COUNTRY,
   WAREHOUSE_NAME,
   WAREHOUSE_ADDRESS1,
   WAREHOUSE_ADDRESS2,
   WAREHOUSE_ADDRESS3,
   WAREHOUSE_CITY,
   WAREHOUSE_POSTAL_CODE,
   WAREHOUSE_COUNTRY,
   WAREHOUSE_COUNTY,
   WAREHOUSE_STATE,
   DELIVERY_ID,
   ADDITIONAL_ATTRIBUTE1,
   ADDITIONAL_ATTRIBUTE2,
   ADDITIONAL_ATTRIBUTE3,
   ADDITIONAL_ATTRIBUTE4,
   ADDITIONAL_ATTRIBUTE5,
   ADDITIONAL_ATTRIBUTE6,
   ADDITIONAL_ATTRIBUTE7,
   ADDITIONAL_ATTRIBUTE8,
   ADDITIONAL_ATTRIBUTE9,
   ADDITIONAL_ATTRIBUTE10,
   ORDER_SOURCE
)
AS
   SELECT DISTINCT
          NULL publish_batch_id,
          rctt.TYPE document_type,
          rctt.NAME invoice_name,
          SYSDATE transaction_date,
          ra1.orig_system_reference bill_to_customer_code_int,
          SUBSTR (hp1.party_name, 1, 50) bill_to_customer_name,
          loc1.address1 bill_to_address1,
          loc1.address2 bill_to_address2,
          loc1.address3 bill_to_address3,
          loc1.address4 bill_to_address4,
          loc1.city bill_to_city,
          loc1.postal_code bill_to_postal_code,
          loc1.country bill_to_country,
          --  loc1.state bill_to_state,
          NVL (loc1.state, loc1.province) bill_to_state,
          loc1.province bill_to_province,
          loc1.county bill_to_county,
          DECODE (hp1.party_type, 'ORGANIZATION', hp1.sic_code, NULL)
             bill_to_customer_sic_code,
          rc1.sales_channel_code bill_to_customer_sales_channel,
          rsu1.site_use_code site_use_code,
          ra2.orig_system_reference ship_to_customer_code_int,
          SUBSTR (hp2.party_name, 1, 50) ship_to_customer_name,
          loc2.address1 ship_to_address1,
          loc2.address2 ship_to_address2,
          loc2.address3 ship_to_address3,
          loc2.address4 ship_to_address4,
          loc2.city ship_to_city,
          loc2.postal_code ship_to_postal_code,
          loc2.country ship_to_country,
          --  loc2.state ship_to_state,
          NVL (loc2.state, loc2.province) ship_to_state,
          loc2.province ship_to_province,
          loc2.county ship_to_county,
          DECODE (hp2.party_type, 'ORGANIZATION', hp2.sic_code, NULL)
             ship_to_customer_sic_code,
          rc2.sales_channel_code ship_to_customer_sales_channel,
          ra3.orig_system_reference sold_to_customer_code_int,
          SUBSTR (hp3.party_name, 1, 50) sold_to_customer_name,
          loc3.address1 sold_to_address1,
          loc3.address2 sold_to_address2,
          loc3.address3 sold_to_address3,
          loc3.address4 sold_to_address4,
          loc3.city sold_to_city,
          loc3.postal_code sold_to_postal_code,
          loc3.country sold_to_country,
          -- loc3.state sold_to_state,
          NVL (loc3.state, loc3.province) sold_to_state,
          loc3.province sold_to_province,
          loc3.county sold_to_county,
          DECODE (hp3.party_type, 'ORGANIZATION', hp3.sic_code, NULL)
             sold_to_customer_sic_code,
          rc3.sales_channel_code sold_to_customer_sales_channel,
          rct1.trx_number transaction_number,
          rct2.trx_number credited_invoice_number,
          rct4.trx_number reference_invoice_number,
          rct3.trx_number parent_invoice_number,
          rct1.ship_date_actual shipment_date,
          rct1.purchase_order purchase_order_number,
          rct1.creation_date creation_date,
          rct1.purchase_order_revision purchase_order_revision_number,
          rct1.start_date_commitment commitment_start_date,
          NVL (rct1.purchase_order_date, rct1.trx_date) purchase_order_date,
          rct1.end_date_commitment commitment_end_date,
          rct1.trx_date inv_transaction_date,
          rct1.last_update_date last_update_date,
          rct1.reason_code credit_memo_reason,
          rb.printing_lead_days transmission_lead_days,
          ABS.NAME transaction_source,
          NVL (rtl.sequence_num, 1) installment_number,
          rct1.waybill_number shipment_waybill_number,
          rct1.ship_via ship_via,
          rct1.fob_point shipment_fob_point,
          rct1.invoice_currency_code currency_code,
          rct1.exchange_rate currency_exchange_rate,
          rt.NAME payment_term_name,
          --DECODE (rs.salesrep_id,-3, NULL,-2, NULL,-1, NULL,rs.NAME) primary_salesrep_name,
          NULL primary_salesrep_name,
          rct1.internal_notes comments,
          ra1.cust_acct_site_id bill_to_address_id,
          rsu1.LOCATION bill_to_customer_location,
          rc1.account_number bill_to_customer_number,
          ra2.cust_acct_site_id ship_to_address_id,
          rsu2.LOCATION ship_to_customer_location,
          rc2.account_number ship_to_customer_number,
          ra3.cust_acct_site_id sold_to_address_id,
          rsu3.LOCATION sold_to_customer_location,
          rc3.account_number sold_to_customer_number,
          rct1.customer_trx_id customer_trx_id,
          rb.term_id payment_term_id,
          rct1.bill_to_customer_id bill_to_customer_id,
          rct1.bill_to_site_use_id bill_to_site_use_id,
          rct1.ship_to_customer_id ship_to_customer_id,
          rct1.ship_to_site_use_id ship_to_site_use_id,
          rct1.sold_to_customer_id sold_to_customer_id,
          rct1.sold_to_site_use_id sold_to_site_use_id,
          rb.due_cutoff_day term_due_cutoff_day,
          -- NVL (rct1.term_due_date, aps.due_date) term_due_date,
          aps.due_date term_due_date,
          rtl.due_days term_due_days,
          rtl.due_day_of_month term_due_day_of_month,
          rtl.due_months_forward term_due_months_forward,
          (NVL (rtl.relative_amount, 0) / NVL (rb.base_amount, 1)) * 100
             term_due_percent,
          aps.amount_due_original total_amount_due,
          NVL (
             (  aps.amount_due_remaining
              - (  (rtld.discount_percent / 100)
                 * aps.amount_line_items_remaining)),
             0)
             discounted_amount,
          aps.tax_original amount_tax_due,
          aps.freight_remaining amount_freight_due,
          aps.amount_line_items_original amount_line_items_due,
          aps.receivables_charges_remaining receiveables_charges_remaining,
          NVL (rct1.interface_header_attribute8, NULL) bill_of_lading_number,
          NVL (rct1.interface_header_attribute12, 0) shipment_number,
          rct1.attribute_category,
          rct1.attribute1,
          rct1.attribute2,
          rct1.attribute3,
          rct1.attribute4,
          rct1.attribute5,
          rct1.attribute6,
          rct1.attribute7,
          rct1.attribute8,
          rct1.attribute9,
          rct1.attribute10,
          rct1.attribute11,
          rct1.attribute12,
          rct1.attribute13,
          rct1.attribute14,
          rct1.attribute15,
          rct1.interface_header_context,
          rct1.interface_header_attribute1,
          rct1.interface_header_attribute2,
          rct1.interface_header_attribute3,
          rct1.interface_header_attribute4,
          rct1.interface_header_attribute5,
          rct1.interface_header_attribute6,
          rct1.interface_header_attribute7,
          rct1.interface_header_attribute8,
          rct1.interface_header_attribute9,
          rct1.interface_header_attribute10,
          rct1.interface_header_attribute11,
          rct1.interface_header_attribute12,
          rct1.interface_header_attribute13,
          rct1.interface_header_attribute14,
          rct1.interface_header_attribute15,
          (SELECT COUNT (*)
             FROM apps.xx_ar_invoice_lines_ws_v
            WHERE customer_trx_id = rct1.customer_trx_id)
             total_lines_count,
          (SELECT SUM (quantity_invoiced)
             FROM apps.xx_ar_invoice_lines_ws_v
            WHERE customer_trx_id = rct1.customer_trx_id)
             total_lines_amount,
          rct1.request_id,
          loc4.address1 remit_to_address1,
          loc4.address2 remit_to_address2,
          loc4.city remit_to_city,
          --  loc4.state remit_to_state,
          NVL (loc4.state, loc4.province) remit_to_state,
          loc4.postal_code remit_to_postal_code,
          loc4.country remit_to_country,
          DECODE ( (SELECT COUNT (*)
                      FROM ra_terms_lines_discounts
                     WHERE term_id = rct1.term_id),
                  0, '05',
                  '08')
             terms_type_code,                               --discount_exists,
          rtld.discount_percent terms_discount_percent,
          (rct1.trx_date + NVL (rtld.discount_days, 0))
             terms_discount_due_date, -- Modified as per Mikes Logic on 18Oct2012
          NVL (rtld.discount_days, 0) terms_discount_days,
          -- to_char( NVL (rct1.term_due_date, aps.due_date),'DD') terms_net_days,
          -- round(nvl((aps.due_date - sysdate),0)) terms_net_days,
          rtl.due_days terms_net_days,
          ( (rtld.discount_percent / 100) * aps.amount_line_items_remaining)
             terms_discount_amount,
          ooha.header_id order_header_id,
          ooha.freight_terms_code freight_terms_code,
          ooha.fob_point_code fob_point_code,
          al.meaning fob_point_meaning,
          (SELECT SUBSTR (an1.text, 1, 80)
             FROM ar_notes an1
            WHERE     an1.customer_trx_id = rct1.customer_trx_id
                  AND ROWNUM =
                         (SELECT MAX (ROWNUM)
                            FROM ar_notes an2
                           WHERE     an1.customer_trx_id =
                                        an2.customer_trx_id
                                 AND last_update_date =
                                        (SELECT MAX (last_update_date)
                                           FROM ar_notes an2
                                          WHERE an1.customer_trx_id =
                                                   an2.customer_trx_id)))
             ar_notes,
          isa.translated_customer_name translated_customer_name -- , ra2.ece_tp_location_code edi_location_code,
                                                               ,
          ra2.attribute5 edi_location_code,
          wvd.tracking_number tracking_number,
          rt.description term_description,
          (SELECT tag
             FROM fnd_lookup_values
            WHERE     lookup_type = 'INTG_810_N104'
                  AND lookup_code = isa.translated_customer_name
                  AND LANGUAGE = 'US')
             remit_to_account_number,
          'INTEGRA LIFESCIENCES' remit_to_account_name,
          (SELECT tag
             FROM fnd_lookup_values
            WHERE     lookup_type = 'INTG_810_REF02'
                  AND lookup_code = isa.translated_customer_name
                  AND LANGUAGE = 'US')
             vendor_id,
          aps.freight_original freight_original,
          wcs.mode_of_transport mode_of_transport,
          wcs.ship_method_meaning ship_method_meaning,
          wcv.scac_code freight_carrier_code,
          --    ra1.ece_tp_location_code bill_to_edi_location_code
          ra1.attribute5 bill_to_edi_location_code,
          delivery_addr.deliver_to_org_id deliver_to_org_id,
          delivery_addr.delivery_party deliver_to_customer_name,
          delivery_addr.address1 deliver_to_address1,
          delivery_addr.address2 deliver_to_address2,
          delivery_addr.city deliver_to_city,
          delivery_addr.state deliver_to_state,
          delivery_addr.postal_code deliver_to_postal_code,
          delivery_addr.country deliver_to_country,
          warehouse.warehouse_name,
          warehouse.warehouse_address1,
          warehouse.warehouse_address2,
          warehouse.warehouse_address3,
          warehouse.warehouse_city,
          warehouse.warehouse_postal_code,
          warehouse.warehouse_country,
          warehouse.warehouse_county,
          warehouse.warehouse_state,
          warehouse.delivery_id,
          ooha.orig_sys_document_ref additional_attribute1 -- Orig Sys reference from Order for GHX / End Cust PO#
                                                          ,
          ooha.tp_attribute8 additional_attribute2    -- Vendor Number for GHX
                                                  ,
          ooha.tp_attribute7 additional_attribute3   -- Release Number for GHX
                                                  ,
          NULL additional_attribute4,
          NULL additional_attribute5,
          NULL additional_attribute6,
          NULL additional_attribute7,
          NULL additional_attribute8,
          NULL additional_attribute9,
          NULL additional_attribute10 --, DECODE(oos.name, 'EDIGHX', 'EDIGHX', 'EDIGXS', 'EDIGXS', DECODE(isa.ghx_edi_enabled,'NOEDI', 'NOEDI', 'EDIGHX')) order_source  -- Added for GHX
  --, DECODE(isa.ghx_edi_enabled,'NOEDI', 'NOEDIORGXS', 'EDIGHX') order_source
          ,
          oos.name order_source
     FROM ra_cust_trx_types_all rctt,
          hz_cust_acct_sites_all ra1,
          hz_cust_accounts rc1,
          ra_customer_trx_all rct1,
          ra_batch_sources_all ABS,
          ar_payment_schedules_all aps,
          hz_cust_site_uses_all rsu1,
          hz_cust_site_uses_all rsu2,
          hz_cust_site_uses_all rsu3,
          ra_customer_trx_all rct4,
          ra_customer_trx_all rct3,
          ra_customer_trx_all rct2,
          ra_terms_b rb,
          ra_terms_tl rt,
          ra_terms_lines rtl,
          hz_parties hp1,
          hz_parties hp2,
          hz_cust_acct_sites_all ra2,
          hz_cust_accounts rc2,
          hz_cust_acct_sites_all ra3,
          hz_parties hp3,
          hz_cust_accounts rc3,
          hz_party_sites hps1,
          hz_locations loc1,
          hz_party_sites hps2,
          hz_locations loc2,
          hz_party_sites hps3,
          hz_locations loc3,
          hz_cust_acct_sites_all ra4,
          hz_party_sites hps4,
          hz_locations loc4,
          ra_terms_lines_discounts rtld,
          oe_order_headers_all ooha,
          oe_order_sources oos                                -- Added for GHX
                              ,
          ar_lookups al,
          wsh_delivery_details_oe_v wvd,
          wsh_carrier_services wcs,
          wsh_carriers_v wcv,
          (SELECT ras.attribute4 translated_customer_name,
                  rcts.customer_trx_id,
                  NVL (ras.attribute7, 'NOEDI') ghx_edi_enabled
             --    (SELECT ras.translated_customer_name, rcts.customer_trx_id
             FROM hz_cust_acct_sites_all ras,
                  hz_cust_site_uses_all rsus,
                  ra_customer_trx_all rcts,
                  hz_cust_accounts rcs
            WHERE     1 = 1 -- For converted invoices we are not having sold_to_customer_id in table
                  -- rcts.sold_to_customer_id = rcs.cust_account_id
                  AND rsus.cust_acct_site_id = ras.cust_acct_site_id
                  --                         AND rcts.customer_trx_id = rct1.customer_trx_id
                  AND rcts.ship_to_site_use_id = rsus.site_use_id
                  AND rcs.cust_account_id = ras.cust_account_id
                  AND ras.attribute4 IS NOT NULL) isa --                 and ras.translated_customer_name is not null) isa
                                                     ,
          (SELECT loc.country,
                  loc.postal_code,
                  loc.state,
                  loc.city,
                  loc.address2,
                  loc.address1,
                  NVL (
                     (SELECT hp1.party_name
                        FROM hz_parties hp1,
                             hz_party_sites hps,
                             hz_party_relationship_v hpr
                       WHERE     hp1.party_id = hps.party_id
                             AND hp1.party_type = 'PERSON'
                             AND hps.location_id = loc.location_id
                             AND hpr.object_id = hp.party_id
                             AND hpr.subject_id = hp1.party_id
                             AND hpr.relationship_type_code = 'CONTACT_OF'
                             AND hpr.subject_party_type = 'PERSON'
                             AND ROWNUM < 2) -- Added to restrict data when there is duplicate Contact Persons
                                            ,
                     SUBSTR (hp.party_name, 1, 50))
                     delivery_party,
                  hcsu.site_use_id deliver_to_org_id
             FROM hz_locations loc,
                  hz_cust_site_uses_all hcsu,
                  hz_cust_acct_sites_all hcas,
                  hz_party_sites hps,
                  hz_parties hp,
                  hz_cust_acct_sites_all ra1,
                  hz_cust_accounts rc1
            WHERE     loc.location_id = hps.location_id
                  AND hcas.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND hcas.party_site_id = hps.party_site_id
                  AND hp.party_id = rc1.party_id
                  AND ra1.cust_acct_site_id = hcsu.cust_acct_site_id
                  AND rc1.cust_account_id = ra1.cust_account_id
                  AND ra1.party_site_id = hps.party_site_id) delivery_addr,
          (SELECT DISTINCT ool.deliver_to_org_id, ool.header_id
             FROM oe_order_lines_all ool) del_org_id,
          (SELECT SUBSTR (hou.NAME, 1, INSTR (hou.NAME, ',') - 1)
                     warehouse_name,
                  wshl.address1 warehouse_address1,
                  wshl.address2 warehouse_address2,
                  wshl.address3 warehouse_address3,
                  wshl.city warehouse_city,
                  wshl.postal_code warehouse_postal_code,
                  wshl.country warehouse_country,
                  wshl.county warehouse_county,
                  wshl.state warehouse_state,
                  wnd.delivery_id delivery_id
             FROM wsh_locations wshl,
                  wsh_new_deliveries wnd,
                  hr_organization_units hou
            WHERE     wnd.initial_pickup_location_id = wshl.wsh_location_id
                  AND wshl.location_source_code = 'HR'
                  AND hou.organization_id = wnd.organization_id) warehouse
    WHERE     ra1.party_site_id = hps1.party_site_id
          AND hps1.location_id = loc1.location_id
          AND rc1.cust_account_id = ra1.cust_account_id
          AND hp1.party_id = rc1.party_id
          AND rsu1.cust_acct_site_id = ra1.cust_acct_site_id
          AND rct1.bill_to_customer_id = rc1.cust_account_id
          AND rct1.cust_trx_type_id = rctt.cust_trx_type_id
          AND rct1.complete_flag = 'Y'
          --AND rct1.printing_pending = 'Y'
          --AND rct1.printing_option = 'PRI'
          AND rct1.bill_to_site_use_id = rsu1.site_use_id
          AND rct1.ship_to_customer_id = rc2.cust_account_id(+)
          AND rc2.party_id = hp2.party_id(+)
          AND rct1.ship_to_site_use_id = rsu2.site_use_id(+)
          AND rsu2.cust_acct_site_id = ra2.cust_acct_site_id(+)
          AND ra2.party_site_id = hps2.party_site_id(+)
          AND hps2.location_id = loc2.location_id(+)
          AND rct1.sold_to_customer_id = rc3.cust_account_id(+)
          AND rc3.party_id = hp3.party_id(+)
          AND rct1.sold_to_site_use_id = rsu3.site_use_id(+)
          AND rsu3.cust_acct_site_id = ra3.cust_acct_site_id(+)
          AND ra3.party_site_id = hps3.party_site_id(+)
          AND hps3.location_id = loc3.location_id(+)
          AND rct1.previous_customer_trx_id = rct2.customer_trx_id(+)
          AND rct1.initial_customer_trx_id = rct3.customer_trx_id(+)
          AND rct1.related_customer_trx_id = rct4.customer_trx_id(+)
          AND rct1.term_id = rb.term_id(+)
          AND rt.term_id(+) = rb.term_id
          AND rt.LANGUAGE(+) = USERENV ('LANG')
          AND rb.term_id = rtl.term_id(+)
          AND rct1.batch_source_id = ABS.batch_source_id(+)
          --AND NVL (rct1.last_printed_sequence_num, 0) < NVL (rtl.sequence_num, 1)
          AND rct1.customer_trx_id = aps.customer_trx_id(+)
          AND NVL (aps.terms_sequence_number, NVL (rtl.sequence_num, 0)) =
                 NVL (rtl.sequence_num, NVL (aps.terms_sequence_number, 0))
          AND NVL (rtl.sequence_num, 0) = (SELECT NVL (MIN (sequence_num), 0)
                                             FROM ra_terms_lines rtl1
                                            WHERE rtl1.term_id = rtl.term_id)
          AND rctt.org_id = rct1.org_id
          AND ABS.org_id = rct1.org_id
          AND rct1.remit_to_address_id = ra4.cust_acct_site_id(+)
          AND ra4.party_site_id = hps4.party_site_id(+)
          AND hps4.location_id = loc4.location_id(+)
          AND rct1.term_id = rtld.term_id(+)
          AND ooha.header_id(+) =
                 xx_ar_invoice_outbound_ws_pkg.get_order_header_id (
                    rct1.customer_trx_id)
          AND del_org_id.header_id(+) =
                 xx_ar_invoice_outbound_ws_pkg.get_order_header_id (
                    rct1.customer_trx_id)
          AND delivery_addr.deliver_to_org_id(+) =
                 del_org_id.deliver_to_org_id
          AND 'FOB' = al.lookup_type(+)
          AND ooha.fob_point_code = al.lookup_code(+)
          AND wvd.source_header_id(+) = ooha.header_id
          AND (   (    wvd.delivery_id =
                          (SELECT MAX (delivery_id)
                             FROM wsh_delivery_details_oe_v
                            WHERE source_header_id = wvd.source_header_id)
                   AND wvd.delivery_id IS NOT NULL)
               OR (wvd.delivery_id IS NULL AND 1 = 1))
          AND warehouse.delivery_id(+) = wvd.delivery_id
          AND ooha.shipping_method_code = wcs.ship_method_code(+)
          AND wcs.carrier_id = wcv.carrier_id(+)
          AND rct1.customer_trx_id = isa.customer_trx_id(+)
          AND ooha.order_source_id = oos.order_source_id(+)   -- Added for GHX
          AND oos.enabled_flag(+) = 'Y';


GRANT SELECT ON APPS.XX_AR_INVOICE_HEADERS_WS_V TO XXAPPSREAD;
