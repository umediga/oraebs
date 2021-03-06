DROP VIEW APPS.XX_XRTX_SO_CAN_ORDER_V;

/* Formatted on 6/6/2016 4:54:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_SO_CAN_ORDER_V
(
   NAME,
   CANCELLED_FLAG,
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
     SELECT hou.name,
            oha.CANCELLED_FLAG,
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
       FROM oe_order_headers_all oha,
            hz_cust_accounts_all hca,
            hz_parties hp,
            hr_operating_units hou
      WHERE     hca.cust_account_id = oha.sold_to_org_id
            AND hp.party_id = hca.party_id
            AND hou.organization_id = oha.org_id
            AND oha.CANCELLED_FLAG = 'Y'
            AND oha.ordered_date BETWEEN TO_DATE (
                                            CONCAT (
                                               '01-JAN-',
                                               (TO_CHAR (SYSDATE, 'YYYY') - 3)),
                                            'DD-MON-YYYY')
                                     AND SYSDATE
   GROUP BY hou.name, oha.ordered_date, CANCELLED_FLAG
   ORDER BY 3 DESC;
