DROP VIEW APPS.XX_BI_M2C_EDI_CS_COMPARE;

/* Formatted on 6/6/2016 4:59:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_EDI_CS_COMPARE
(
   ORACLE_CUSTOMER_NUMBER,
   CUSTOMER_NAME,
   PARTY_SITE_NUMBER,
   ADDRESS1,
   ADDRESS2,
   ADDRESS3,
   ADDRESS4,
   CITY,
   STATE,
   POSTAL_CODE,
   COUNTY,
   COUNTRY,
   EDI_LOCATION,
   US_REPORTING_CODE,
   GEO_ZONE,
   BILL_TO_SITE,
   BILL_TO_PRIMARY_FLAG,
   HEADER_ACTIVE_STATUS,
   BILLUSE_ACTIVE_STATUS,
   SHIPUSE_ACTIVE_STATUS,
   SOLD_TO_SITE,
   SOLD_TO_PRIMARY_FLAG,
   SOLDUSE_ACTIVE_STATUS,
   GROUP_NAME,
   PARTNER_NAME,
   PART_DESC,
   CUSTOMER_ADDRESS,
   EDI_LOCATION_CODE,
   PO_CONFIGURED_FLAG,
   PO_TRANSLATOR_CODE,
   PO_ENABLED_FLAG,
   POA_CONFIGURED_FLAG,
   POA_TRANSLATOR_CODE,
   POA_ENABLED_FLAG,
   ASN_CONFIGURED_FLAG,
   ASN_TRANSLATOR_CODE,
   ASN_ENABLED_FLAG,
   INO_CONFIGURED_FLAG,
   INO_TRANSLATOR_CODE,
   INO_ENABLED_FLAG
)
AS
   SELECT acc.account_number Oracle_Customer_Number,
          p.party_name Customer_Name,
          ps.party_site_number Party_Site_Number,
          loc.address1 Address1,
          loc.address2 Address2,
          loc.address3 Address3,
          loc.address4 Address4,
          loc.city City,
          loc.state State,
          loc.postal_code Postal_Code,
          loc.county County,
          loc.country Country,
          cas.ece_tp_location_code edi_location,
          cas.attribute3 US_Reporting_Code,
          cas.attribute4 Geo_Zone,
          DECODE (billuse.site_use_code,  NULL, 'N',  'BILL_TO', 'Y',  'N')
             Bill_to_Site,
          DECODE (billuse.primary_flag, NULL, 'N', billuse.primary_flag)
             Bill_to_primary_flag,
          DECODE (ps.status, 'A', 'Active', 'Inactive') header_active_status,
          DECODE (billuse.status, 'A', 'Active', 'Inactive')
             billuse_active_status,
          DECODE (shipuse.status, 'A', 'Active', 'Inactive')
             shipuse_active_status,
          DECODE (soldtouse.site_use_code,  NULL, 'N',  'SOLD_TO', 'Y',  'N')
             Sold_To_Site,
          DECODE (soldtouse.primary_flag, NULL, 'N', soldtouse.primary_flag)
             Sold_To_Primary_flag,
          DECODE (soldtouse.status, 'A', 'Active', 'Inactive')
             solduse_active_status,
          ETG.TP_GROUP_CODE GROUP_NAME,
          ETH.TP_CODE PARTNER_NAME,
          ETH.TP_DESCRIPTION PARTNER_DESC,
          RAA.ADDRESS1 || ' ' || RAA.CITY || ' ' || RAA.STATE
             CUSTOMER_ADDRESS,
          RAA.ECE_TP_LOCATION_CODE EDI_LOCATION_CODE,
          (SELECT DECODE (ELV.MEANING,
                          'IN: Purchase Order (850/ORDERS)', 'Y',
                          NULL)
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'IN: Purchase Order (850/ORDERS)')
             PO_CONFIGURED,
          (SELECT ETD.TRANSLATOR_CODE
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'IN: Purchase Order (850/ORDERS)')
             PO_TRANSLATOR_CODE,
          (SELECT ETD.EDI_FLAG
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'IN: Purchase Order (850/ORDERS)')
             PO_ENABLED,
          (SELECT DECODE (
                     ELV.MEANING,
                     'OUT: Purchase Order Acknowledgement (855/ORDRSP)', 'Y',
                     NULL)
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Purchase Order Acknowledgement (855/ORDRSP)')
             POA_CONFIGURED,
          (SELECT ETD.TRANSLATOR_CODE
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Purchase Order Acknowledgement (855/ORDRSP)')
             POA_TRANSLATOR_CODE,
          (SELECT ETD.EDI_FLAG
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Purchase Order Acknowledgement (855/ORDRSP)')
             POA_ENABLED_FLAG,
          (SELECT DECODE (
                     ELV.MEANING,
                     'OUT: Outbound Shipment Notice/Manifest Transaction', 'Y',
                     NULL)
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Outbound Shipment Notice/Manifest Transaction')
             ASN_CONFIGURED,
          (SELECT ETD.TRANSLATOR_CODE
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Outbound Shipment Notice/Manifest Transaction')
             ASN_TRANSLATOR_CODE,
          (SELECT ETD.EDI_FLAG
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING =
                         'OUT: Outbound Shipment Notice/Manifest Transaction')
             ASN_ENABLED_FLAG,
          (SELECT DECODE (ELV.MEANING,
                          'OUT: Invoice (810/INVOIC)', 'Y',
                          NULL)
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'OUT: Invoice (810/INVOIC)')
             INO_CONFIGURED,
          (SELECT ETD.TRANSLATOR_CODE
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'OUT: Invoice (810/INVOIC)')
             INO_TRANSLATOR_CODE,
          (SELECT ETD.EDI_FLAG
             FROM ECE_TP_DETAILS ETD, ECE_LOOKUP_VALUES ELV
            WHERE     ETD.TP_HEADER_ID = ETH.TP_HEADER_ID
                  AND ELV.LOOKUP_CODE = ETD.DOCUMENT_ID
                  AND ELV.LOOKUP_TYPE = 'DOCUMENT'
                  AND ELV.MEANING = 'OUT: Invoice (810/INVOIC)')
             INO_ENABLED_FLAG
     FROM hz_cust_accounts_all acc,
          hz_cust_acct_sites_all cas,
          hz_party_sites ps,
          hz_parties p,
          hz_locations loc,
          hz_cust_site_uses_all billuse,
          hz_cust_site_uses_all shipuse,
          hz_cust_site_uses_all soldtouse,
          ECE_TP_GROUP ETG,
          ECE_TP_HEADERS ETH,
          RA_ADDRESSES_ALL RAA
    WHERE     acc.cust_account_id = cas.cust_account_id
          AND p.party_id = ps.party_id
          AND cas.party_site_id = ps.party_site_id
          AND ps.location_id = loc.location_id
          AND billuse.site_use_code(+) = 'BILL_TO'
          AND shipuse.site_use_code(+) = 'SHIP_TO'
          AND soldtouse.site_use_code(+) = 'SOLD_TO'
          AND billuse.cust_acct_site_id(+) = cas.cust_acct_site_id
          AND shipuse.cust_acct_site_id(+) = cas.cust_acct_site_id
          AND soldtouse.cust_acct_site_id(+) = cas.cust_acct_site_id
          AND ETG.TP_GROUP_ID = ETH.TP_GROUP_ID
          AND ETH.TP_HEADER_ID = RAA.TP_HEADER_ID
--AND RAA.PARTY_ID = p.PARTY_ID
;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_EDI_CS_COMPARE FOR APPS.XX_BI_M2C_EDI_CS_COMPARE;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_EDI_CS_COMPARE FOR APPS.XX_BI_M2C_EDI_CS_COMPARE;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_EDI_CS_COMPARE FOR APPS.XX_BI_M2C_EDI_CS_COMPARE;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_EDI_CS_COMPARE FOR APPS.XX_BI_M2C_EDI_CS_COMPARE;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_EDI_CS_COMPARE TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_EDI_CS_COMPARE TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_EDI_CS_COMPARE TO XXINTG;
