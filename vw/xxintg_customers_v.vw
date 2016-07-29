DROP VIEW APPS.XXINTG_CUSTOMERS_V;

/* Formatted on 6/6/2016 5:00:23 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_CUSTOMERS_V
(
   ORG_ID,
   CUSTOMER_NAME,
   PARTY_ID,
   PARTY_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER_SITE,
   CUST_ACCOUNT_ID,
   CUST_ACCT_SITE_ID,
   SITE_USE_ID,
   STATE,
   ORIG_SYSTEM_REFERENCE,
   SALES_CHANNEL_CODE,
   SITE_USE_CODE,
   CUSTOMER_CLASSIFICATION,
   SALESREP_ID,
   GL_ID_REV,
   COUNTRY
)
AS
   SELECT bill_cas.org_id,
          bill_party.party_name customer_name,
          bill_party.party_id,
          bill_party.party_number,
          cust_acct.account_number customer_number,
          bill_su.location customer_site,
          cust_acct.cust_account_id,
          bill_su.cust_acct_site_id,
          bill_su.site_use_id,
          bill_loc.state,
          cust_acct.orig_system_reference,
          cust_acct.sales_channel_code,
          bill_su.site_use_code,
          cust_acct.customer_class_code,
          bill_su.primary_salesrep_id,
          bill_su.gl_id_rev,
          bill_loc.country
     FROM hz_cust_accounts cust_acct,
          hz_cust_site_uses_all bill_su,
          hz_cust_acct_sites_all bill_cas,
          hz_parties bill_party,
          hz_party_sites bill_ps,
          hz_locations bill_loc
    WHERE     bill_su.cust_acct_site_id = bill_cas.cust_acct_site_id
          AND bill_cas.cust_account_id = cust_acct.cust_account_id
          AND cust_acct.party_id = bill_party.party_id
          AND bill_loc.location_id = bill_ps.location_id
          AND bill_ps.party_site_id = bill_cas.party_site_id;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXINTG_CUSTOMERS_V FOR APPS.XXINTG_CUSTOMERS_V;


GRANT SELECT ON APPS.XXINTG_CUSTOMERS_V TO XXAPPSREAD;
