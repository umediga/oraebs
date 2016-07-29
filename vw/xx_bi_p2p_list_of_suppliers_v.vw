DROP VIEW APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V;

/* Formatted on 6/6/2016 4:59:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V
(
   VENDOR_ID,
   VENDOR_NAME,
   ORACLE_SUPPLIER_NUMBER,
   ALT_SUPPLIER_NAME,
   SEGMENT2,
   SEGMENT3,
   SEGMENT4,
   SEGMENT5,
   SIC,
   NATIONAL_INSURANCE_NUM,
   ORG_TYPE,
   CUST_NUMBER,
   LEGACY_SYSTEM,
   LEGACY_SUPPLIER_ID,
   CERT_REG_NUM,
   CERT_EXPIRY_DATE,
   ISO_CERT_NUMBER,
   ISO_EXPIRY_DATE,
   QUALITY_AGREE_NEED,
   QUALITY_AGREE_DATE,
   SELF_ASSESS_DATE,
   INTEGRA_AUDIT_DATE,
   HCP,
   MISSION_STATEMENT,
   TAXPAYER_ID,
   TAX_REG_NUMBER,
   ANALYSIS_YEAR,
   TAX_REPORT_NAME,
   CURR_PREFERENCE,
   FEDERAL_RPT_FLAG,
   STATE_RPT_FLAG,
   ANNUAL_REVENUE,
   POTENTIAL_REVENUE,
   FISCAL_YEAR_END,
   VENDOR_SITE_CODE_NAME,
   PUR_SITE_FLAG,
   RFQ_ONLY_SITE_FLAG,
   PAY_SITE_FLAG,
   ADDRESS_LINE1,
   ADDRESS_LINES_ALT,
   ADDRESS_LINE2,
   ADDRESS_LINE3,
   CITY,
   STATE,
   POSTAL_CODE,
   PROVINCE,
   COUNTRY,
   OPERATING_UNIT,
   COMMUNICATION,
   PURPOSE,
   FIRST_NAME,
   MIDDLE_NAME,
   LAST_NAME,
   EMAIL_ADDRESS,
   URL,
   ORG_ID,
   PHONE_AREA_CODE,
   PHONE_NUMBER,
   FAX_AREA_CODE,
   FAX,
   INACTIVE_DATE_1,
   LAST_CERT_BY,
   MINORITY_GRP_LOOKUP,
   SMALL_BUSINESS,
   WOMEN_FLAG,
   INSPECTION_FLAG,
   SITENAME2,
   SITE_STATUS,
   SHIP_TO_ADDRESS,
   BILL_TO_ADDRESS,
   SHIP_VIA,
   PAY_ON,
   ALT_PAY_SITE_NAME,
   INV_SUMMARY_LEVEL,
   FOB,
   FREIGHT_TERMS,
   TRANS_ARRANGED,
   COUNTRY_OF_ORIGIN,
   ENF_SHIP_TO_LOCATION,
   MATCH_APPROVAL_LEVEL,
   QTY_RCV_TOLERANCE,
   QTY_RCV_EXCEPTION,
   INV_CURRENCY,
   INV_AMOUNT_LIMIT,
   INV_MATCH_OPTION,
   PAY_HOLD_REASON,
   PAY_CURRENCY,
   PAY_PRIORITY,
   TERMS,
   TERMS_DATE_BASIS,
   PAY_DATE_BASIS_LOOKUP,
   PAY_GROUP,
   SITE_STATUS2,
   SITENAME3,
   INV_TOLERANCE,
   SERVICE_TOLERANCE,
   VAT_REGISTRATION_NUM,
   O_PARENT_SUPPLIER_NUMBER,
   O_INACTIVE_DATE,
   O_YEAR_ESTABLISHED,
   "O_D-U-N-S_NUMBER",
   T_ALLOW_WITHHOLDING_TAX,
   T_DEFAULT_RPRTING_COUNTRY_NAME,
   T_DEFAULT_RPRTING_REG_NUMBER,
   T_DEFAULT_RPRTING_TAX_REG_TYPE,
   A_COUNTRY,
   A_ADDRESS_NAME,
   A_ADDRESSEE,
   A_ADDRESS_STATUS,
   A_LANGUAGE,
   A_PHONE_AREA_CODE,
   A_PHONE_NUMBER,
   A_FAX_AREA_CODE,
   A_FAX_NUMBER,
   A_EMAIL_ADDRESS,
   S_ADDRESS_PURPOSE,
   S_PHONE_AREA_CODE,
   S_PHONE_NUMBER,
   S_FAX_AREA_CODE,
   S_FAX_NUMBER,
   S_EMAIL_ADDRESS,
   C_STATUS,
   C_PARTY_SITE_NAME,
   C_ADDRESS_NAME,
   C_ADDRESS_DETAILS,
   B_BANK_NUMBER,
   B_PAYMENT_CURRENCY_CODE,
   B_START_DATE_ACTIVE,
   B_END_DATE_ACTIVE,
   B_PAYMENT_PRIORITY,
   T_ORGANIZATION_TYPE,
   T_ALLOW_TAX_APPLICABILITY,
   T_SET_FOR_SELF_ASSESSMENT,
   T_ALLOW_OFFSET_TAXES,
   T_TAX_CLASSIFICATION,
   PYMNT_SITE_NAME,
   PYMNT_OPERATING_UNIT,
   F_SITE_NAME,
   F_OPERATING_UNIT,
   R_DAYS_EARLY_RECEIPT_ALLOWED,
   R_DAYS_LATE_RECEIPT_ALLOWED,
   R_ALLOW_SUBSTITUTE_RCPTS_FLG,
   R_ALLOW_UNORDERED_RCPTS_FLG,
   R_RCPT_DAYS_EXCEPTION_CODE,
   P_SITE_NAME,
   P_OPERATING_UNIT,
   P_PAYMENT_METHOD,
   R_RELATIONSHIP_STATUS,
   R_SUPPLIER_SITE,
   R_FROM_DATE,
   R_TO_DATE,
   PSITE_SITE_NAME,
   PSITE_OPERATING_UNIT,
   P_MATCH_OPTION,
   P_INVOICE_CURRENCY_CODE,
   P_HOLD_ALL_PAYMENTS,
   P_HOLD_UNMATCHED_INVOICES,
   P_HOLD_FUTURE_PAYMENTS,
   PMNT_SITE_NAME,
   PMNT_OPERATING_UNIT,
   P_CURRENCY_CODE,
   P_PAY_GROUP,
   T_TERMS_SITE_NAME,
   T_OPERATING_UNIT,
   T_TERMS,
   T_TERMS_DATE_BASIS,
   T_TERMS_PAY_DATE_BASIS
)
AS
   SELECT ap.vendor_id,
          ap.vendor_name,
          ap.segment1 oracle_supplier_number,
          ap.vendor_name_alt,
          ap.segment2,
          ap.segment3,
          ap.segment4,
          ap.segment5,
          ap.standard_industry_class,
          ap.national_insurance_number,
          (SELECT flv.meaning
             FROM fnd_lookup_values flv
            WHERE     flv.lookup_type = 'ORGANIZATION TYPE'
                  AND flv.lookup_code = ap.organization_type_lookup_code
                  AND flv.LANGUAGE = 'D'),
          ap.customer_num,
          ap.attribute1,
          ap.attribute2,
          ap.attribute3,
          ap.attribute4,
          ap.attribute5,
          ap.attribute6,
          ap.attribute7,
          ap.attribute8,
          ap.attribute9,
          ap.attribute10,
          ap.attribute11,
          hp.mission_statement,
          DECODE (ap.organization_type_lookup_code,
                  'INDIVIDUAL', ap.individual_1099,
                  'FOREIGN INDIVIDUAL', ap.individual_1099,
                  hp.jgzz_fiscal_code),
          hp.tax_reference,
          hp.analysis_fy,
          ap.tax_reporting_name,
          asa.invoice_currency_code currency_preference,
          ap.federal_reportable_flag,
          ap.state_reportable_flag,
          hp.curr_fy_potential_revenue,
          hp.next_fy_potential_revenue,
          hp.fiscal_yearend_month,
          asa.vendor_site_code,
          asa.purchasing_site_flag,
          asa.rfq_only_site_flag,
          asa.pay_site_flag,
          asa.address_line1,
          asa.address_lines_alt,
          asa.address_line2,
          asa.address_line3,
          asa.city,
          asa.state,
          asa.zip,
          asa.province,
          asa.country,
          hou.NAME,
          (   'Email:'
           || ' '
           || asa.email_address
           || ' '
           || ' '
           || 'Phone:'
           || asa.area_code
           || ' '
           || asa.phone
           || ' '
           || ' '
           || 'Fax:'
           || asa.fax_area_code
           || ' '
           || asa.fax),
          DECODE (
             NVL (asa.pay_site_flag, 'N'),
             'Y', DECODE (
                     NVL (asa.purchasing_site_flag, 'N'),
                     'Y', DECODE (NVL (asa.rfq_only_site_flag, 'N'),
                                  'Y', 'Payment,Purchasing,RFQ',
                                  'N', 'Payment,Purchasing'),
                     'N', DECODE (NVL (asa.rfq_only_site_flag, 'N'),
                                  'Y', 'Payment, RFQ',
                                  'N', 'Payment')),
             'N', DECODE (
                     NVL (asa.purchasing_site_flag, 'N'),
                     'Y', DECODE (NVL (asa.rfq_only_site_flag, 'N'),
                                  'Y', 'Purchasing, RFQ',
                                  'N', 'Purchasing'),
                     'N', DECODE (NVL (asa.rfq_only_site_flag, 'N'),
                                  'Y', 'RFQ',
                                  'N', NULL))),
          ap.first_name,
          ap.second_name,
          ap.last_name,
          asa.email_address,
          hp.url,
          asa.org_id,
          asa.area_code,
          /*DECODE (CONT_POINT.CONTACT_POINT_TYPE,
          'TLX', CONT_POINT.TELEX_NUMBER,
          CONT_POINT.PHONE_NUMBER)*/
          asa.phone,
          asa.fax_area_code,
          asa.fax,
          asa.inactive_date,
          ap.bus_class_last_certified_by,
          --HUB ZONE
          ap.minority_group_lookup_code,     --SERVICE_DISABLED_VETERAND_OWNED
          DECODE (ap.small_business_flag,  'Y', 'Yes',  'N', 'No'),
          --VETERAN OWNED
          DECODE (ap.women_owned_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (ap.inspection_required_flag,  'Y', 'Yes',  'N', 'No'),
          asa.vendor_site_code,
          DECODE (asa.inactive_date, NULL, 'Active', 'Inactive'),
          hrl1.location_code,
          hrl2.location_code,
          asa.ship_via_lookup_code,
          asa.pay_on_code,
          pay_site.vendor_site_code,
          asa.pay_on_receipt_summary_code,
          asa.fob_lookup_code,
          asa.freight_terms_lookup_code,
          asa.shipping_control,
          (SELECT cor.territory_short_name
             FROM fnd_territories_vl cor
            WHERE asa.country_of_origin_code = cor.territory_code(+)),
          (SELECT flv.meaning
             FROM fnd_lookup_values flv
            WHERE     flv.lookup_type = 'RCV OPTION'
                  AND flv.lookup_code = ap.enforce_ship_to_location_code
                  AND flv.LANGUAGE = 'D'),
          --MATCH_APPROVAL_LEVEL
          asa.match_option,
          ap.qty_rcv_tolerance,
          (SELECT flv.meaning
             FROM fnd_lookup_values flv
            WHERE     flv.lookup_type = 'RCV OPTION'
                  AND flv.lookup_code = ap.qty_rcv_exception_code
                  AND flv.LANGUAGE = 'D'),
          ap.invoice_currency_code,
          asa.invoice_amount_limit,
          (SELECT flv.meaning
             FROM fnd_lookup_values flv
            WHERE     flv.lookup_type = 'POS_INVOICE_MATCH_OPTION'
                  AND flv.LANGUAGE = 'US'
                  AND flv.lookup_code = asa.match_option),
          ap.hold_reason,
          ap.payment_currency_code,
          ap.payment_priority,
          terms.NAME,
          asa.terms_date_basis,
          asa.pay_date_basis_lookup_code,
          (SELECT pay_group.description
             FROM fnd_lookup_values pay_group
            WHERE     asa.pay_group_lookup_code = pay_group.lookup_code(+)
                  AND pay_group.lookup_type(+) = 'PAY GROUP'
                  AND pay_group.LANGUAGE(+) = USERENV ('lang')),
          DECODE (asa.inactive_date, NULL, 'Active', 'Inactive') site_status2,
          asa.vendor_site_code sitename3,
          (SELECT apt.tolerance_name
             FROM ap_tolerance_templates apt
            WHERE asa.tolerance_id = apt.tolerance_id),
          (SELECT apt.tolerance_name
             FROM ap_tolerance_templates apt
            WHERE asa.services_tolerance_id = apt.tolerance_id),
          asa.vat_registration_num,
          ap.parent_vendor_id,
          DECODE (asa.inactive_date, NULL, 'Active', 'Inactive'),
          hp.year_established,
          asa.duns_number,
          ap.organization_type_lookup_code,
          zpp.country_code,
          zpp.rep_registration_number,
          zpp.registration_type_code,
          asa.country,
          hps.party_site_name,
          hps.addressee,
          hps.status,
          asa.LANGUAGE,
          asa.area_code,
          asa.phone,
          asa.fax_area_code,
          asa.fax,
          asa.email_address,
          hpu.site_use_type,
          asa.area_code,
          asa.phone,
          asa.fax_area_code,
          asa.fax,
          asa.email_address,
          hps.status,
          hps.party_site_name,
          asa.vendor_site_code,
          (   asa.address_line1
           || ' '
           || ' '
           || asa.address_line2
           || ' '
           || asa.city
           || ' '
           || ' '
           || asa.county
           || ' '
           || ' '
           || asa.state
           || ' '
           || asa.zip),
          asa.bank_number,
          --ACA.IBAN_NUMBER,
          ap.payment_currency_code,
          ap.start_date_active,
          ap.end_date_active,
          asa.payment_priority,
          DECODE (asa.allow_awt_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (zpp.process_for_applicability_flag,
                  'Y', 'Yes',
                  'N', 'No'),
          DECODE (zpp.self_assess_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (zpp.allow_offset_tax_flag,  'Y', 'Yes',  'N', 'No'),
          zpp.tax_classification_code,
          asa.vendor_site_code,
          hou.NAME,
          asa.vendor_site_code,
          hou.NAME,
          ap.days_early_receipt_allowed,
          ap.days_late_receipt_allowed,
          DECODE (ap.allow_substitute_receipts_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (ap.allow_unordered_receipts_flag,  'Y', 'Yes',  'N', 'No'),
          ap.receipt_days_exception_code,
          asa.vendor_site_code,
          hou.NAME,
          asa.payment_method_lookup_code,
          hps.status,
          asa.vendor_site_id,
          --ACA.REMIT_TO_SUPPLIER_NAME,
          --ACA.REMIT_TO_SUPPLIER_SITE,
          hou.date_from,
          hou.date_to,
          asa.vendor_site_code,
          hou.NAME,
          ap.match_option,
          ap.invoice_currency_code,
          DECODE (asa.hold_all_payments_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (asa.hold_unmatched_invoices_flag,  'Y', 'Yes',  'N', 'No'),
          DECODE (asa.hold_future_payments_flag,  'Y', 'Yes',  'N', 'No'),
          asa.vendor_site_code,
          hou.NAME,
          ap.payment_currency_code,
          ap.pay_group_lookup_code,
          asa.vendor_site_code,
          hou.NAME,
          terms.NAME,
          ap.terms_date_basis,
          ap.pay_date_basis_lookup_code
     FROM ap_suppliers ap,
          ap_supplier_sites_all asa,
          ap_terms_tl terms,
          ap_supplier_sites_all pay_site,
          apps.hr_locations hrl1,
          apps.hr_locations hrl2,
          hz_parties hp,
          hr_operating_units hou,
          zx_party_tax_profile zpp,
          hz_party_sites hps,
          hz_party_site_uses hpu
    WHERE     ap.vendor_id = asa.vendor_id
          AND ap.terms_id = terms.term_id
          AND terms.LANGUAGE(+) = USERENV ('LANG')
          AND terms.enabled_flag(+) = 'Y'
          AND asa.default_pay_site_id = pay_site.vendor_site_id(+)
          AND hrl1.location_id(+) = asa.ship_to_location_id
          AND hrl2.location_id(+) = asa.bill_to_location_id
          AND ap.party_id = hp.party_id
          AND asa.org_id = hou.organization_id
          --AND AP.SEGMENT1='101182'
          AND TO_NUMBER (zpp.party_id) = hp.party_id
          AND hpu.party_site_id = hps.party_site_id
          AND asa.vendor_site_code = hps.party_site_name
          AND hps.party_id = hp.party_id
          AND hpu.party_site_id = hps.party_site_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_P2P_LIST_OF_SUPPLIERS_V FOR APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_P2P_LIST_OF_SUPPLIERS_V FOR APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_P2P_LIST_OF_SUPPLIERS_V FOR APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_P2P_LIST_OF_SUPPLIERS_V FOR APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_P2P_LIST_OF_SUPPLIERS_V TO XXINTG;
