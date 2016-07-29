DROP VIEW APPS.INTG_SO_COUNTRY_VL;

/* Formatted on 6/6/2016 5:00:32 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.INTG_SO_COUNTRY_VL
(
   CODE,
   COUNTRY
)
AS
     SELECT DISTINCT hls.country, fnd.meaning
       FROM apps.hz_cust_site_uses_all ship_to,
            apps.hz_cust_acct_sites_all hcass,
            apps.hz_cust_accounts hcas,
            apps.hz_party_sites hpss,
            apps.hz_locations hls,
            apps.oe_order_lines_all oel,
            apps.fnd_lookup_values fnd
      WHERE     1 = 1
            AND ship_to.site_use_id = oel.ship_to_org_id
            AND hcass.cust_acct_site_id = ship_to.cust_acct_site_id
            AND hcas.cust_account_id = hcass.cust_account_id
            AND hcass.party_site_id = hpss.party_site_id
            AND hpss.location_id = hls.location_id
            AND fnd.lookup_code = hls.country
            AND hls.country IS NOT NULL
            AND fnd.lookup_type = 'JEES_EURO_COUNTRY_CODES'
            AND fnd.language = 'US'
            AND (fnd.end_date_active IS NULL OR fnd.end_date_active > SYSDATE)
   ORDER BY hls.country;