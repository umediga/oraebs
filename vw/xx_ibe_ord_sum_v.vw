DROP VIEW APPS.XX_IBE_ORD_SUM_V;

/* Formatted on 6/6/2016 4:58:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_IBE_ORD_SUM_V
(
   HEADER_ID,
   CREATED_BY,
   REFERENCE_NUMBER,
   WEB_CONFIRM_NUMBER,
   ORDER_NUMBER,
   ORDERED_DATE,
   ORDER_STATUS,
   CUST_ACCOUNT_ID,
   PARTY_ID,
   CUSTOMER_NAME,
   CUST_PO_NUMBER,
   CREDIT_CARD_NUMBER,
   ORDER_CATEGORY_CODE,
   BOOKED_DATE,
   SOLD_TO_CONTACT_ID,
   CANCELLED_FLAG,
   OPEN_FLAG,
   BOOKED_FLAG,
   SOURCE_DOCUMENT_ID,
   SOURCE_DOCUMENT_TYPE_ID,
   MEANING,
   BILL_TO_ACCOUNT_ID,
   BILL_TO_ACCT_SITE_ID,
   ORG_ID
)
AS
   SELECT oh.header_id,
          oh.created_by,
          oh.source_document_id,
          oh.orig_sys_document_ref,
          oh.order_number,
          oh.ordered_date,
          oh.flow_status_code order_status,
          oh.sold_to_org_id Cust_account_id,
          cust.party_id,
          cust.party_name customer_name,
          oh.cust_po_number,
          SUBSTR (oh.credit_card_number,
                  (LENGTH (oh.credit_card_number) - 3),
                  4),
          oh.order_category_code,
          oh.booked_date,
          oh.sold_to_contact_id,
          oh.cancelled_flag,
          oh.open_flag,
          oh.booked_flag,
          oh.source_document_id,
          oh.source_document_type_id,
          oel.meaning,
          hcs.cust_account_id,
          hcsu.cust_acct_site_id,
          oh.org_id org_id
     FROM oe_order_headers_all oh,
          hz_cust_accounts acct,
          hz_parties cust,
          oe_lookups oel,
          hz_cust_site_uses_all hcsu,
          hz_cust_acct_sites_all hcs
    WHERE     oh.sold_to_org_id = acct.cust_account_id
          AND acct.party_id = cust.party_id
          AND oel.lookup_code = oh.flow_status_code
          AND oel.lookup_type = 'FLOW_STATUS'
          AND oh.invoice_to_org_id = hcsu.site_use_id(+)
          AND Hcsu.Cust_Acct_Site_Id = Hcs.Cust_Acct_Site_Id(+)
   UNION
   SELECT oh.header_id,
          oh.created_by,
          oh.source_document_id,
          oh.orig_sys_document_ref,
          oh.order_number,
          oh.ordered_date,
          Oh.Flow_Status_Code Order_Status,
          ship.orig_cust_account_id Cust_account_id, --referred original id commented oh.sold_to_org_id  ,
          cust.party_id,
          cust.party_name customer_name,
          oh.cust_po_number,
          SUBSTR (oh.credit_card_number,
                  (LENGTH (oh.credit_card_number) - 3),
                  4),
          oh.order_category_code,
          oh.booked_date,
          oh.sold_to_contact_id,
          oh.cancelled_flag,
          oh.open_flag,
          oh.booked_flag,
          oh.source_document_id,
          oh.source_document_type_id,
          Oel.Meaning,
          hcs.cust_account_id,
          hcsu.cust_acct_site_id,
          oh.org_id org_id
     FROM oe_order_headers_all oh,
          hz_cust_accounts acct,
          hz_parties cust,
          oe_lookups oel,
          hz_cust_site_uses_all hcsu,
          Hz_Cust_Acct_Sites_All Hcs,
          (SELECT hr.subject_id, hca.cust_account_id orig_cust_account_id
             FROM hz_parties hzp, hz_cust_accounts hca, hz_relationships hr
            WHERE     hr.object_id = hzp.party_id
                  AND hzp.party_id = hca.party_id
                  AND HR.RELATIONSHIP_CODE = 'Member Account of'
                  AND HR.STATUS = 'A'
                  AND (   (TRUNC (SYSDATE) BETWEEN start_date AND end_date)
                       OR end_date IS NULL)) ship
    WHERE     oh.sold_to_org_id = acct.cust_account_id
          AND acct.party_id = cust.party_id
          AND cust.party_id = ship.subject_id
          AND oel.lookup_code = oh.flow_status_code
          AND oel.lookup_type = 'FLOW_STATUS'
          AND Oh.Invoice_To_Org_Id = Hcsu.Site_Use_Id(+)
          AND hcsu.cust_acct_site_id = hcs.cust_acct_site_id(+);
