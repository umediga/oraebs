DROP VIEW APPS.XX_XRTX_AP_INV_TXN_VS_OU_V4;

/* Formatted on 6/6/2016 4:57:22 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_VS_OU_V4
(
   OPERATING_UNIT,
   YEAR,
   VALIDATION_STATUS,
   NEEDS_REVALIDATION_COUNT
)
AS
     SELECT d.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            DECODE (MATCH_STATUS_FLAG,
                    'A', 'Validated',
                    'N', 'Never Validated',
                    NULL, 'Never Validated',
                    'S', 'Selected for Payment',
                    'Needs Revalidation')
               validation_status,
            COUNT (*) needs_revalidation_count
       FROM ap_invoices_all A,
            ap_invoice_distributions_all b,
            ap_holds_all c,
            hr_all_organization_units d
      WHERE     A.INVOICE_ID = b.invoice_id
            AND A.invoice_id = c.invoice_id
            AND A.org_id = d.organization_id
            AND b.MATCH_STATUS_FLAG = 'T'
            AND c.release_lookup_code IS NOT NULL
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY d.name,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY'),
            DECODE (MATCH_STATUS_FLAG,
                    'A', 'Validated',
                    'N', 'Never Validated',
                    NULL, 'Never Validated',
                    'S', 'Selected for Payment',
                    'Needs Revalidation')
   ORDER BY 2 DESC;
