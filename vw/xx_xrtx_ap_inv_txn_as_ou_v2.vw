DROP VIEW APPS.XX_XRTX_AP_INV_TXN_AS_OU_V2;

/* Formatted on 6/6/2016 4:57:50 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_AS_OU_V2
(
   OPERATING_UNIT,
   YEAR,
   NOT_REQ_COUNT
)
AS
     SELECT b.name operating_unit,
            TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
            COUNT (*) not_req_count
       FROM ap_invoices_all A, hr_all_organization_units b
      WHERE     A.org_id = b.organization_id
            AND a.wfapproval_status = 'NOT REQUIRED'
            AND TRUNC (A.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY b.NAME, TO_CHAR (TRUNC (A.creation_date), 'YYYY')
   ORDER BY 2 DESC;