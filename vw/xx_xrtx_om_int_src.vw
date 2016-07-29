DROP VIEW APPS.XX_XRTX_OM_INT_SRC;

/* Formatted on 6/6/2016 4:56:38 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OM_INT_SRC
(
   SOURCE_NAME,
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
   SELECT                                               -- A.org_id AS org_id,
          --b.NAME operating_unit,
          c.NAME source_name,
          TRUNC (A.creation_date) creation_date,
          TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L --"DEC",
     FROM oe_order_headers_all A,               --hr_all_organization_units b,
                                 OE_ORDER_SOURCES c
    WHERE     A.order_source_id = c.order_source_id(+)
          AND c.NAME NOT IN ('Online', 'Copy');
