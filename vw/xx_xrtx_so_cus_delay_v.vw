DROP VIEW APPS.XX_XRTX_SO_CUS_DELAY_V;

/* Formatted on 6/6/2016 4:54:10 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SO_CUS_DELAY_V
(
   PARTY_NAME,
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
     SELECT hp.party_name,
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
            AND TRUNC (oola.request_date) BETWEEN TO_DATE (
                                                     (   '01-JAN-'
                                                      || (  TO_CHAR (SYSDATE,
                                                                     'YYYY')
                                                          - 3)),
                                                     'DD-MON-YYYY')
                                              AND SYSDATE --SYSDATE-730 AND SYSDATE
   GROUP BY hp.party_name,
            oola.promise_date,
            ooha.order_category_code,
            oola.actual_shipment_date
   ORDER BY 3 DESC;
