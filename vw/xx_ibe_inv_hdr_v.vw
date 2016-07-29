DROP VIEW APPS.XX_IBE_INV_HDR_V;

/* Formatted on 6/6/2016 4:58:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_IBE_INV_HDR_V
(
   TRX_NUMBER,
   TRX_DATE,
   INVOICE_CURRENCY_CODE,
   TYPE,
   PO_NUMBER,
   WAYBILL_NUMBER,
   DUE_DATE,
   AMOUNT_DUE_ORIGINAL,
   AMOUNT_DUE_REMAINING,
   AMOUNT_LINE_ITEMS_ORIGINAL,
   TAX_ORIGINAL,
   FREIGHT_ORIGINAL,
   AMOUNT_ADJUSTED,
   AMOUNT_APPLIED,
   AMOUNT_CREDITED,
   DISCOUNT_TAKEN_EARNED,
   SHIP_VIA,
   PARTY_ID,
   CUSTOMER_TRX_ID,
   CUST_ACCOUNT_ID,
   CREATED_BY,
   INTERFACE_HEADER_ATTRIBUTE1,
   ORG_ID
)
AS
   SELECT ct.trx_number,
          ct.trx_date,
          ct.invoice_currency_code,
          al_class.meaning TYPE,
          ct.purchase_order po_number,
          ct.waybill_number,
          ps.due_date due_date,
          ps.amount_due_original,
          ps.amount_due_remaining,
          ps.amount_line_items_original,
          ps.tax_original,
          ps.freight_original,
          ps.amount_adjusted,
          ps.amount_applied,
          ps.amount_credited,
          ps.discount_taken_earned,
          ct.ship_via,
          acct.party_id party_id,
          ct.customer_trx_id customer_trx_id,
          acct.cust_account_id cust_account_id,
          ct.created_by,
          ct.interface_header_attribute1,
          ct.org_id org_id
     FROM ar_payment_schedules_all ps,
          ra_customer_trx_all ct,
          ar_lookups al_class,
          hz_cust_accounts acct
    WHERE     ps.customer_trx_id = ct.customer_trx_id
          AND ps.class = al_class.lookup_code
          AND al_class.lookup_type = 'INV/CM'
          AND ct.bill_to_customer_id = acct.cust_account_id
   UNION
   SELECT ct.trx_number,
          ct.trx_date,
          ct.invoice_currency_code,
          al_class.meaning TYPE,
          ct.purchase_order po_number,
          ct.waybill_number,
          ps.due_date due_date,
          ps.amount_due_original,
          ps.amount_due_remaining,
          ps.amount_line_items_original,
          ps.tax_original,
          ps.freight_original,
          ps.amount_adjusted,
          ps.amount_applied,
          ps.amount_credited,
          ps.discount_taken_earned,
          ct.ship_via,
          acct.party_id party_id,
          ct.customer_trx_id customer_trx_id,
          ship.orig_cust_account_id Cust_account_id,
          ct.created_by,
          ct.interface_header_attribute1,
          ct.org_id org_id
     FROM ar_payment_schedules_all ps,
          ra_customer_trx_all ct,
          ar_lookups al_class,
          hz_cust_accounts acct,
          (SELECT hr.subject_id, hca.cust_account_id orig_cust_account_id
             FROM hz_parties hzp, hz_cust_accounts hca, hz_relationships hr
            WHERE     hr.object_id = hzp.party_id
                  AND hzp.party_id = hca.party_id
                  AND HR.RELATIONSHIP_CODE = 'Member Account of'
                  AND HR.STATUS = 'A'
                  AND (   (TRUNC (SYSDATE) BETWEEN start_date AND end_date)
                       OR end_date IS NULL)) ship
    WHERE     ps.customer_trx_id = ct.customer_trx_id
          AND ps.class = al_class.lookup_code
          AND al_class.lookup_type = 'INV/CM'
          AND ct.bill_to_customer_id = acct.cust_account_id
          AND acct.party_id = ship.subject_id;
