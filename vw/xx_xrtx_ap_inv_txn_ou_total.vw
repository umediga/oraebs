DROP VIEW APPS.XX_XRTX_AP_INV_TXN_OU_TOTAL;

/* Formatted on 6/6/2016 4:57:43 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_OU_TOTAL
(
   OPERATING_UNIT,
   YEAR,
   TOTAL_COUNT
)
AS
     SELECT c.NAME operating_unit,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            COUNT (*) total_count
       FROM ap_invoices_all b, hr_all_organization_units c
      WHERE     b.org_id = c.organization_id
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.NAME, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 2 DESC;
