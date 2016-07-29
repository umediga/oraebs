DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V6;

/* Formatted on 6/6/2016 4:57:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V6
(
   OPERATING_UNIT,
   CONCURRENT_PROGRAM_NAME,
   UNID_COUNT,
   YEAR
)
AS
     SELECT c.NAME operating_unit,
            'MANUAL' CONCURRENT_PROGRAM_NAME,
            COUNT (*) UNID_count,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR
       FROM AR_CASH_RECEIPTS_ALL b, hr_all_organization_units c
      WHERE     b.org_id = c.organization_id
            AND b.program_id IS NULL
            AND B.STATUS IN ('UNID')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.NAME, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 4 DESC;
