DROP VIEW APPS.XX_CN_CUST_LOC_V;

/* Formatted on 6/6/2016 4:58:50 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_CN_CUST_LOC_V
(
   CUSTOMER_TRX_LINE_ID,
   ORG_ID,
   PARTY_NUMBER,
   PARTY_NAME,
   PARTY_SITE_ID,
   CITY,
   COUNTY,
   STATE,
   POSTAL_CODE,
   COUNTRY
)
AS
   SELECT trx_line.customer_trx_line_id,
          trx.org_id,
          party.party_number,
          party.party_name,
          partysite.party_site_id,
          loc.city,
          loc.county,
          loc.state,
          loc.postal_code,
          loc.country
     FROM ra_customer_trx_all trx,
          ra_customer_trx_lines_all trx_line,
          hz_cust_site_uses_all siteuse,
          hz_cust_acct_sites_all acctsite,
          hz_party_sites partysite,
          hz_parties party,
          hz_locations loc
    WHERE     trx.ship_to_site_use_id = siteuse.site_use_id
          AND siteuse.cust_acct_site_id = acctsite.cust_acct_site_id
          AND acctsite.party_site_id = partysite.party_site_id
          AND partysite.party_id = party.party_id
          AND partysite.location_id = loc.location_id
          AND trx_line.customer_trx_id = trx.customer_trx_id;
