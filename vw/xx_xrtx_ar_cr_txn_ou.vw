DROP VIEW APPS.XX_XRTX_AR_CR_TXN_OU;

/* Formatted on 6/6/2016 4:57:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AR_CR_TXN_OU
(
   OPERATING_UNIT,
   YEAR,
   CREATION_TYPE,
   TOTAL_TYPE,
   CREATION_DATE,
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
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Total' total_type,
          TRUNC (b.creation_date) creation_date,
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
          AND b.program_id IS NOT NULL
          AND A.language = 'US'
          AND b.org_id = c.organization_id
          AND B.STATUS IN ('UNID', 'UNAPP', 'APP')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Unidentified' total_type,
          TRUNC (b.creation_date) creation_date,
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
          AND b.program_id IS NOT NULL
          AND A.language = 'US'
          AND b.org_id = c.organization_id
          AND B.STATUS IN ('UNID')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Unapplied' total_type,
          TRUNC (b.creation_date) creation_date,
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
          AND b.program_id IS NOT NULL
          AND A.language = 'US'
          AND b.org_id = c.organization_id
          AND B.STATUS IN ('UNAPP')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'IMPORT' creation_type,
          'Applied' total_type,
          TRUNC (b.creation_date) creation_date,
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
          AND b.program_id IS NOT NULL
          AND A.language = 'US'
          AND b.org_id = c.organization_id
          AND B.STATUS IN ('APP')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Total' total_type,
          TRUNC (b.creation_date) creation_date,
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
     FROM AR_CASH_RECEIPTS_ALL b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.program_id IS NULL
          AND B.STATUS IN ('UNID', 'UNAPP', 'APP')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Unidentified' total_type,
          TRUNC (b.creation_date) creation_date,
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
     FROM AR_CASH_RECEIPTS_ALL b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.program_id IS NULL
          AND B.STATUS IN ('UNID')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Unapplied' total_type,
          TRUNC (b.creation_date) creation_date,
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
     FROM AR_CASH_RECEIPTS_ALL b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.program_id IS NULL
          AND B.STATUS IN ('UNAPP')
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'MANUAL' creation_type,
          'Applied' total_type,
          TRUNC (b.creation_date) creation_date,
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
     FROM AR_CASH_RECEIPTS_ALL b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.program_id IS NULL
          AND B.STATUS IN ('APP')
   ORDER BY 1,
            3,
            4,
            2 DESC;
