DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V2;

/* Formatted on 6/6/2016 4:57:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_V2
(
   OPERATING_UNIT,
   UNID_COUNT,
   YEAR
)
AS
     SELECT c.NAME operating_unit,
            COUNT (*) UNID_count,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR
       FROM fnd_concurrent_programs_tl A,
            AR_CASH_RECEIPTS_ALL b,
            hr_all_organization_units c
      WHERE     A.concurrent_program_id = b.program_id
            AND b.program_id IS NOT NULL
            AND A.language = 'US'
            AND b.org_id = c.organization_id
            AND B.STATUS IN ('UNID')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.NAME, TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 3 DESC;
