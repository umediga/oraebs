DROP VIEW APPS.XX_XRTX_SHIPMENT_CUSTOMER_INFO;

/* Formatted on 6/6/2016 4:54:13 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SHIPMENT_CUSTOMER_INFO
(
   ORG_ID,
   ORGANIZATION_NAME,
   CUSTOMER,
   REQUEST_DATE,
   YEAR,
   CAL_MON,
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
     SELECT oola.org_id AS Org_id,
            hou.NAME organization_name,
            HP.PARTY_NAME CUSTOMER,
            TRUNC (oola.request_date) request_date,
            TO_CHAR (TRUNC (oola.actual_shipment_date), 'YYYY') YEAR,
            TO_CHAR (TRUNC (OOLA.actual_shipment_date), 'MON') cal_mon,
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) <= 3
               THEN
                  1
            END
               "A",                                                  --"3HRS",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 3
                              AND 6
               THEN
                  1
            END
               "B",                                                  --"6HRS",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 6
                              AND 12
               THEN
                  1
            END
               "C",                                                 --"12HRS",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 12
                              AND 24
               THEN
                  1
            END
               "D",                                                 --"24HRS",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 24
                              AND 72
               THEN
                  1
            END
               "E",                                                 --"3Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 72
                              AND 120
               THEN
                  1
            END
               "F",                                                 --"5Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 120
                              AND 168
               THEN
                  1
            END
               "G",                                                 --"7Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 168
                              AND 240
               THEN
                  1
            END
               "H",                                                --"10Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 240
                              AND 360
               THEN
                  1
            END
               "I",                                                --"15Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) BETWEEN 360
                              AND 480
               THEN
                  1
            END
               "J",                                                --"20Days",
            CASE
               WHEN ROUND (
                       (oola.actual_shipment_date - oola.promise_date) * 24,
                       2) > 480
               THEN
                  1
            END
               "K"                                                  --"21Days"
       FROM OE_ORDER_HEADERS_ALL ooha,
            OE_ORDER_LINES_ALL OOLA,
            hr_all_organization_units hou,
            HZ_CUST_SITE_USES_ALL HCSUA,         -- uses of customer addresses
            HZ_CUST_ACCT_SITES_ALL HCASA,                -- customer addresses
            HZ_CUST_ACCOUNTS HCA,                         -- customer accounts
            HZ_PARTIES HP
      WHERE     OOLA.CANCELLED_FLAG = 'N'
            AND OOLA.OPEN_FLAG = 'N'
            AND OOHA.ORG_ID = hou.ORGANIZATION_ID
            AND OOLA.PROMISE_DATE < OOLA.ACTUAL_SHIPMENT_DATE
            AND OOLA.LINE_CATEGORY_CODE <> 'RETURN'
            AND ooha.SHIP_TO_ORG_ID = HCSUA.SITE_USE_ID -- or a.invoice_to_org_id
            AND ooha.HEADER_ID = OOLA.HEADER_ID
            AND HCSUA.cust_acct_site_id = HCASA.cust_acct_site_id
            AND HCASA.CUST_ACCOUNT_ID = HCA.CUST_ACCOUNT_ID
            AND HCA.PARTY_ID = HP.PARTY_ID
   ORDER BY 1, 3, 4;
