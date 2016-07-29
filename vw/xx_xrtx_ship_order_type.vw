DROP VIEW APPS.XX_XRTX_SHIP_ORDER_TYPE;

/* Formatted on 6/6/2016 4:54:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SHIP_ORDER_TYPE
(
   CAL_MON,
   REQUEST_DATE,
   YEAR,
   ORGANIZATION_NAME,
   ORDER_TYPE,
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
   K
)
AS
     SELECT TO_CHAR (TRUNC (OOLA.actual_shipment_date), 'MON') cal_mon,
            TRUNC (oola.request_date) request_date,
            TO_CHAR (TRUNC (OOLA.actual_shipment_date), 'YYYY') year,
            hou.name Organization_name,
            ott.NAME order_type,
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) <= 3
               THEN
                  1
            END
               "A",                                                  --"3HRS",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 3
                              AND 6
               THEN
                  1
            END
               "B",                                                  --"6HRS",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 6
                              AND 12
               THEN
                  1
            END
               "C",                                                 --"12HRS",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 12
                              AND 24
               THEN
                  1
            END
               "D",                                                 --"24HRS",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 24
                              AND 72
               THEN
                  1
            END
               "E",                                                 --"3Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 72
                              AND 120
               THEN
                  1
            END
               "F",                                                 --"5Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 120
                              AND 168
               THEN
                  1
            END
               "G",                                                 --"7Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 168
                              AND 240
               THEN
                  1
            END
               "H",                                                --"10Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 240
                              AND 360
               THEN
                  1
            END
               "I",                                                --"15Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) BETWEEN 360
                              AND 480
               THEN
                  1
            END
               "J",                                                --"20Days",
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) > 480
               THEN
                  1
            END
               "K"                                                  --"21Days"
       FROM OE_ORDER_HEADERS_ALL ooha,
            oe_order_lines_all OOLA,
            oe_transaction_types_tl ott,
            hr_all_organization_units hou
      WHERE     OOLA.cancelled_flag = 'N'
            AND OOLA.open_flag = 'N'
            AND OOHA.ORDER_TYPE_ID = OTT.TRANSACTION_TYPE_ID
            AND OTT.LANGUAGE = 'US'
            AND ooha.HEADER_ID = OOLA.HEADER_ID
            AND OOHA.ORG_ID = hou.ORGANIZATION_ID
            AND OOLA.promise_date < oola.actual_shipment_date
            AND OOLA.line_category_code <> 'RETURN'
   ORDER BY 1, 3, 4;
