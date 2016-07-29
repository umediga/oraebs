DROP VIEW APPS.XX_BI_M2C_BILL_TO_SHIP;

/* Formatted on 6/6/2016 4:59:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_BILL_TO_SHIP
(
   ORACLE_CUSTOMER_NUMBER,
   PARTY_SITE_NUMBER,
   CUSTOMER_NAME,
   ADDRESS1,
   ADDRESS2,
   ADDRESS3,
   ADDRESS4,
   CITY,
   STATE,
   POSTAL_CODE,
   BILL_TO_SITE,
   BILLUSE_ACTIVE_STATUS,
   SHIPUSE_ACTIVE_STATUS,
   SHIP_TO_SITE,
   PR_TERRITORY_CODE,
   HEADER_ACTIVE_STATUS,
   NEURO_TERRITORY_CODE
)
AS
   SELECT acc.account_number Oracle_Customer_Number,
          ps.party_site_number Party_Site_Number,
          p.party_name Customer_Name,
          loc.address1 Address1,
          loc.address2 Address2,
          loc.address3 Address3,
          loc.address4 Address4,
          loc.city City,
          loc.state State,
          loc.postal_code Postal_Code,
          DECODE (billuse.site_use_code,  NULL, 'N',  'BILL_TO', 'Y',  'N')
             Bill_to_Site,
          DECODE (billuse.status, 'A', 'Active', 'Inactive')
             billuse_active_status,
          DECODE (shipuse.status, 'A', 'Active', 'Inactive')
             shipuse_active_status,
          DECODE (shipuse.site_use_code,  NULL, 'N',  'SHIP_TO', 'Y',  'N')
             Ship_to_Site,
          DECODE (ps.status, 'A', 'Active', 'Inactive') header_active_status,
          cas.attribute5 PR_Territory_Code,
          cas.attribute7 Neuro_Territory_Code
     FROM hz_cust_accounts acc,
          hz_cust_acct_sites_all cas,
          hz_party_sites ps,
          hz_parties p,
          hz_locations loc,
          hz_cust_site_uses_all billuse,
          hz_cust_site_uses_all shipuse
    WHERE     acc.cust_account_id = cas.cust_account_id
          AND p.party_id = ps.party_id
          AND cas.party_site_id = ps.party_site_id
          AND ps.location_id = loc.location_id
          AND billuse.site_use_code(+) = 'BILL_TO'
          AND shipuse.site_use_code(+) = 'SHIP_TO'
          AND billuse.cust_acct_site_id(+) = cas.cust_acct_site_id
          AND shipuse.cust_acct_site_id(+) = cas.cust_acct_site_id;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_BILL_TO_SHIP FOR APPS.XX_BI_M2C_BILL_TO_SHIP;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_BILL_TO_SHIP FOR APPS.XX_BI_M2C_BILL_TO_SHIP;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_BILL_TO_SHIP FOR APPS.XX_BI_M2C_BILL_TO_SHIP;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_BILL_TO_SHIP FOR APPS.XX_BI_M2C_BILL_TO_SHIP;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_BILL_TO_SHIP TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_BILL_TO_SHIP TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_M2C_BILL_TO_SHIP TO XXINTG;
