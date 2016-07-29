DROP VIEW APPS.XX_XRTX_AP_INV_TXN_VS_SUP_V5;

/* Formatted on 6/6/2016 4:57:19 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_VS_SUP_V5
(
   SUPPLIER_NAME,
   YEAR,
   VALIDATION_STATUS,
   SELECT_FOR_PAYMENT_COUNT
)
AS
     SELECT d.vendor_name supplier_name,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
            DECODE (b.MATCH_STATUS_FLAG,
                    'A', 'Validated',
                    'N', 'Never Validated',
                    NULL, 'Never Validated',
                    'S', 'Selected for Payment',
                    'Needs Revalidation')
               validation_status,
            COUNT (*) select_for_payment_count
       FROM ap_invoices_all A,
            ap_invoice_distributions_all b,
            ap_holds_all c,
            ap_suppliers d
      WHERE     A.INVOICE_ID = b.invoice_id
            AND A.invoice_id = c.invoice_id
            AND a.vendor_id = d.vendor_id
            AND b.MATCH_STATUS_FLAG = 'S'
            AND c.release_lookup_code IS NOT NULL
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY d.vendor_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY'),
            DECODE (b.MATCH_STATUS_FLAG,
                    'A', 'Validated',
                    'N', 'Never Validated',
                    NULL, 'Never Validated',
                    'S', 'Selected for Payment',
                    'Needs Revalidation')
   ORDER BY 2 DESC;
