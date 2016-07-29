DROP VIEW APPS.XX_XRTX_AP_INV_TXN_OU_CANCEL;

/* Formatted on 6/6/2016 4:57:45 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_OU_CANCEL
(
   OPERATING_UNIT,
   YEAR,
   CANCELLED_COUNT
)
AS
     SELECT c.NAME operating_unit,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            COUNT (*) cancelled_count
       FROM ap_invoices_all b, hr_all_organization_units c
      WHERE     b.org_id = c.organization_id
            AND b.cancelled_date IS NOT NULL
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.name, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 2 DESC;
