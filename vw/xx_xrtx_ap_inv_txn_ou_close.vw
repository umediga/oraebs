DROP VIEW APPS.XX_XRTX_AP_INV_TXN_OU_CLOSE;

/* Formatted on 6/6/2016 4:57:45 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_OU_CLOSE
(
   OPERATING_UNIT,
   YEAR,
   CLOSED_COUNT
)
AS
     SELECT c.NAME operating_unit,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            COUNT (*) closed_count
       FROM ap_invoices_all b, hr_all_organization_units c
      WHERE     b.org_id = c.organization_id
            AND b.payment_status_flag IN ('Y')
            AND b.cancelled_date IS NULL
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.NAME, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 2 DESC;
