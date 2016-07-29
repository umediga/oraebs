DROP VIEW APPS.XX_XRTX_ORD_TYPE_DELAY_V;

/* Formatted on 6/6/2016 4:56:34 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_ORD_TYPE_DELAY_V
(
   NAME,
   ORDER_CATEGORY_CODE,
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
     SELECT b.name,
            ooha.order_category_code,
            EXTRACT (YEAR FROM oola.actual_shipment_date) YEAR,
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 1 THEN 1
            END
               "A",                                                   --"JAN",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 2 THEN 1
            END
               "B",                                                   --"FEB",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 3 THEN 1
            END
               "C",                                                   --"MAR",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 4 THEN 1
            END
               "D",                                                   --"APR",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 5 THEN 1
            END
               "E",                                                   --"MAY",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 6 THEN 1
            END
               "F",                                                   --"JUN",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 7 THEN 1
            END
               "G",                                                   --"JUL",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 8 THEN 1
            END
               "H",                                                   --"AUG",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 9 THEN 1
            END
               "I",                                                   --"SEP",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 10 THEN 1
            END
               "J",                                                   --"OCT",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 11 THEN 1
            END
               "K",                                                   --"NOV",
            CASE
               WHEN EXTRACT (MONTH FROM oola.actual_shipment_date) = 12 THEN 1
            END
               "L"                                                    --"DEC",
       FROM OE_ORDER_HEADERS_ALL ooha,
            oe_order_lines_all OOLA,
            oe_transaction_types_tl b,
            hr_all_organization_units hou
      WHERE     OOLA.cancelled_flag = 'N'
            AND OOLA.open_flag = 'N'
            AND OOHA.ORDER_TYPE_ID = b.TRANSACTION_TYPE_ID
            AND b.LANGUAGE = 'US'
            AND ooha.HEADER_ID = OOLA.HEADER_ID
            AND OOHA.ORG_ID = hou.ORGANIZATION_ID
            AND OOLA.promise_date < oola.actual_shipment_date
            AND OOLA.line_category_code <> 'RETURN'
            AND TRUNC (oola.request_date) BETWEEN TO_DATE (
                                                     (   '01-JAN-'
                                                      || (  TO_CHAR (SYSDATE,
                                                                     'YYYY')
                                                          - 3)),
                                                     'DD-MON-YYYY')
                                              AND SYSDATE --SYSDATE-730 AND SYSDATE
   GROUP BY b.name,
            ooha.order_category_code,
            oola.promise_date,
            oola.actual_shipment_date
   ORDER BY 3 DESC;
