DROP VIEW APPS.XX_XRTX_AP_INV_TXN_ACC_SU_V2;

/* Formatted on 6/6/2016 4:57:52 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_ACC_SU_V2
(
   SUPPLIER_NAME,
   YEAR,
   ACCOUNTED_STATUS,
   ACCOUNTED_COUNT
)
AS
     SELECT b.vendor_name supplier_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (A.INVOICE_ID),
                    'Y', 'Accounted',
                    'Not Accounted')
               accounted_status,
            COUNT (*) accounted_count
       FROM ap_invoices_all A, ap_suppliers b
      WHERE     a.vendor_id = b.vendor_id
            AND AP_INVOICES_PKG.GET_POSTING_STATUS (A.INVOICE_ID) = 'Y'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY b.vendor_name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY'),
            DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (A.INVOICE_ID),
                    'Y', 'Accounted',
                    'Not Accounted')
   ORDER BY 2 DESC;
