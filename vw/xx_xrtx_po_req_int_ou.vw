DROP VIEW APPS.XX_XRTX_PO_REQ_INT_OU;

/* Formatted on 6/6/2016 4:55:01 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_PO_REQ_INT_OU
(
   ORG_ID,
   OPERATING_UNIT,
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
   SELECT A.org_id AS org_id,
          b.NAME operating_unit,
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
     FROM po_requisition_headers_all A, hr_all_organization_units b
    WHERE A.org_id = b.organization_id AND a.program_id IS NOT NULL;
