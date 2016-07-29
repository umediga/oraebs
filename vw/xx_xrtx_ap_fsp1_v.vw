DROP VIEW APPS.XX_XRTX_AP_FSP1_V;

/* Formatted on 6/6/2016 4:57:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_FSP1_V
(
   "Opearting Unit",
   RFQ_ONLY_SITE_FLAG,
   SHIP_TO_LOCATION_ID,
   "Ship To Location",
   BILL_TO_LOCATION_ID,
   "Bil To Location",
   INVENTORY_ORGANIZATION_ID,
   INVORG,
   SHIP_VIA_LOOKUP_CODE,
   SHIPVIA,
   FOB_LOOKUP_CODE,
   MEANING,
   FOB,
   FREIGHTTERMS
)
AS
   SELECT b.name "Opearting Unit",
          a.RFQ_ONLY_SITE_FLAG,
          a.SHIP_TO_LOCATION_ID,
          hcsua.LOCATION "Ship To Location",
          a.BILL_TO_LOCATION_ID,
          hcsua1.LOCATION "Bil To Location",
          a.INVENTORY_ORGANIZATION_ID,
          ood.organization_code || '-' || ood.organization_name "INVORG",
          a.SHIP_VIA_LOOKUP_CODE,
          al.meaning "SHIPVIA",
          a.FOB_LOOKUP_CODE,
          al1.meaning,
          CASE
             WHEN al1.lookup_code = 'CIF'
             THEN
                'Vendors responsibility for goods ceases at specified location'
             WHEN al1.lookup_code = 'DEST'
             THEN
                'Destination (Process)'
             WHEN al1.lookup_code = 'Destination'
             THEN
                'Vendors responsibility ceases upon acceptance by buyer'
             WHEN al1.lookup_code = 'NONE'
             THEN
                'Default (Process)'
             WHEN al1.lookup_code = 'Origin'
             THEN
                'Vendors responsibility ceases upon transfer to carrier'
             WHEN al1.lookup_code = 'SHIP'
             THEN
                'Shipping Pt(Process)'
          END
             AS "FOB",
          a.FREIGHT_TERMS_LOOKUP_CODE "FREIGHTTERMS"
     FROM financials_system_params_all a,
          hr_operating_units b,
          hz_cust_acct_sites_all hcasa,
          hz_cust_site_uses_all hcsua,
          hz_cust_acct_sites_all hcasa1,
          hz_cust_site_uses_all hcsua1,
          org_organization_definitions ood,
          ar_lookups al,
          ar_lookups al1
    WHERE     a.ORG_ID = b.organization_id
          AND a.SHIP_TO_LOCATION_ID = hcsua.site_use_id(+)
          AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
          AND a.BILL_TO_LOCATION_ID = hcsua1.site_use_id(+)
          AND hcsua1.cust_acct_site_id = hcasa1.cust_acct_site_id(+)
          AND a.INVENTORY_ORGANIZATION_ID = ood.organization_id(+)
          AND a.SHIP_VIA_LOOKUP_CODE = al.lookup_code(+)
          AND a.FOB_LOOKUP_CODE = al1.lookup_code(+);
