DROP VIEW APPS.XX_XRTX_TOP_CUST_ORD_T;

/* Formatted on 6/6/2016 4:54:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_TOP_CUST_ORD_T
(
   PARTY_NAME,
   NAME,
   ORDER_CNT
)
AS
     SELECT hp.party_name, hou.name, COUNT (*) ORDER_CNT
       FROM oe_order_headers_all oha,
            hz_cust_accounts_all hca,
            hz_parties hp,
            hr_operating_units hou
      WHERE     (oha.cancelled_flag IS NOT NULL OR oha.Cancelled_flag <> 'Y')
            AND hca.cust_account_id = oha.sold_to_org_id
            AND hp.party_id = hca.party_id
            AND hou.organization_id = oha.org_id
            AND oha.ORDER_CATEGORY_CODE = 'ORDER'
            AND oha.ordered_date BETWEEN SYSDATE - 800 AND SYSDATE
   GROUP BY hou.name, hp.party_name, hp.party_id
   ORDER BY 3 DESC;
