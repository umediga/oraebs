DROP VIEW APPS.XX_XRTX_AP_INV_TXN_OU_WISE_V;

/* Formatted on 6/6/2016 4:57:35 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_AP_INV_TXN_OU_WISE_V
(
   OPERATING_UNIT,
   YEAR,
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
     FROM ap_invoices_all b, hr_all_organization_units c
    WHERE b.org_id = c.organization_id
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'Cancel' total_type,
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
     FROM ap_invoices_all b, hr_all_organization_units c
    WHERE b.org_id = c.organization_id AND b.cancelled_date IS NOT NULL
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'Open' total_type,
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
     FROM ap_invoices_all b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.payment_status_flag IN ('N', 'P')
          AND b.cancelled_date IS NULL
   UNION ALL
   SELECT c.NAME operating_unit,
          TO_CHAR (TRUNC (b.creation_date), 'YYYY') YEAR,
          'Close' total_type,
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
     FROM ap_invoices_all b, hr_all_organization_units c
    WHERE     b.org_id = c.organization_id
          AND b.payment_status_flag IN ('Y')
          AND b.cancelled_date IS NULL;
