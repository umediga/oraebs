DROP VIEW APPS.XX_XRTX_TOP_ORD_SUP_T;

/* Formatted on 6/6/2016 4:54:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_TOP_ORD_SUP_T
(
   VENDOR_NAME,
   NAME,
   TYPE_LOOKUP_CODE,
   NO_PO
)
AS
     SELECT ap.vendor_name,
            hou.name,
            pha.TYPE_LOOKUP_CODE,
            COUNT (*) NO_PO
       FROM PO_HEADERS_ALL pha,
            ap_suppliers ap,
            hz_parties hp,
            hr_operating_units hou
      WHERE     pha.vendor_id = ap.vendor_id
            AND ap.party_id = hp.party_id
            AND hou.organization_id = pha.org_id
            AND pha.creation_date BETWEEN SYSDATE - 800 AND SYSDATE
   GROUP BY hou.name, pha.TYPE_LOOKUP_CODE, ap.vendor_name
   ORDER BY 4 DESC;
