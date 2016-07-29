DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V3;

/* Formatted on 6/6/2016 4:57:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU_SRC_V3
(
   OPERATING_UNIT,
   CONCURRENT_PROGRAM_NAME,
   UNAPP_COUNT,
   YEAR
)
AS
     SELECT c.NAME operating_unit,
            A.USER_CONCURRENT_PROGRAM_NAME CONCURRENT_PROGRAM_NAME,
            COUNT (*) UNAPP_count,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR
       FROM fnd_concurrent_programs_tl A,
            AR_CASH_RECEIPTS_ALL b,
            hr_all_organization_units c
      WHERE     A.concurrent_program_id = b.program_id
            AND b.program_id IS NOT NULL
            AND A.language = 'US'
            AND b.org_id = c.organization_id
            AND B.STATUS IN ('UNAPP')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY c.NAME,
            A.USER_CONCURRENT_PROGRAM_NAME,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 4 DESC;
