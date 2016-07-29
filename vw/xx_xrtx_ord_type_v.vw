DROP VIEW APPS.XX_XRTX_ORD_TYPE_V;

/* Formatted on 6/6/2016 4:56:33 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_ORD_TYPE_V
(
   NAME,
   ORDER_CATEGORY_CODE,
   YEAR,
   A,
   B,
   C1,
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
     SELECT b.name,
            oha.order_category_code,
            EXTRACT (YEAR FROM oha.ordered_date) YEAR,
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 1 THEN 1 END "A", --"JAN",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 2 THEN 1 END "B", --"FEB",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 3 THEN 1 END "C1", --"MAR",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 4 THEN 1 END "D", --"APR",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 5 THEN 1 END "E", --"MAY",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 6 THEN 1 END "F", --"JUN",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 7 THEN 1 END "G", --"JUL",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 8 THEN 1 END "H", --"AUG",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 9 THEN 1 END "I", --"SEP",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 10 THEN 1 END "J", --"OCT",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 11 THEN 1 END "K", --"NOV",
            CASE WHEN EXTRACT (MONTH FROM oha.ordered_date) = 12 THEN 1 END "L" --"DEC",
       FROM oe_order_headers_all oha, oe_transaction_types_tl b
      WHERE     oha.booked_flag = 'Y'
            AND oha.ordered_date BETWEEN TO_DATE (
                                            CONCAT (
                                               '01-JAN-',
                                               (TO_CHAR (SYSDATE, 'YYYY') - 3)),
                                            'DD-MON-YYYY')
                                     AND SYSDATE
            AND oha.CANCELLED_FLAG <> 'Y'
            AND oha.order_type_id = b.transaction_type_id
            AND b.language = 'US'
   GROUP BY b.name, oha.order_category_code, oha.ordered_date
   ORDER BY 2 DESC;