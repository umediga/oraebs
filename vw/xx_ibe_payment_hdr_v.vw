DROP VIEW APPS.XX_IBE_PAYMENT_HDR_V;

/* Formatted on 6/6/2016 4:58:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_IBE_PAYMENT_HDR_V
(
   CASH_RECEIPT_ID,
   RECEIPT_NUMBER,
   CUST_ACCOUNT_ID,
   CUSTOMER_NAME,
   AMOUNT,
   TYPE,
   APPLIED_AMOUNT,
   RECEIPT_DATE,
   DUE_DATE,
   CURRENCY_CODE,
   UNAPPLIED_AMOUNT,
   PARTY_ID,
   CREATED_BY,
   ORG_ID
)
AS
     SELECT cr.cash_receipt_id,
            cr.receipt_number,
            acct.cust_account_id,
            cust.party_name,
            cr.amount,
            al_pay_type.meaning TYPE,
            ABS (ps.amount_applied),
            cr.receipt_date,
            ps.due_date,
            cr.currency_code currency_code,
            SUM (DECODE (ra.status, 'UNAPP', NVL (ra.amount_applied, 0), 0))
               unapplied_amount,
            cust.party_id party_id,
            cr.created_by,
            ps.org_id org_id
       FROM ar_lookups al_pay_type,
            hz_cust_accounts acct,
            hz_parties cust,
            ar_payment_schedules_all ps,
            ar_receivable_applications_all ra,
            ar_cash_receipts_all cr
      WHERE     cr.pay_from_customer = acct.cust_account_id(+)
            AND acct.party_id = cust.party_id
            AND ps.cash_receipt_id(+) = cr.cash_receipt_id
            AND cr.cash_receipt_id = ra.cash_receipt_id(+)
            AND al_pay_type.lookup_type = 'PAYMENT_CATEGORY_TYPE'
            AND cr.TYPE = al_pay_type.lookup_code
   GROUP BY cr.cash_receipt_id,
            cr.receipt_number,
            acct.cust_account_id,
            cust.party_name,
            cr.amount,
            al_pay_type.meaning,
            ps.amount_applied,
            cr.currency_code,
            cr.receipt_date,
            ps.due_date,
            cust.party_id,
            cr.created_by,
            ps.org_id
   UNION
     SELECT cr.cash_receipt_id,
            cr.receipt_number,
            ship.orig_cust_account_id Cust_account_id,
            cust.party_name,
            cr.amount,
            al_pay_type.meaning TYPE,
            ABS (ps.amount_applied),
            cr.receipt_date,
            ps.due_date,
            cr.currency_code currency_code,
            SUM (DECODE (ra.status, 'UNAPP', NVL (ra.amount_applied, 0), 0))
               unapplied_amount,
            cust.party_id party_id,
            cr.created_by,
            ps.org_id org_id
       FROM ar_lookups al_pay_type,
            hz_cust_accounts acct,
            hz_parties cust,
            ar_payment_schedules_all ps,
            ar_receivable_applications_all ra,
            ar_cash_receipts_all cr,
            (SELECT hr.subject_id, hca.cust_account_id orig_cust_account_id
               FROM hz_parties hzp, hz_cust_accounts hca, hz_relationships hr
              WHERE     hr.object_id = hzp.party_id
                    AND hzp.party_id = hca.party_id
                    AND HR.RELATIONSHIP_CODE = 'Member Account of'
                    AND HR.STATUS = 'A'
                    AND (   (TRUNC (SYSDATE) BETWEEN start_date AND end_date)
                         OR end_date IS NULL)) ship
      WHERE     cr.pay_from_customer = acct.cust_account_id(+)
            AND acct.party_id = cust.party_id
            AND cust.party_id = ship.subject_id
            AND ps.cash_receipt_id(+) = cr.cash_receipt_id
            AND cr.cash_receipt_id = ra.cash_receipt_id(+)
            AND al_pay_type.lookup_type = 'PAYMENT_CATEGORY_TYPE'
            AND cr.TYPE = al_pay_type.lookup_code
   GROUP BY cr.cash_receipt_id,
            cr.receipt_number,
            ship.orig_cust_account_id,
            cust.party_name,
            cr.amount,
            al_pay_type.meaning,
            ps.amount_applied,
            cr.currency_code,
            cr.receipt_date,
            ps.due_date,
            cust.party_id,
            cr.created_by,
            ps.org_id;
