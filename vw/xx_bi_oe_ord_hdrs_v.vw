DROP VIEW APPS.XX_BI_OE_ORD_HDRS_V;

/* Formatted on 6/6/2016 4:59:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_ORD_HDRS_V
(
   ORDER_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER,
   CUSTOMER_CONTACT,
   CUSTOMER_CONTACT_EMAIL,
   CUSTOMER_CONTACT_PHONE_NUMBER,
   CUSTOMER_CONTACT_PHONE_EXT,
   AGREEMENT,
   PRICE_LIST,
   SHIP_TO_LOCATION,
   SHIP_TO_ADDRESS1,
   SHIP_TO_ADDRESS2,
   SHIP_TO_ADDRESS3,
   SHIP_TO_ADDRESS4,
   SHIP_TO_CTY_ST_ZIP_CTRY,
   SHIP_TO_CONTACT,
   SHIP_FROM_ORG,
   ORDER_SOURCE,
   ORDER_TYPE,
   SALESPERSON,
   BILL_TO_LOCATION,
   BILL_TO_ADDRESS1,
   BILL_TO_ADDRESS2,
   BILL_TO_ADDRESS3,
   BILL_TO_ADDRESS4,
   BILL_TO_CTY_ST_ZIP_CTRY,
   BILL_TO_CONTACT,
   PAYMENT_TERMS,
   INVOICING_RULE,
   DATE_ORDERED,
   CUSTOMER_PO_NUMBER,
   SALES_CHANNEL,
   STATUS,
   TAX_EXEMPTED,
   TAX_EXEMPT_REASON,
   TAX_EXEMPT_NUMBER,
   CURRENCY,
   PAYMENT_TYPE_CODE,
   SHIPMENT_PRIORITY,
   FREIGHT_TERMS,
   BOOKED_FLAG,
   CANCELLED_FLAG,
   ORG_ID,
   SOLD_FROM_ORG_ID,
   HEADER_ID,
   ORDER_TYPE_ID,
   CUSTOMER_CONTACT_ID,
   AGREEMENT_ID,
   PRICE_LIST_ID,
   SHIP_TO_ORG_ID,
   SHIP_TO_CONTACT_ID,
   SHIP_TO_CUSTOMER,
   SHIP_TO_CUSTOMER_ID,
   SHIP_FROM_ORG_ID,
   INVOICING_RULE_ID,
   BILL_TO_ORG_ID,
   BILL_TO_CONTACT_ID,
   BILL_TO_CUSTOMER,
   BILL_TO_CUSTOMER_ID,
   PAYMENT_TERM_ID,
   ORDER_SOURCE_ID,
   ORIG_SYS_DOCUMENT_REF,
   SALESPERSON_ID,
   BOOKED_DATE,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATED_BY_NAME,
   CREATION_DATE,
   CREATED_BY,
   CREATED_BY_NAME,
   VERSION_NUMBER,
   EXPIRATION_DATE,
   SOURCE_DOCUMENT_TYPE_ID,
   CHANGE_SEQUENCE,
   SOURCE_DOCUMENT_ID,
   REQUEST_DATE,
   PRICING_DATE,
   DEMAND_CLASS_CODE,
   PRICE_REQUEST_CODE,
   CONVERSION_RATE,
   CONVERSION_TYPE_CODE,
   CONVERSION_RATE_DATE,
   PARTIAL_SHIPMENTS,
   SHIP_TOLERANCE_ABOVE,
   SHIP_TOLERANCE_BELOW,
   TAX_POINT,
   OPEN_FLAG,
   ACCOUNTING_RULE_ID,
   ACCOUNTING_RULE_DURATION,
   SHIPPING_METHOD,
   FREIGHT_CARRIER_CODE,
   FOB_POINT_CODE,
   SOLD_TO_ORG_ID,
   DELIVER_TO_ORG_ID,
   DELIVER_TO_CONTACT_ID,
   RETURN_REASON_CODE,
   ORDER_DATE_TYPE_CODE,
   EARLIEST_SCHEDULE_LIMIT,
   LATEST_SCHEDULE_LIMIT,
   PAYMENT_AMOUNT,
   CHECK_NUMBER,
   CREDIT_CARD_CODE,
   CREDIT_CARD_HOLDER_NAME,
   CREDIT_CARD_NUMBER,
   CREDIT_CARD_EXPIRATION_DATE,
   CREDIT_CARD_APPROVAL_CODE,
   FIRST_ACK_CODE,
   FIRST_ACK_DATE,
   LAST_ACK_CODE,
   LAST_ACK_DATE,
   ORDER_CATEGORY_CODE,
   SHIPPING_INSTRUCTIONS,
   PACKING_INSTRUCTIONS,
   CREDIT_CARD_APPROVAL_DATE,
   CUSTOMER_PREFERENCE_SET_CODE,
   MARKETING_SOURCE_CODE_ID,
   UPGRADED_FLAG
)
AS
   SELECT header.order_number,
          cust_acct.account_number customer_number,
          SUBSTRB (party.party_name, 1, 50) customer,
             SUBSTRB (soldcont2.person_last_name, 1, 50)
          || DECODE (soldcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (soldcont2.person_first_name, 1, 50))
          || DECODE (soldcont3.title, NULL, NULL, ' ' || soldcont3.title)
             customer_contact,
          soldcont6.email_address,
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
          soldcont5.phone_extension,
          agree.NAME agreement,
          pl.NAME,
          ship_to_org.LOCATION ship_to_location,
          ship_to_addr2.address1 ship_to_address1,
          ship_to_addr2.address2 ship_to_address2,
          ship_to_addr2.address3 ship_to_address3,
          ship_to_addr2.address4 ship_to_address4,
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
             SUBSTRB (shipcont2.person_last_name, 1, 50)
          || DECODE (shipcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (shipcont2.person_first_name, 1, 50))
          || DECODE (shipcont3.title, NULL, NULL, ' ' || shipcont3.title)
             ship_to_contact,
          ship_from_org.organization_code ship_from_org,
          os.NAME order_source,
          ot.NAME order_type,
          oe_bis_salesperson.get_salesperson_name (header.salesrep_id),
          billorg.LOCATION bill_to,
          bill_to_addr2.address1 bill_to_address1,
          bill_to_addr2.address2 bill_to_address2,
          bill_to_addr2.address3 bill_to_address3,
          bill_to_addr2.address4 bill_to_address4,
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
             bill_to_cty_st_zip_ctry,
             SUBSTRB (billcont2.person_last_name, 1, 50)
          || DECODE (billcont2.person_first_name,
                     NULL, NULL,
                     ', ' || SUBSTRB (billcont2.person_first_name, 1, 50))
          || DECODE (billcont3.title, NULL, NULL, ' ' || billcont3.title)
             bill_to_contact,
          term.NAME,
          invrule.NAME,
          header.ordered_date,
          header.cust_po_number,
          header.sales_channel_code,
          DECODE (header.flow_status_code,
                  'BOOKED', 'Booked',
                  'CANCELLED', 'Cancelled',
                  'CLOSED', 'Closed',
                  'ENTERED', 'Entered',
                  NULL),
          DECODE (header.tax_exempt_flag,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (header.tax_exempt_reason_code,
                  'EDUCATION', 'education',
                  'HOSPITAL', 'hospital',
                  'MANUFACTURER', 'manufacturer',
                  'R10UPGRADE', 'R10UPGRADE',
                  'RESALE', 'resale',
                  'RESEARCH', 'research',
                  NULL),
          header.tax_exempt_number,
          header.transactional_curr_code,
          header.payment_type_code,
          DECODE (header.shipment_priority_code,
                  'High', 'High Priority',
                  'Standard', 'Standard Priority',
                  NULL),
          DECODE (header.freight_terms_code,
                  'COLLECT', 'Collect',
                  'DUECOST', 'Prepay  Add with cost conversion',
                  'Due', 'Prepay  Add',
                  'Paid', 'Prepaid',
                  'TBD', 'To Be Determined',
                  'THIRD_PARTY', 'Third Party Billing',
                  NULL),
          DECODE (header.booked_flag,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (header.cancelled_flag,  'N', 'No',  'Y', 'Yes',  NULL),
          header.org_id,
          header.sold_from_org_id,
          header.header_id,
          header.order_type_id,
          header.sold_to_contact_id,
          header.agreement_id,
          header.price_list_id,
          header.ship_to_org_id,
          header.ship_to_contact_id,
          SUBSTRB (ship_party.party_name, 1, 50),
          ship_cust_acct.cust_account_id,
          header.ship_from_org_id,
          header.invoicing_rule_id,
          header.invoice_to_org_id,
          header.invoice_to_contact_id,
          SUBSTRB (bill_party.party_name, 1, 50),
          bill_cust_acct.cust_account_id,
          header.payment_term_id,
          header.order_source_id,
          header.orig_sys_document_ref,
          header.salesrep_id,
          header.booked_date,
          header.last_update_date,
          header.last_updated_by,
          user1.user_name,
          header.creation_date,
          header.created_by,
          user2.user_name,
          header.version_number,
          header.expiration_date,
          header.source_document_type_id,
          header.change_sequence,
          header.source_document_id,
          header.request_date,
          header.pricing_date,
          header.demand_class_code,
          header.price_request_code,
          header.conversion_rate,
          header.conversion_type_code,
          header.conversion_rate_date,
          DECODE (header.partial_shipments_allowed,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          header.ship_tolerance_above,
          header.ship_tolerance_below,
          DECODE (header.tax_point_code, 'INVOICE', 'AT INVOICING', NULL),
          DECODE (header.open_flag,  'N', 'No',  'Y', 'Yes',  NULL),
          header.accounting_rule_id,
          header.accounting_rule_duration,
          DECODE (header.shipping_method_code,
                  'DEL', 'Delivery',
                  'PS', 'Pick Slip',
                  NULL),
          header.freight_carrier_code,
          header.fob_point_code,
          header.sold_to_org_id,
          header.deliver_to_org_id,
          header.deliver_to_contact_id,
          header.return_reason_code,
          header.order_date_type_code,
          header.earliest_schedule_limit,
          header.latest_schedule_limit,
          header.payment_amount,
          header.check_number,
          header.credit_card_code,
          header.credit_card_holder_name,
          header.credit_card_number,
          header.credit_card_expiration_date,
          header.credit_card_approval_code,
          header.first_ack_code,
          header.first_ack_date,
          header.last_ack_code,
          header.last_ack_date,
          DECODE (header.order_category_code,
                  'MIXED', 'Mixed',
                  'ORDER', 'Order',
                  'RETURN', 'Return',
                  NULL),
          header.shipping_instructions,
          header.packing_instructions,
          header.credit_card_approval_date,
          header.customer_preference_set_code,
          header.marketing_source_code_id,
          header.upgraded_flag
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
    --ORG_ORGANIZATION_DEFINITIONS OOD
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
          AND header.created_by = user2.user_id(+)
   --AND hr_security.show_bis_record (OOD.OPERATING_UNIT) = 'TRUE'
   WITH READ ONLY;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_ORD_HDRS_V FOR APPS.XX_BI_OE_ORD_HDRS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_ORD_HDRS_V FOR APPS.XX_BI_OE_ORD_HDRS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_ORD_HDRS_V FOR APPS.XX_BI_OE_ORD_HDRS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_ORD_HDRS_V FOR APPS.XX_BI_OE_ORD_HDRS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ORD_HDRS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ORD_HDRS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_ORD_HDRS_V TO XXINTG;
