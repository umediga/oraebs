DROP VIEW APPS.XX_XRTX_AP_INV_TXN_SU_CANCEL;

/* Formatted on 6/6/2016 4:57:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_SU_CANCEL
(
   SUPPLIER_NAME,
   YEAR,
   CANCELLED_COUNT
)
AS
     SELECT c.vendor_name supplier_name,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            COUNT (*) cancelled_count
       FROM AP_INVOICE_DISTRIBUTIONS_ALL a, ap_invoices_all b, ap_suppliers c
      WHERE     A.invoice_id = b.invoice_id
            --and a.vendor_id=b.vendor_id
            AND b.vendor_id = c.vendor_id
            AND b.cancelled_date IS NOT NULL
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.vendor_name, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 2 DESC;
