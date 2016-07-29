DROP VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V8;

/* Formatted on 6/6/2016 4:57:03 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_SRC_V8
(
   CONCURRENT_PROGRAM_NAME,
   APP_COUNT,
   YEAR
)
AS
     SELECT 'MANUAL' CONCURRENT_PROGRAM_NAME,
            COUNT (*) APP_count,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR
       FROM AR_CASH_RECEIPTS_ALL b
      WHERE     b.program_id IS NULL
            AND B.STATUS IN ('APP')
            AND TRUNC (b.creation_date) BETWEEN TO_DATE (
                                                   (   '01-JAN-'
                                                    || (  TO_CHAR (SYSDATE,
                                                                   'YYYY')
                                                        - 3)),
                                                   'DD-MON-YYYY')
                                            AND SYSDATE
   GROUP BY TO_CHAR (TRUNC (b.creation_date), 'YYYY')
   ORDER BY 3 DESC;
