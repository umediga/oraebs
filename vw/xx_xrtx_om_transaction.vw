DROP VIEW APPS.XX_XRTX_OM_TRANSACTION;

/* Formatted on 6/6/2016 4:56:37 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_OM_TRANSACTION
(
   ORG_ID,
   OPERATING_UNIT,
   SOURCE_NAME,
   TRANSACTION_TYPE,
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
            c.NAME source_name,
            d.transaction_type_code transaction_type,
            TRUNC (A.creation_date) creation_date,
            TO_CHAR (TRUNC (A.creation_date), 'YYYY') YEAR,
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
       FROM oe_order_headers_all A,
            hr_operating_units b,
            OE_ORDER_SOURCES c,
            OE_TRANSACTION_TYPES_ALL d
      WHERE     A.org_id = b.organization_id
            AND A.order_source_id = c.order_source_id
            AND A.ORDER_TYPE_ID = d.transaction_TYPE_ID
   ORDER BY 2, 3, 4;
