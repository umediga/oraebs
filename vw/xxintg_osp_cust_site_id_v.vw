DROP VIEW APPS.XXINTG_OSP_CUST_SITE_ID_V;

/* Formatted on 6/6/2016 5:00:16 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_OSP_CUST_SITE_ID_V
(
   PARTY_NAME,
   SITE_CODE,
   SITE_USE_ID
)
AS
     SELECT ap.vendor_name "PARTY_NAME",
            ass.vendor_site_code "SITE_CODE",
            ass.vendor_site_id "SITE_USE_ID"
       FROM ap_suppliers ap, ap_supplier_sites_all ass
      WHERE ap.vendor_id = ass.vendor_id
   ORDER BY ap.vendor_name;
