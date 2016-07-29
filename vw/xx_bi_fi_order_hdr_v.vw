DROP VIEW APPS.XX_BI_FI_ORDER_HDR_V;

/* Formatted on 6/6/2016 4:59:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_FI_ORDER_HDR_V
(
   ACCOUNTING_RULE_DURATION,
   AGREEMENT,
   BILL_TO_ADDRESS1,
   BILL_TO_ADDRESS2,
   BILL_TO_ADDRESS3,
   BILL_TO_ADDRESS4,
   BILL_TO_CONTACT,
   BILL_TO_CTY_ST_ZIP_CTRY,
   BILL_TO_CUSTOMER,
   BILL_TO_LOCATION,
   BOOKED_DATE,
   CHANGE_SEQUENCE,
   CHECK_NUMBER,
   CONVERSION_RATE_DATE,
   CONVERSION_TYPE_CODE,
   CREATED_BY_NAME,
   CREDIT_CARD_APPROVAL_CODE,
   CREDIT_CARD_APPROVAL_DATE,
   CREDIT_CARD_CODE,
   CREDIT_CARD_EXPIRATION_DATE,
   CREDIT_CARD_HOLDER_NAME,
   CREDIT_CARD_NUMBER,
   CURRENCY,
   CUSTOMER,
   CUSTOMER_CONTACT,
   CUSTOMER_CONTACT_EMAIL,
   CUSTOMER_CONTACT_PHONE_EXT,
   CUSTOMER_CONTACT_PHONE_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER_PO_NUMBER,
   CUSTOMER_PREFERENCE_SET_CODE,
   DATE_ORDERED,
   DEMAND_CLASS_CODE,
   EXPIRATION_DATE,
   FIRST_ACK_CODE,
   FIRST_ACK_DATE,
   FOB_POINT_CODE,
   FREIGHT_CARRIER_CODE,
   INVOICING_RULE,
   LAST_ACK_CODE,
   LAST_ACK_DATE,
   LAST_UPDATED_BY_NAME,
   ORDER_DATE_TYPE_CODE,
   ORDER_NUMBER,
   ORDER_SOURCE,
   ORDER_TYPE,
   ORIG_SYS_DOCUMENT_REF,
   PACKING_INSTRUCTIONS,
   PAYMENT_TERMS,
   PAYMENT_TYPE_CODE,
   PRICE_LIST,
   PRICE_REQUEST_CODE,
   PRICING_DATE,
   REQUEST_DATE,
   RETURN_REASON_CODE,
   SALESPERSON,
   SHIPPING_INSTRUCTIONS,
   SHIP_FROM_ORG,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_CONTACT,
   SHIP_TO_CTY_ST_ZIP_CTRY,
   SHIP_TO_CUSTOMER,
   SHIP_TO_LOCATION,
   STATUS,
   TAX_EXEMPT_NUMBER,
   UPGRADED_FLAG,
   VERSION_NUMBER,
   DATE_ORDERED_DD,
   DATE_ORDERED_MM,
   DATE_ORDERED_Q,
   DATE_ORDERED_YYYY,
   SALES_CHANNEL,
   TAX_EXEMPTED,
   TAX_EXEMPT_REASON,
   SHIPMENT_PRIORITY,
   FREIGHT_TERMS,
   BOOKED_FLAG,
   CANCELLED_FLAG,
   PARTIAL_SHIPMENTS,
   TAX_POINT,
   OPEN_FLAG,
   SHIPPING_METHOD,
   ORDER_CATEGORY_CODE,
   PAYMENT_AMOUNT,
   LATEST_SCHEDULE_LIMIT,
   EARLIEST_SCHEDULE_LIMIT,
   SHIP_TOLERANCE_BELOW,
   SHIP_TOLERANCE_ABOVE,
   CONVERSION_RATE
)
AS
   SELECT header.accounting_rule_duration,
          agree.NAME AGREEMENT,
          bill_to_addr2.address1 bill_to_address1,
          bill_to_addr2.address2 bill_to_address2,
          bill_to_addr2.address3 bill_to_address3,
          bill_to_addr2.address4 bill_to_address4,
             SUBSTRB (billcont2.person_last_name, 1, 50)
          || DECODE (billcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (billcont2.person_first_name, 1, 50))
          || DECODE (billcont3.title, NULL, NULL, ' ' || billcont3.title)
             BILL_TO_CONTACT,
             DECODE (bill_to_addr2.city,
                     NULL, NULL,
                     bill_to_addr2.city || ', ')
          || DECODE (bill_to_addr2.state,
                     NULL, NULL,
                     bill_to_addr2.state || ', ')
          || DECODE (bill_to_addr2.postal_code,
                     NULL, NULL,
                     bill_to_addr2.postal_code || ', ')
          || DECODE (bill_to_addr2.country,
                     NULL, NULL,
                     bill_to_addr2.country)
             BILL_TO_CTY_ST_ZIP_CTRY,
          SUBSTRB (bill_party.party_name, 1, 50) BILL_TO_CUSTOMER,
          billorg.LOCATION BILL_TO_LOCATION,
          header.booked_date BOOKED_DATE,
          header.change_sequence CHANGE_SEQUENCE,
          header.check_number CHECK_NUMBER,
          header.conversion_rate_date CONVERSION_RATE_DATE,
          header.conversion_type_code CONVERSION_TYPE_CODE,
          user2.user_name CREATED_BY_NAME,
          header.credit_card_approval_code CREDIT_CARD_APPROVAL_CODE,
          header.credit_card_approval_date CREDIT_CARD_APPROVAL_DATE,
          header.credit_card_code CREDIT_CARD_CODE,
          header.credit_card_expiration_date CREDIT_CARD_EXPIRATION_DATE,
          header.credit_card_holder_name CREDIT_CARD_HOLDER_NAME,
          header.credit_card_number CREDIT_CARD_NUMBER,
          header.transactional_curr_code CURRENCY,
          SUBSTRB (party.party_name, 1, 50) CUSTOMER,
             SUBSTRB (soldcont2.person_last_name, 1, 50)
          || DECODE (soldcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (soldcont2.person_first_name, 1, 50))
          || DECODE (soldcont3.title, NULL, NULL, ' ' || soldcont3.title)
             CUSTOMER_CONTACT,
          soldcont6.email_address CUSTOMER_CONTACT_EMAIL,
          soldcont5.phone_extension CUSTOMER_CONTACT_PHONE_EXT,
             DECODE (soldcont5.phone_country_code,
                     NULL, NULL,
                     soldcont5.phone_country_code || ' ')
          || DECODE (soldcont5.phone_area_code,
                     NULL, NULL,
                     soldcont5.phone_area_code || '-')
          || DECODE (soldcont5.phone_number,
                     NULL, NULL,
                     soldcont5.phone_number)
             customer_contact_phone_number,
          cust_acct.account_number CUSTOMER_NUMBER,
          header.cust_po_number CUSTOMER_PO_NUMBER,
          header.customer_preference_set_code CUSTOMER_PREFERENCE_SET_CODE,
          header.ordered_date DATE_ORDERED,
          header.demand_class_code DEMAND_CLASS_CODE,
          header.expiration_date EXPIRATION_DATE,
          header.first_ack_code FIRST_ACK_CODE,
          header.first_ack_date FIRST_ACK_DATE,
          header.fob_point_code FOB_POINT_CODE,
          header.freight_carrier_code FREIGHT_CARRIER_CODE,
          invrule.NAME INVOICING_RULE,
          header.last_ack_code LAST_ACK_CODE,
          header.last_ack_date LAST_ACK_DATE,
          user1.user_name LAST_UPDATED_BY_NAME,
          header.order_date_type_code ORDER_DATE_TYPE_CODE,
          header.order_number ORDER_NUMBER,
          os.NAME ORDER_SOURCE,
          ot.NAME ORDER_TYPE,
          header.orig_sys_document_ref ORIG_SYS_DOCUMENT_REF,
          header.packing_instructions PACKING_INSTRUCTIONS,
          term.NAME PAYMENT_TERMS,
          header.payment_type_code PAYMENT_TYPE_CODE,
          pl.NAME PRICE_LIST,
          header.price_request_code PRICE_REQUEST_CODE,
          header.pricing_date PRICING_DATE,
          header.request_date REQUEST_DATE,
          header.return_reason_code RETURN_REASON_CODE,
          oe_bis_salesperson.get_salesperson_name (header.salesrep_id)
             SALESPERSON,
          header.shipping_instructions SHIPPING_INSTRUCTIONS,
          ship_from_org.organization_code SHIP_FROM_ORG,
          ship_to_addr2.address1 ship_to_address1,
          ship_to_addr2.address2 ship_to_address2,
          ship_to_addr2.address3 ship_to_address3,
          ship_to_addr2.address4 ship_to_address4,
             SUBSTRB (shipcont2.person_last_name, 1, 50)
          || DECODE (shipcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (shipcont2.person_first_name, 1, 50))
          || DECODE (shipcont3.title, NULL, NULL, ' ' || shipcont3.title)
             SHIP_TO_CONTACT,
             DECODE (ship_to_addr2.city,
                     NULL, NULL,
                     ship_to_addr2.city || ', ')
          || DECODE (ship_to_addr2.state,
                     NULL, NULL,
                     ship_to_addr2.state || ', ')
          || DECODE (ship_to_addr2.postal_code,
                     NULL, NULL,
                     ship_to_addr2.postal_code || ', ')
          || DECODE (ship_to_addr2.country,
                     NULL, NULL,
                     ship_to_addr2.country)
             ship_to_cty_st_zip_ctry,
          SUBSTRB (ship_party.party_name, 1, 50) SHIP_TO_CUSTOMER,
          ship_to_org.LOCATION SHIP_TO_LOCATION,
          DECODE (header.flow_status_code,
                  'BOOKED', 'Booked',
                  'CANCELLED', 'Cancelled',
                  'CLOSED', 'Closed',
                  'ENTERED', 'Entered',
                  NULL)
             STATUS,
          header.tax_exempt_number TAX_EXEMPT_NUMBER,
          header.upgraded_flag UPGRADED_FLAG,
          header.version_number VERSION_NUMBER,
          (DECODE (
              header.ordered_date,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (header.ordered_date, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM'))),
          (DECODE (
              header.ordered_date,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (header.ordered_date, 'MM'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              header.ordered_date,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                 TO_CHAR (TRUNC (header.ordered_date, 'Q'), 'MM') || '1900',
                 'MMYYYY'))),
          (DECODE (
              header.ordered_date,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (header.ordered_date, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM'))),
          header.sales_channel_code SALES_CHANNEL,
          DECODE (header.tax_exempt_flag,  'N', 'No',  'Y', 'Yes',  NULL)
             TAX_EXEMPTED,
          DECODE (header.tax_exempt_reason_code,
                  'EDUCATION', 'education',
                  'HOSPITAL', 'hospital',
                  'MANUFACTURER', 'manufacturer',
                  'R10UPGRADE', 'R10UPGRADE',
                  'RESALE', 'resale',
                  'RESEARCH', 'research',
                  NULL)
             TAX_EXEMPT_REASON,
          DECODE (header.shipment_priority_code,
                  'High', 'High Priority',
                  'Standard', 'Standard Priority',
                  NULL)
             SHIPMENT_PRIORITY,
          DECODE (header.freight_terms_code,
                  'COLLECT', 'Collect',
                  'DUECOST', 'Prepay and Add with cost conversion',
                  'Due', 'Prepay and Add',
                  'Paid', 'Prepaid',
                  'TBD', 'To Be Determined',
                  'THIRD_PARTY', 'Third Party Billing',
                  NULL)
             FREIGHT_TERMS,
          DECODE (header.booked_flag,  'N', 'No',  'Y', 'Yes',  NULL)
             BOOKED_FLAG,
          DECODE (header.cancelled_flag,  'N', 'No',  'Y', 'Yes',  NULL)
             CANCELLED_FLAG,
          DECODE (header.partial_shipments_allowed,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL)
             PARTIAL_SHIPMENTS,
          DECODE (header.tax_point_code, 'INVOICE', 'AT INVOICING', NULL)
             TAX_POINT,
          DECODE (header.open_flag,  'N', 'No',  'Y', 'Yes',  NULL) OPEN_FLAG,
          DECODE (header.shipping_method_code,
                  'DEL', 'Delivery',
                  'PS', 'Pick Slip',
                  NULL)
             SHIPPING_METHOD,
          DECODE (header.order_category_code,
                  'MIXED', 'Mixed',
                  'ORDER', 'Order',
                  'RETURN', 'Return',
                  NULL)
             ORDER_CATEGORY_CODE,
          header.payment_amount,
          header.latest_schedule_limit,
          header.earliest_schedule_limit,
          header.ship_tolerance_below,
          header.ship_tolerance_above,
          header.conversion_rate
     FROM mtl_parameters ship_from_org,
          hz_cust_site_uses_all ship_to_org,
          hz_party_sites ship_to_addr1,
          hz_locations ship_to_addr2,
          hz_cust_acct_sites_all ship_to_addr3,
          hz_party_sites bill_to_addr1,
          hz_locations bill_to_addr2,
          hz_cust_acct_sites_all bill_to_addr3,
          hz_cust_site_uses_all billorg,
          hz_parties party,
          hz_cust_accounts cust_acct,
          ra_terms term,
          oe_order_headers_all header,
          hz_cust_account_roles soldcont1,
          hz_parties soldcont2,
          hz_org_contacts soldcont3,
          hz_relationships soldcont4,
          hz_contact_points soldcont5,
          hz_parties soldcont6,
          hz_cust_account_roles shipcont1,
          hz_parties shipcont2,
          hz_org_contacts shipcont3,
          hz_relationships shipcont4,
          hz_cust_account_roles billcont1,
          hz_parties billcont2,
          hz_org_contacts billcont3,
          hz_relationships billcont4,
          fnd_currencies fndcur,
          oe_order_sources os,
          oe_transaction_types_tl ot,
          oe_agreements_tl agree,
          qp_list_headers_tl pl,
          ra_rules invrule,
          hz_parties ship_party,
          hz_cust_accounts ship_cust_acct,
          hz_parties bill_party,
          hz_cust_accounts bill_cust_acct,
          fnd_user user1,
          fnd_user user2
    WHERE     NVL (header.order_source_id, header.source_document_type_id) =
                 os.order_source_id(+)
          AND header.order_type_id = ot.transaction_type_id
          AND ot.LANGUAGE = USERENV ('LANG')
          AND header.agreement_id = agree.agreement_id(+)
          AND agree.LANGUAGE(+) = USERENV ('LANG')
          AND header.price_list_id = pl.list_header_id(+)
          AND pl.LANGUAGE(+) = USERENV ('LANG')
          AND header.invoicing_rule_id = invrule.rule_id(+)
          AND header.payment_term_id = term.term_id(+)
          AND header.transactional_curr_code = fndcur.currency_code
          AND header.sold_to_org_id = cust_acct.cust_account_id(+)
          AND party.party_id(+) = cust_acct.party_id
          AND header.ship_from_org_id = ship_from_org.organization_id(+)
          AND header.ship_to_org_id = ship_to_org.site_use_id(+)
          AND ship_to_org.cust_acct_site_id =
                 ship_to_addr3.cust_acct_site_id(+)
          AND ship_to_addr3.party_site_id = ship_to_addr1.party_site_id(+)
          AND ship_to_addr2.location_id(+) = ship_to_addr1.location_id
          AND header.invoice_to_org_id = billorg.site_use_id(+)
          AND billorg.cust_acct_site_id = bill_to_addr3.cust_acct_site_id(+)
          AND bill_to_addr3.party_site_id = bill_to_addr1.party_site_id(+)
          AND bill_to_addr2.location_id(+) = bill_to_addr1.location_id
          AND header.sold_to_contact_id = soldcont1.cust_account_role_id(+)
          AND soldcont1.party_id = soldcont4.party_id(+)
          AND soldcont1.role_type(+) = 'CONTACT'
          AND soldcont3.party_relationship_id(+) = soldcont4.relationship_id
          AND soldcont4.directional_flag(+) = 'F'
          AND soldcont4.subject_table_name(+) = 'HZ_PARTIES'
          AND soldcont4.object_table_name(+) = 'HZ_PARTIES'
          AND soldcont4.subject_id = soldcont2.party_id(+)
          AND soldcont4.party_id = soldcont6.party_id(+)
          AND soldcont5.owner_table_id(+) = soldcont6.party_id
          AND soldcont5.owner_table_name(+) = 'HZ_PARTIES'
          AND soldcont5.contact_point_type(+) = 'PHONE'
          AND soldcont5.status(+) = 'A'
          AND soldcont5.primary_flag(+) = 'Y'
          AND header.ship_to_contact_id = shipcont1.cust_account_role_id(+)
          AND shipcont1.party_id = shipcont4.party_id(+)
          AND shipcont1.role_type(+) = 'CONTACT'
          AND shipcont3.party_relationship_id(+) = shipcont4.relationship_id
          AND shipcont4.directional_flag(+) = 'F'
          AND shipcont4.subject_table_name(+) = 'HZ_PARTIES'
          AND shipcont4.object_table_name(+) = 'HZ_PARTIES'
          AND shipcont4.subject_id = shipcont2.party_id(+)
          AND header.invoice_to_contact_id =
                 billcont1.cust_account_role_id(+)
          AND billcont1.party_id = billcont4.party_id(+)
          AND billcont1.role_type(+) = 'CONTACT'
          AND billcont3.party_relationship_id(+) = billcont4.relationship_id
          AND billcont4.directional_flag(+) = 'F'
          AND billcont4.subject_table_name(+) = 'HZ_PARTIES'
          AND billcont4.object_table_name(+) = 'HZ_PARTIES'
          AND billcont4.subject_id = billcont2.party_id(+)
          AND ship_to_addr3.cust_account_id =
                 ship_cust_acct.cust_account_id(+)
          AND ship_party.party_id(+) = ship_cust_acct.party_id
          AND bill_to_addr3.cust_account_id =
                 bill_cust_acct.cust_account_id(+)
          AND bill_party.party_id(+) = bill_cust_acct.party_id
          AND header.last_updated_by = user1.user_id(+)
          AND header.created_by = user2.user_id(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_FI_ORDER_HDR_V FOR APPS.XX_BI_FI_ORDER_HDR_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_FI_ORDER_HDR_V FOR APPS.XX_BI_FI_ORDER_HDR_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_FI_ORDER_HDR_V FOR APPS.XX_BI_FI_ORDER_HDR_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_FI_ORDER_HDR_V FOR APPS.XX_BI_FI_ORDER_HDR_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ORDER_HDR_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ORDER_HDR_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_FI_ORDER_HDR_V TO XXINTG;
