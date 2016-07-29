DROP VIEW APPS.XX_XRTX_SHIPMENT_DELAY;

/* Formatted on 6/6/2016 4:54:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SHIPMENT_DELAY
(
   CAL_MON,
   ORGANIZATION_NAME,
   REQUEST_DATE,
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
   K
)
AS
     SELECT TO_CHAR (OOLA.actual_shipment_date, 'MON') cal_mon,
            hou.name organization_name,
            TRUNC (oola.request_date) request_date,
            TO_CHAR (TRUNC (OOLA.actual_shipment_date), 'YYYY') year,
            CASE
               WHEN ROUND (
                       (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                       2) <= 3
               THEN
                  1
            END
               "A",                                                  --"3HRS",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 3
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) <= 6
               THEN
                  1
            END
               "B",                                                  --"6HRS",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 6
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) <= 12
               THEN
                  1
            END
               "C",                                                 --"12HRS",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 12
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 24
               THEN
                  1
            END
               "D",                                                 --"24HRS",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 24
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 72
               THEN
                  1
            END
               "E",                                                 --"3Days",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 72
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 120
               THEN
                  1
            END
               "F",                                                 --"5Days",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 120
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 168
               THEN
                  1
            END
               "G",                                                 --"7Days",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 168
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 240
               THEN
                  1
            END
               "H",                                                --"10Days",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 120
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 360
               THEN
                  1
            END
               "I",                                                --"15Days",
            CASE
               WHEN     ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) > 360
                    AND ROUND (
                           (OOLA.actual_shipment_date - OOLA.promise_date) * 24,
                           2) < 480
               THEN
                  1
            END
               "J",                                                --"20Days",
            CASE
               WHEN ROUND ( (actual_shipment_date - promise_date) * 24, 2) >
                       480
               THEN
                  1
            END
               "K"                                                  --"21Days"
       FROM oe_order_lines_all OOLA,
            OE_ORDER_HEADERS_ALL ooha,
            hr_all_organization_units hou
      WHERE     OOLA.cancelled_flag = 'N'
            AND OOLA.open_flag = 'N'
            AND ooha.HEADER_ID = OOLA.HEADER_ID
            AND OOHA.ORG_ID = hou.ORGANIZATION_ID
            AND OOLA.promise_date < OOLA.actual_shipment_date
            AND OOLA.LINE_CATEGORY_CODE <> 'RETURN'
   ORDER BY 1, 2, 3;
