DROP VIEW APPS.XX_XRTX_AP_INV_TXN_SUPP_V6;

/* Formatted on 6/6/2016 4:57:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_SUPP_V6
(
   SUPPLIER_NAME,
   YEAR,
   RETAINAGE_REL_COUNT
)
AS
     SELECT b.vendor_name supplier_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            COUNT (*) retainage_rel_count
       FROM ap_invoices_all A, ap_suppliers b
      WHERE     a.vendor_id = b.vendor_id
            AND a.invoice_type_lookup_code = 'RETAINAGE RELEASE'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY b.vendor_name, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;
