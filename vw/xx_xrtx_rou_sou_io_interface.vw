DROP VIEW APPS.XX_XRTX_ROU_SOU_IO_INTERFACE;

/* Formatted on 6/6/2016 4:54:14 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_ROU_SOU_IO_INTERFACE
(
   SOURCE,
   ORGANIZATION_ID,
   INVENTORY_ORGANIZATION,
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
     SELECT c.user_concurrent_program_name SOURCE,
            a.organization_id,
            b.name inventory_organization,
            TRUNC (a.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') year,
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
       FROM bom_operational_routings A,
            hr_all_organization_units b,
            fnd_concurrent_programs_tl c
      WHERE     A.organization_id = b.organization_id
            AND a.REQUEST_ID IS NOT NULL
            AND a.PROGRAM_ID IS NOT NULL
            AND a.PROGRAM_APPLICATION_ID IS NOT NULL
            AND a.PROGRAM_APPLICATION_ID IS NOT NULL
            AND c.concurrent_program_id <> 0
   ORDER BY 1, 3;
