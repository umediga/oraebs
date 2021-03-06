DROP VIEW APPS.XX_XRTX_PO_DOC_SUPP_V25;

/* Formatted on 6/6/2016 4:55:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_SUPP_V25
(
   OPERATING_UNIT,
   SUPPLIER_NAME,
   YEAR,
   REQ_REAPPROVAL_COUNT
)
AS
     SELECT hou.NAME operating_unit,
            aps.vendor_name supplier_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) req_reapproval_count
       FROM po_headers_all A, ap_suppliers aps, hr_all_organization_units hou
      WHERE     A.org_id = hou.organization_id
            AND A.vendor_id = aps.vendor_id(+)
            AND A.type_lookup_code = 'PLANNED'
            AND a.authorization_status = 'REQUIRES REAPPROVAL'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME,
            aps.vendor_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 3 DESC;
