DROP VIEW APPS.XX_XRTX_PO_DOC_SUPP_TOTAL2;

/* Formatted on 6/6/2016 4:55:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_DOC_SUPP_TOTAL2
(
   SUPPLIER_NAME,
   YEAR,
   TOTAL_COUNT
)
AS
     SELECT aps.vendor_name supplier_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) total_count
       FROM po_headers_all A, ap_suppliers aps
      WHERE     A.vendor_id = aps.vendor_id(+)
            AND A.type_lookup_code = 'CONTRACT'
            AND A.authorization_status IS NOT NULL
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY aps.vendor_name, TO_CHAR (TRUNC (a.creation_date), 'YYYY')
   ORDER BY 2 DESC;
