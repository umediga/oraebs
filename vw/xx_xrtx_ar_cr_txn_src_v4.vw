DROP VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V4;

/* Formatted on 6/6/2016 4:57:05 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V4
(
   CONCURRENT_PROGRAM_NAME,
   APP_COUNT,
   YEAR
)
AS
     SELECT A.USER_CONCURRENT_PROGRAM_NAME CONCURRENT_PROGRAM_NAME,
            COUNT (*) APP_count,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR
       FROM fnd_concurrent_programs_tl A, AR_CASH_RECEIPTS_ALL b
      WHERE     A.concurrent_program_id = b.program_id
            AND b.program_id IS NOT NULL
            AND A.language = 'US'
            AND B.STATUS IN ('APP')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY A.USER_CONCURRENT_PROGRAM_NAME,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 3 DESC;
