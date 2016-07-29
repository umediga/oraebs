DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPP_V5;

/* Formatted on 6/6/2016 4:54:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_OU_SUPP_V5
(
   OPERATING_UNIT,
   SUPPLIER_NAME,
   YEAR,
   REJECTED_COUNT
)
AS
     SELECT hou.NAME operating_unit,
            aps.vendor_name supplier_name,
            TO_CHAR (A.creation_date, 'YYYY') YEAR,
            COUNT (*) rejected_count
       FROM po_requisition_headers_all A,
            po_requisition_lines_all b,
            hr_all_organization_units hou,
            ap_suppliers aps
      WHERE     A.requisition_header_id = b.requisition_header_id
            AND A.org_id = hou.organization_id
            AND b.vendor_id = aps.vendor_id(+)
            AND A.type_lookup_code = 'INTERNAL'
            AND a.authorization_status = 'REJECTED'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY hou.NAME, aps.vendor_name, TO_CHAR (A.creation_date, 'YYYY')
   ORDER BY 3 DESC;
