DROP VIEW APPS.XX_XRTX_GL_INT_V;

/* Formatted on 6/6/2016 4:56:42 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_GL_INT_V
(
   LEDGERNAME,
   JE_SOURCE,
   JE_CATEGORY,
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
   SELECT ldg.NAME ledgername,
          gljh.je_source,
          gljh.je_category,
          TRUNC (gljh.creation_date) creation_date,
          TO_CHAR (TRUNC (gljh.creation_date), 'YYYY') year,
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 1 THEN 1 END A, --"JAN",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 2 THEN 1 END B, --"FEB",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 3 THEN 1 END C, --"MAR",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 4 THEN 1 END D, --"APR",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 5 THEN 1 END E, --"MAY",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 6 THEN 1 END F, --"JUN",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 7 THEN 1 END G, --"JUL",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 8 THEN 1 END H, --"AUG",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 9 THEN 1 END I, --"SEP",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 10 THEN 1 END J, --"OCT",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 11 THEN 1 END K, --"NOV",
          CASE WHEN EXTRACT (MONTH FROM gljh.creation_date) = 12 THEN 1 END L --"DEC",
     FROM gl_je_headers gljh, gl_ledgers ldg             --,gl_je_sources gljs
    WHERE gljh.ledger_id = ldg.ledger_id AND gljh.je_source <> 'Manual';
