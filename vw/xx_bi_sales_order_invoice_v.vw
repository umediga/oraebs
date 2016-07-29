DROP VIEW APPS.XX_BI_SALES_ORDER_INVOICE_V;

/* Formatted on 6/6/2016 4:58:57 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_ORDER_INVOICE_V
(
   ATTN_CONTACT_DEPT_AND_PH,
   ATTN_COMPANY,
   ORDERED_BY_NAME_PH,
   FAX_NUMBER,
   EMAIL_ID,
   END_CUSTOMER_PO_NUMBER,
   DUPLICATE_PO_REASON,
   DATE_OF_SURGERY,
   SURGEON_NAME,
   CERTIFICATE_OF_CONFORMANCE,
   CASE_NUMBER,
   PATIENT_ID,
   RELATED_ORDER,
   CONSTRUCT_PRICING,
   SURGERY_TYPE,
   CREATION_DATE,
   CREATED_BY,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   ORDER_STATUS,
   SALESREP_ID,
   CUST_PO_NUMBER,
   ORDER_NUMBER,
   ORDER_TYPE,
   ORDERED_DATE,
   ORIG_SOURCE_ORDER_NUMBER,
   ORDER_HEADER_ID,
   DOCTOR_CERTIFICATION,
   KIT_SERIAL_NUMBER,
   CONSTRUCT,
   QUANTITY,
   SELLING_PRICE,
   EXTENDED_SELLING_PRICE,
   SCHEDULE_SHIP_DATE,
   WAREHOUSE,
   SUBINVENTORY,
   SALES_ORDER_LINE_NUMBER,
   CUSTOMER_NAME,
   CUSTOMER_NUMBER,
   CUSTOMER_CITY,
   CUSTOMER_STATE,
   CUSTOMER_ZIP,
   SHIP_TO_ADDRESS,
   BILL_TO_ADDRESS,
   DELIVER_TO_ADDRESS,
   ITEM_NUMBER,
   ITEM_DESCRIPTION,
   PRICE_LIST,
   REGION_NAME,
   INVOICE_NUMBER,
   INVOICE_DATE,
   INVOICE_CREATED_DATE,
   PO_NUMBER,
   DCODE,
   DCODE_DESCRIPTION,
   DIVISION,
   SUB_DIVISION,
   BRAND,
   CCODE,
   GL_ACCOUNT,
   DEALER,
   ORACLE_REGION_NAME,
   WAREHOUSE_NAME,
   PRODUCT_FRANCHISE,
   LIST_PRICE,
   GPO_FLAG,
   COMMISSION_RATES,
   ON_HOLD,
   CHARGES,
   MSRP,
   GROSS_MARGIN
)
AS
   SELECT ooh.attribute1 attn_contact_dept_and_ph,
          ooh.attribute20 attn_company,
          ooh.attribute2 ordered_by_name_ph,
          ooh.attribute3 fax_number,
          ooh.attribute4 email_id,
          ooh.attribute5 end_customer_po_number,
          ooh.attribute6 duplicate_po_reason,
          ooh.attribute7 date_of_surgery,
          ooh.attribute8 surgeon_name,
          ooh.attribute10 certificate_of_conformance,
          ooh.attribute12 case_number,
          ooh.attribute13 patient_id,
          ooh.attribute14 related_order,
          ooh.attribute15 construct_pricing,
          ooh.attribute11 surgery_type,
          ooh.creation_date,
          ooh.created_by,
          ooh.last_update_date,
          ooh.last_updated_by,
          ooh.flow_status_code order_status,
          ooh.salesrep_id,
          ooh.cust_po_number,
          ooh.order_number,
          ottt.NAME order_type,
          ooh.ordered_date,
          ooh.orig_sys_document_ref orig_source_order_number,
          ooh.header_id order_header_id,
          ool.attribute8 doctoer_certification,
          ool.attribute1 kit_serial_number,
          ool.attribute15 construct,
          NVL (ool.invoiced_quantity, ool.ordered_quantity) quantity,
          ool.unit_selling_price selling_price,
          (  (NVL (ool.invoiced_quantity, ool.ordered_quantity))
           * ool.unit_selling_price)
             extended_selling_price,
          ool.schedule_ship_date,
          ool.ship_from_org_id warehouse,
          ool.subinventory,
          ool.line_number sales_order_line_number,
          hp.party_name customer_name,
          hca.account_number customer_number,
          hl.city,
          hl.state,
          hl.postal_code,
          (   hp.party_name
           || ' '
           || hl.address1
           || ','
           || hl.address2
           || ','
           || hl.address3
           || ','
           || hl.city
           || ','
           || hl.state
           || ','
           || hl.postal_code
           || ','
           || hl.county)
             ship_to_address,
          (   hp1.party_name
           || ' '
           || hl1.address1
           || ','
           || hl1.address2
           || ','
           || hl1.address3
           || ','
           || hl1.city
           || ','
           || hl1.state
           || ','
           || hl1.postal_code
           || ','
           || hl1.county)
             bill_to_address,
          (   hp2.party_name
           || ' '
           || hl2.address1
           || ','
           || hl2.address2
           || ','
           || hl2.address3
           || ','
           || hl2.city
           || ','
           || hl2.state
           || ','
           || hl2.postal_code
           || ','
           || hl2.county)
             deliver_to_address,
          msib.segment1 item_number,
          msib.description item_description,
          qlh.NAME price_list,
          ftt.territory_short_name region_name,
          rcta.trx_number invoice_number,
          rcta.trx_date invoice_date,
          rcta.creation_date invoice_created_date,
          rcta.purchase_order po_number,
          mcb.segment9 dcode,
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  fnd_flex_values_tl c
            WHERE     ROWNUM = 1
                  AND a.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                  AND c.LANGUAGE = USERENV ('LANG')
                  AND b.flex_value = mcb.segment9
                  AND a.flex_value_set_id = b.flex_value_set_id
                  AND b.flex_value_id = c.flex_value_id)
             "DCODE_DESCRIPTION",
          mcb.segment4 division,
          mcb.segment5 sub_division,
          mcb.segment7 brand,
          mcb.segment8 ccode,
          NULL gl_account,
          (SELECT jrre.resource_name
             FROM apps.ra_salesreps_all rsa,
                  apps.jtf_rs_resource_extns_tl jrre
            WHERE     ROWNUM = 1
                  AND rsa.salesrep_id = ooh.salesrep_id
                  AND jrre.resource_id = rsa.resource_id
                  AND jrre.LANGUAGE = 'US')
             dealer,
          --Sudha: to be mapped after confirmation--
          NULL oracle_region_name,
          NULL warehouse_name,
          NULL product_franchise,
          NULL list_price,
          NULL gpo_flag,
          NULL commission_rates,
          NULL on_hold,
          NULL charges,
          NULL msrp,
          NULL gross_margin
     --Sudha: to be mapped after confirmation--
     FROM apps.ra_customer_trx_all rcta,
          apps.hz_parties hp,
          apps.hz_cust_accounts hca,
          apps.hz_cust_site_uses_all hcs,
          apps.hz_cust_acct_sites_all hcas,
          apps.hz_locations hl,
          apps.hz_party_sites hps,
          apps.hz_cust_site_uses_all hcs1,
          apps.hz_cust_acct_sites_all hcas1,
          apps.hz_locations hl1,
          apps.hz_party_sites hps1,
          apps.ra_customer_trx_lines_all rctl,
          apps.mtl_system_items_b msib,
          apps.hz_cust_site_uses_all hcs2,
          apps.hz_cust_acct_sites_all hcas2,
          apps.hz_locations hl2,
          apps.hz_party_sites hps2,
          apps.hz_parties hp1,
          apps.hz_cust_accounts hca1,
          apps.hz_parties hp2,
          apps.hz_cust_accounts hca2,
          --APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
          apps.oe_order_headers_all ooh,
          apps.oe_order_lines_all ool,
          apps.oe_transaction_types_tl ottt,
          -- APPS.RA_CUST_TRX_LINE_GL_DIST_ALL GL,
          --APPS.RA_CUST_TRX_TYPES_ALL RCTTA,
          apps.mtl_item_categories_v micv,
          apps.mtl_categories_b mcb,
          apps.fnd_territories_tl ftt,
          apps.qp_list_headers_tl qlh
    WHERE     ooh.ship_to_org_id = hcs.site_use_id(+)
          AND ooh.invoice_to_org_id = hcs1.site_use_id(+)
          AND ooh.deliver_to_org_id = hcs2.site_use_id(+)
          AND hcas.cust_account_id = hca.cust_account_id(+)
          AND hcas.party_site_id = hps.party_site_id(+)
          AND hps.location_id = hl.location_id(+)
          AND hps.party_id = hp.party_id(+)
          AND hcs.cust_acct_site_id = hcas.cust_acct_site_id(+)
          AND hcs1.cust_acct_site_id = hcas1.cust_acct_site_id(+)
          AND hcs2.cust_acct_site_id = hcas2.cust_acct_site_id(+)
          AND hcas1.cust_account_id = hca1.cust_account_id(+)
          AND hcas1.party_site_id = hps1.party_site_id(+)
          AND hps1.location_id = hl1.location_id(+)
          AND hps1.party_id = hp1.party_id(+)
          AND hcas2.cust_account_id = hca2.cust_account_id(+)
          AND hcas2.party_site_id = hps2.party_site_id(+)
          AND hps2.location_id = hl2.location_id(+)
          AND hps2.party_id = hp2.party_id(+)
          AND rctl.customer_trx_id = rcta.customer_trx_id
          AND rctl.sales_order = TO_CHAR (ooh.order_number)
          AND rctl.sales_order_line = TO_CHAR (ool.line_number)
          AND rctl.customer_trx_id = rcta.customer_trx_id
          AND rcta.interface_header_attribute1 = TO_CHAR (ooh.order_number)
          AND rctl.interface_line_attribute6(+) = TO_CHAR (ool.line_id)
          AND ooh.org_id = rcta.org_id
          --AND RCTL.INVENTORY_ITEM_ID           = MSIB.INVENTORY_ITEM_ID
          --AND RCTL.WAREHOUSE_ID                = MSIB.ORGANIZATION_ID
          --AND OOD.ORGANIZATION_ID              = MSIB.ORGANIZATION_ID
          --AND GL.CUSTOMER_TRX_LINE_ID          = RCTL.CUSTOMER_TRX_LINE_ID
          --AND GL.CUSTOMER_TRX_ID               = RCTA.CUSTOMER_TRX_ID
          --AND RCTTA.CUST_TRX_TYPE_ID           = RCTA.CUST_TRX_TYPE_ID
          --AND RCTTA.ORG_ID                     = RCTA.ORG_ID
          --AND RCTA.INTERFACE_HEADER_ATTRIBUTE1(+) = TO_CHAR (OOH.ORDER_NUMBER)
          --AND RCTL.INTERFACE_LINE_ATTRIBUTE6   = TO_CHAR (OOL.LINE_ID)
          --AND RCTL.INVENTORY_ITEM_ID           = OOL.INVENTORY_ITEM_ID
          AND msib.inventory_item_id = ool.inventory_item_id
          AND msib.organization_id = ool.ship_from_org_id
          AND ooh.order_type_id = ottt.transaction_type_id(+)
          AND ooh.header_id = ool.header_id
          AND ottt.LANGUAGE = USERENV ('LANG')
          ----AND RCTL.SET_OF_BOOKS_ID             = GL.SET_OF_BOOKS_ID
          ----AND GL.COGS_REQUEST_ID              IS NOT NULL
          AND micv.inventory_item_id = msib.inventory_item_id
          AND micv.organization_id = msib.organization_id
          AND micv.category_set_id(+) = 5
          AND mcb.category_id = micv.category_id
          AND ftt.territory_code = hl.country
          AND qlh.list_header_id = ool.price_list_id
          AND qlh.LANGUAGE = USERENV ('LANG')
          AND ftt.LANGUAGE = USERENV ('LANG')
          AND rcta.ship_date_actual IS NOT NULL
          AND ftt.territory_short_name = 'United States';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_ORDER_INVOICE_V FOR APPS.XX_BI_SALES_ORDER_INVOICE_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_ORDER_INVOICE_V FOR APPS.XX_BI_SALES_ORDER_INVOICE_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_ORDER_INVOICE_V FOR APPS.XX_BI_SALES_ORDER_INVOICE_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_ORDER_INVOICE_V FOR APPS.XX_BI_SALES_ORDER_INVOICE_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_ORDER_INVOICE_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_ORDER_INVOICE_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_ORDER_INVOICE_V TO XXINTG;
