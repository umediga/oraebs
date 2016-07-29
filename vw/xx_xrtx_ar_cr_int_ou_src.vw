DROP VIEW APPS.XX_XRTX_AR_CR_INT_OU_SRC;

/* Formatted on 6/6/2016 4:57:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_INT_OU_SRC
(
   OPERATING_UNIT,
   CONCURRENT_PROGRAM_NAME,
   CREATION_DATE,
   YEAR,
   A,
   B,
   C,
   D,
   E,
   F,
   G,
   H,
   I,
   J,
   K,
   L
)
AS
     SELECT c.NAME operating_unit,
            A.USER_CONCURRENT_PROGRAM_NAME CONCURRENT_PROGRAM_NAME,
            TRUNC (b.creation_date) creation_date,
            TO_CHAR (TRUNC (b.creation_date), 'YYYY') year,
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 1 THEN 1 END A, --"JAN",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 2 THEN 1 END B, --"FEB",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 3 THEN 1 END C, --"MAR",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 4 THEN 1 END D, --"APR",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 5 THEN 1 END E, --"MAY",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 6 THEN 1 END F, --"JUN",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 7 THEN 1 END G, --"JUL",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 8 THEN 1 END H, --"AUG",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 9 THEN 1 END I, --"SEP",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 10 THEN 1 END J, --"OCT",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 11 THEN 1 END K, --"NOV",
            CASE WHEN EXTRACT (MONTH FROM b.creation_date) = 12 THEN 1 END L --"DEC",
       FROM fnd_concurrent_programs_tl A,
            AR_CASH_RECEIPTS_ALL b,
            hr_all_organization_units c
      WHERE     A.concurrent_program_id = b.program_id
            AND A.language = 'US'
            AND b.org_id = c.organization_id
            AND b.program_id IS NOT NULL
            AND B.STATUS IN ('UNID', 'UNAPP', 'APP')
   ORDER BY 4 DESC;
