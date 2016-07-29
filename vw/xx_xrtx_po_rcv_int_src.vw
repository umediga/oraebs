DROP VIEW APPS.XX_XRTX_PO_RCV_INT_SRC;

/* Formatted on 6/6/2016 4:55:17 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_RCV_INT_SRC
(
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
   SELECT b.user_concurrent_program_name concurrent_program_name,
          TRUNC (A.creation_date) creation_date,
          TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
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
     FROM rcv_shipment_headers a, fnd_concurrent_programs_tl b
    WHERE     (A.program_id IS NOT NULL AND A.program_id NOT IN (-1, 0))
          AND a.program_id = b.concurrent_program_id
          AND b.language = 'US';
