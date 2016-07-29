DROP VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_CANCEL;

/* Formatted on 6/6/2016 4:54:21 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_TXN_SUPP_CANCEL
(
   SUPPLIER_NAME,
   YEAR,
   CANCEL_COUNT
)
AS
     SELECT aps.vendor_name supplier_name,
            TO_CHAR (A.creation_date, 'YYYY') YEAR,
            COUNT (*) cancel_count
       FROM po_requisition_headers_all A,
            po_requisition_lines_all b,
            ap_suppliers aps
      WHERE     A.requisition_header_id = b.requisition_header_id
            AND b.vendor_id = aps.vendor_id(+)
            AND A.type_lookup_code = 'INTERNAL'
            AND NVL (a.cancel_flag, 'N') <> 'N'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY aps.vendor_name, TO_CHAR (A.creation_date, 'YYYY')
   ORDER BY 2 DESC;
