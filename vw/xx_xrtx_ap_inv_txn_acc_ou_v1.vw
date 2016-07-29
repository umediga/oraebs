DROP VIEW APPS.XX_XRTX_AP_INV_TXN_ACC_OU_V1;

/* Formatted on 6/6/2016 4:57:55 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_ACC_OU_V1
(
   OPERATING_UNIT,
   YEAR,
   ACCOUNTED_STATUS,
   TOTAL_COUNT
)
AS
     SELECT b.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (A.INVOICE_ID),
                    'Y', 'Accounted',
                    'Not Accounted')
               accounted_status,
            COUNT (*) total_count
       FROM ap_invoices_all A, hr_all_organization_units b
      WHERE     A.org_id = b.organization_id
            --and AP_INVOICES_PKG.GET_POSTING_STATUS( A.INVOICE_ID) ='Y'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY b.NAME,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY'),
            DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (A.INVOICE_ID),
                    'Y', 'Accounted',
                    'Not Accounted')
   ORDER BY 2 DESC;