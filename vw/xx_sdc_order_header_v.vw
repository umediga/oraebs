DROP VIEW APPS.XX_SDC_ORDER_HEADER_V;

/* Formatted on 6/6/2016 4:58:07 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_SDC_ORDER_HEADER_V
(
   HEADER_ID,
   ORGANIZATION_NAME,
   ORDER_NUMBER,
   TOTAL,
   CHARGES,
   SUB_TOTAL,
   TAX,
   STATUS,
   CURRENCY,
   ORDERED_DATE,
   OE_ORDER_TYPE,
   CUSTOMER_CONTACT,
   BIIL_TO_SITE_ID,
   BIIL_TO_LOCATION,
   SALES_REP,
   PRICE_LIST,
   CUSTOMER_PO,
   CUSTOMER_NUMBER,
   SHIP_TO_SITE_ID,
   SHIP_TO_LOCATION,
   CREATION_DATE,
   LAST_UPDATE_DATE,
   END_CUSTOMER_PO_NUMBER,
   DATE_OF_SURGERY,
   SURGEON_NAME,
   EMAIL_ID,
   PHONE_NUMBER
)
AS
   SELECT ooh.header_id                                          --,ooh.org_id
                       ,
          org.name organization_name,
          ooh.order_number,
          xx_sdc_order_view_pkg.header_total (ooh.header_id) total,
          (SELECT NVL (SUM (operand), 0)
             FROM OE_PRICE_ADJUSTMENTS
            WHERE header_id = ooh.header_id AND charge_type_code <> 'TAX')
             charges,
          xx_sdc_order_view_pkg.header_sub_total (ooh.header_id) sub_total,
          xx_sdc_order_view_pkg.header_tax (ooh.header_id) tax,
          ooh.flow_status_code status,
          ooh.transactional_curr_code currency,
          ooh.ordered_date,
          oht.name oe_order_type,
          (SELECT DISTINCT
                     ship_party.person_first_name
                  || ' '
                  || ship_party.person_last_name
             FROM hz_cust_account_roles ship_roles,
                  hz_parties ship_party,
                  hz_relationships ship_rel,
                  hz_cust_accounts ship_acct
            WHERE     ship_roles.party_id = ship_rel.party_id(+)
                  AND ship_roles.role_type(+) = 'CONTACT'
                  AND ship_roles.cust_account_id =
                         ship_acct.cust_account_id(+)
                  AND NVL (ship_rel.object_id, -1) =
                         NVL (ship_acct.party_id, -1)
                  AND ship_rel.subject_id = ship_party.party_id(+)
                  AND ship_roles.cust_account_role_id =
                         ooh.sold_to_contact_id)
             customer_contact      --,invoice_use.site_use_id biil_to_location
                             ,
          invoice_site.cust_acct_site_id biil_to_site_id,
          invoice_psite.party_site_number biil_to_location,
          rep.name sales_rep,
          qp.name price_list,
          ooh.cust_po_number customer_po,
          ship_acc.account_number customer_number --,ship_psite.site_use_id ship_to_location
                                                 ,
          ship_site.cust_acct_site_id ship_to_site_id,
          ship_psite.party_site_number ship_to_location,
          ooh.creation_date,
          ooh.last_update_date,
          ooh.attribute5 end_customer_po_number,
          ooh.attribute7 date_of_surgery,
          ooh.attribute8 surgeon_name,
          ooh.attribute4 email_id,
          ooh.attribute2 phone_number
     FROM oe_order_headers_all ooh,
          oe_transaction_types_tl oht,
          hr_operating_units org                                    -- Bill to
                                ,
          hz_cust_site_uses_all invoice_use,
          hz_cust_acct_sites_all invoice_site,
          hz_party_sites invoice_psite,
          hz_locations invoice_loc,
          hz_cust_accounts invoice_acc                              -- Ship to
                                      ,
          hz_cust_acct_sites_all ship_site,
          hz_cust_site_uses_all ship_use,
          hz_party_sites ship_psite,
          hz_locations ship_loc,
          hz_cust_accounts ship_acc,
          hz_parties hp,
          jtf_rs_salesreps rep,
          qp_list_headers qp
    WHERE     oht.transaction_type_id = ooh.order_type_id
          AND oht.language = USERENV ('LANG')
          AND ooh.org_id = org.organization_id
          AND ooh.salesrep_id = rep.salesrep_id(+)
          AND ooh.price_list_id = qp.list_header_id(+)
          AND ooh.invoice_to_org_id = invoice_use.site_use_id
          AND invoice_use.cust_acct_site_id =
                 invoice_site.cust_acct_site_id(+)
          AND invoice_site.party_site_id = invoice_psite.party_site_id(+)
          AND invoice_psite.location_id = invoice_loc.location_id(+)
          AND invoice_site.cust_account_id = invoice_acc.cust_account_id(+)
          -- Ship to
          AND ooh.ship_to_org_id = ship_use.site_use_id
          AND ship_use.cust_acct_site_id = ship_site.cust_acct_site_id(+)
          AND ship_site.party_site_id = ship_psite.party_site_id(+)
          AND ship_psite.location_id = ship_loc.location_id(+)
          AND ship_site.cust_account_id = ship_acc.cust_account_id(+)
          AND hp.party_id = ship_acc.party_id
          AND ship_acc.customer_type = 'R'
          --AND   ship_psite.status = 'A'
          --AND   hp.status = 'A'
          --AND   ship_site.status = 'A'
          --AND   ship_acc.status = 'A'
          AND NVL (ooh.booked_flag, 'X') = 'Y'
          AND EXISTS
                 (SELECT lookup_code
                    FROM fnd_lookup_values_vl
                   WHERE     lookup_type = 'XX_SFDC_OU_LOOKUP'
                         AND NVL (enabled_flag, 'X') = 'Y'
                         AND SYSDATE BETWEEN NVL (start_date_active, SYSDATE)
                                         AND NVL (end_date_active, SYSDATE));
