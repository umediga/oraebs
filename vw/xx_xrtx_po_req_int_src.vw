DROP VIEW APPS.XX_XRTX_PO_REQ_INT_SRC;

/* Formatted on 6/6/2016 4:55:00 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_INT_SRC
(
   CONCURRENT_PRORAM_NAME,
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
   SELECT b.user_concurrent_program_name concurrent_proram_name,
          TRUNC (A.creation_date) creation_date,
          TO_CHAR (TRUNC (a.creation_date), 'YYYY') year,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 1 THEN 1 END A,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 2 THEN 1 END B,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 3 THEN 1 END C,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 4 THEN 1 END D,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 5 THEN 1 END E,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 6 THEN 1 END F,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 7 THEN 1 END G,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 8 THEN 1 END H,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 9 THEN 1 END I,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 10 THEN 1 END J,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 11 THEN 1 END K,
          CASE WHEN EXTRACT (MONTH FROM A.creation_date) = 12 THEN 1 END L
     FROM po_requisition_headers_all a, fnd_concurrent_programs_tl b
    WHERE     a.program_id IS NOT NULL
          AND a.program_id = b.concurrent_program_id
          AND b.language = 'US';
