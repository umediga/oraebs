DROP VIEW APPS.XX_XRTX_AP_INV_TXN_SU_OPEN;

/* Formatted on 6/6/2016 4:57:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_SU_OPEN
(
   SUPPLIER_NAME,
   YEAR,
   OPEN_COUNT
)
AS
     SELECT c.vendor_name supplier_name,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            COUNT (*) open_count
       FROM AP_INVOICE_DISTRIBUTIONS_ALL a, ap_invoices_all b, ap_suppliers c
      WHERE     A.invoice_id = b.invoice_id
            --and a.vendor_id=b.vendor_id
            AND b.vendor_id = c.vendor_id
            AND b.payment_status_flag IN ('N', 'P')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
            AND b.cancelled_date IS NULL
   GROUP BY c.vendor_name, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 2 DESC;