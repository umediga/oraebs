DROP VIEW APPS.XX_XRTX_TOP_CUST_INV_T;

/* Formatted on 6/6/2016 4:54:06 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_XRTX_TOP_CUST_INV_T
(
   PARTY_NAME,
   NAME,
   INVOICE_COUNT
)
AS
     SELECT hp.party_name, hou.name, COUNT (ra.trx_number) INVOICE_COUNT
       FROM ra_customer_trx_all ra,
            hz_cust_accounts hc,
            ar_payment_schedules_all aps,
            hz_parties hp,
            hr_operating_units hou
      WHERE     ra.bill_to_customer_id = hc.cust_account_id
            AND ra.customer_trx_id = aps.customer_trx_id
            AND ra.org_id = aps.org_id
            AND ra.org_id = hou.organization_id
            AND ra.complete_flag = 'Y'
            AND hc.party_id = hp.party_id
            AND hc.status = 'A'
            AND aps.amount_due_remaining <> 0
            AND aps.status = 'OP'
            AND aps.class = 'INV'
            AND ra.trx_date BETWEEN SYSDATE - 800 AND SYSDATE
   GROUP BY hp.party_name, hou.name, hou.organization_id
   ORDER BY 3 DESC;
