DROP VIEW APPS.XX_BI_SALES_SPN_RPT_PKG_V;

/* Formatted on 6/6/2016 4:58:55 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_SPN_RPT_PKG_V
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
   SELECT DISTINCT
          ooh.ATTRIBUTE1 ATTN_CONTACT_DEPT_AND_PH,
          ooh.ATTRIBUTE20 ATTN_COMPANY,
          ooh.ATTRIBUTE2 ORDERED_BY_NAME_PH,
          ooh.ATTRIBUTE3 FAX_NUMBER,
          ooh.ATTRIBUTE4 EMAIL_ID,
          ooh.ATTRIBUTE5 END_CUSTOMER_PO_NUMBER,
          ooh.ATTRIBUTE6 DUPLICATE_PO_REASON,
          ooh.ATTRIBUTE7 DATE_OF_SURGERY,
          ooh.ATTRIBUTE8 SURGEON_NAME,
          ooh.ATTRIBUTE10 CERTIFICATE_OF_CONFORMANCE,
          ooh.ATTRIBUTE12 CASE_NUMBER,
          ooh.ATTRIBUTE13 PATIENT_ID,
          ooh.ATTRIBUTE14 RELATED_ORDER,
          ooh.ATTRIBUTE15 CONSTRUCT_PRICING,
          ooh.ATTRIBUTE11 SURGERY_TYPE,
          ooh.CREATION_DATE,
          ooh.CREATED_BY,
          ooh.LAST_UPDATE_DATE,
          ooh.LAST_UPDATED_BY,
          ooh.FLOW_STATUS_CODE ORDER_STATUS,
          ooh.SALESREP_ID,
          ooh.CUST_PO_NUMBER,
          ooh.ORDER_NUMBER,
          OTTT.NAME ORDER_TYPE,
          ooh.ORDERED_DATE,
          ooh.ORIG_SYS_DOCUMENT_REF ORIG_SOURCE_ORDER_NUMBER,
          ooh.HEADER_ID ORDER_HEADER_ID,
          ool.ATTRIBUTE8 DOCTOER_CERTIFICATION,
          ool.ATTRIBUTE1 KIT_SERIAL_NUMBER,
          ool.ATTRIBUTE15 CONSTRUCT,
          NVL (ool.INVOICED_QUANTITY, ool.ORDERED_QUANTITY) QUANTITY,
          ool.UNIT_SELLING_PRICE SELLING_PRICE,
          (  (NVL (ool.INVOICED_QUANTITY, ool.ORDERED_QUANTITY))
           * ool.UNIT_SELLING_PRICE)
             EXTENDED_SELLING_PRICE,
          ool.SCHEDULE_SHIP_DATE,
          ool.SHIP_FROM_ORG_ID WAREHOUSE,
          ool.SUBINVENTORY,
          OOL.LINE_NUMBER SALES_ORDER_LINE_NUMBER,
          HP.party_name CUSTOMER_NAME,
          HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
          --decode((substr(HL.ORIG_SYSTEM_REFERENCE,5,length(HL.ORIG_SYSTEM_REFERENCE)-4)),null,HCA.ACCOUNT_NUMBER,(HCA.ACCOUNT_NUMBER ||'-'||substr(HL.ORIG_SYSTEM_REFERENCE,5,length(HL.ORIG_SYSTEM_REFERENCE)-4))) CUSTOMER_NUMBER,
          HL.City,
          HL.State,
          HL.postal_code,
          (   HP.party_name
           || ' '
           || HL.address1
           || ','
           || HL.address2
           || ','
           || HL.address3
           || ','
           || HL.city
           || ','
           || HL.state
           || ','
           || HL.postal_code
           || ','
           || HL.county)
             SHIP_TO_ADDRESS,
          (   HP1.party_name
           || ' '
           || HL1.address1
           || ','
           || HL1.address2
           || ','
           || HL1.address3
           || ','
           || HL1.city
           || ','
           || HL1.state
           || ','
           || HL1.postal_code
           || ','
           || HL1.county)
             BILL_TO_ADDRESS,
          (   HP2.party_name
           || ' '
           || HL2.address1
           || ','
           || HL2.address2
           || ','
           || HL2.address3
           || ','
           || HL2.city
           || ','
           || HL2.state
           || ','
           || HL2.postal_code
           || ','
           || HL2.county)
             DELIVER_TO_ADDRESS,
          MSIB.SEGMENT1 ITEM_NUMBER,
          MSIB.DESCRIPTION ITEM_DESCRIPTION,
          qlh.NAME PRICE_LIST,
          FTT.TERRITORY_SHORT_NAME REGION_NAME,
          RCTA.TRX_NUMBER INVOICE_NUMBER,
          RCTA.TRX_DATE INVOICE_DATE,
          RCTA.CREATION_DATE INVOICE_CREATED_DATE,
          RCTA.PURCHASE_ORDER PO_NUMBER,
          MCB.SEGMENT9 DCODE,
          (SELECT c.description
             FROM fnd_flex_value_sets a,
                  fnd_flex_values b,
                  FND_FLEX_VALUES_TL C
            WHERE     ROWNUM = 1
                  AND a.flex_value_set_name = 'INTG_PRODUCT_TYPE'
                  AND C.LANGUAGE = USERENV ('LANG')
                  AND b.FLEX_VALUE = mcb.segment9
                  AND a.FLEX_VALUE_SET_ID = B.FLEX_VALUE_SET_ID
                  AND B.FLEX_VALUE_ID = C.FLEX_VALUE_ID)
             "DCODE_DESCRIPTION",
          MCB.SEGMENT4 DIVISION,
          MCB.SEGMENT5 SUB_DIVISION,
          MCB.SEGMENT7 BRAND,
          MCB.SEGMENT8 CCODE,
          NULL GL_ACCOUNT,
          (SELECT JRRE.RESOURCE_NAME
             FROM APPS.RA_SALESREPS_ALL RSA,
                  APPS.JTF_RS_RESOURCE_EXTNS_TL JRRE
            WHERE     ROWNUM = 1
                  AND RSA.SALESREP_ID = OOH.SALESREP_ID
                  AND JRRE.RESOURCE_ID = RSA.RESOURCE_ID
                  AND JRRE.LANGUAGE = 'US')
             DEALER,
          --Sudha: to be mapped after confirmation--
          NULL ORACLE_REGION_NAME,
          NULL WAREHOUSE_NAME,
          NULL PRODUCT_FRANCHISE,
          NULL LIST_PRICE,
          NULL GPO_FLAG,
          NULL COMMISSION_RATES,
          NULL ON_HOLD,
          NULL CHARGES,
          NULL MSRP,
          NULL GROSS_MARGIN
     --Sudha: to be mapped after confirmation--
     FROM APPS.RA_CUSTOMER_TRX_ALL RCTA,
          APPS.HZ_PARTIES HP,
          APPS.HZ_CUST_ACCOUNTS HCA,
          APPS.HZ_CUST_SITE_USES_ALL HCS,
          APPS.HZ_CUST_ACCT_SITES_ALL HCAS,
          APPS.HZ_LOCATIONS HL,
          APPS.HZ_PARTY_SITES HPS,
          APPS.HZ_CUST_SITE_USES_ALL HCS1,
          APPS.HZ_CUST_ACCT_SITES_ALL HCAS1,
          APPS.HZ_LOCATIONS HL1,
          APPS.HZ_PARTY_SITES HPS1,
          --APPS.RA_CUSTOMER_TRX_LINES_ALL RCTL,
          APPS.MTL_SYSTEM_ITEMS_B MSIB,
          APPS.HZ_CUST_SITE_USES_ALL HCS2,
          APPS.HZ_CUST_ACCT_SITES_ALL HCAS2,
          APPS.HZ_LOCATIONS HL2,
          APPS.HZ_PARTY_SITES HPS2,
          APPS.HZ_PARTIES HP1,
          APPS.HZ_CUST_ACCOUNTS HCA1,
          APPS.HZ_PARTIES HP2,
          APPS.HZ_CUST_ACCOUNTS HCA2,
          --APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
          APPS.OE_ORDER_HEADERS_ALL OOH,
          APPS.OE_ORDER_LINES_ALL OOL,
          APPS.OE_TRANSACTION_TYPES_TL OTTT,
          -- APPS.RA_CUST_TRX_LINE_GL_DIST_ALL GL,
          --APPS.RA_CUST_TRX_TYPES_ALL RCTTA,
          APPS.MTL_ITEM_CATEGORIES_V MICV,
          APPS.MTL_CATEGORIES_B MCB,
          APPS.FND_TERRITORIES_TL FTT,
          apps.qp_list_headers_tl qlh
    WHERE     OOH.ship_to_org_id = hcs.SITE_USE_ID(+)
          AND ooh.invoice_to_org_id = hcs1.SITE_USE_ID(+)
          AND ooh.deliver_to_org_id = hcs2.SITE_USE_ID(+)
          AND HCAS.cust_account_id = HCA.cust_account_id(+)
          AND HCAS.party_site_id = HPS.party_site_id(+)
          AND HPS.location_id = HL.location_id(+)
          AND HPS.party_id = HP.party_id(+)
          AND HCS.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID(+)
          AND HCS1.CUST_ACCT_SITE_ID = HCAS1.CUST_ACCT_SITE_ID(+)
          AND HCS2.CUST_ACCT_SITE_ID = HCAS2.CUST_ACCT_SITE_ID(+)
          AND HCAS1.cust_account_id = HCA1.cust_account_id(+)
          AND HCAS1.party_site_id = HPS1.party_site_id(+)
          AND HPS1.location_id = HL1.location_id(+)
          AND HPS1.party_id = HP1.party_id(+)
          AND HCAS2.cust_account_id = HCA2.cust_account_id(+)
          AND HCAS2.party_site_id = HPS2.party_site_id(+)
          AND HPS2.location_id = HL2.location_id(+)
          AND HPS2.party_id = HP2.party_id(+)
          --AND RCTL.CUSTOMER_TRX_ID             = RCTA.CUSTOMER_TRX_ID
          --AND RCTL.INVENTORY_ITEM_ID           = MSIB.INVENTORY_ITEM_ID
          --AND RCTL.WAREHOUSE_ID                = MSIB.ORGANIZATION_ID
          --AND OOD.ORGANIZATION_ID              = MSIB.ORGANIZATION_ID
          --AND GL.CUSTOMER_TRX_LINE_ID          = RCTL.CUSTOMER_TRX_LINE_ID
          --AND GL.CUSTOMER_TRX_ID               = RCTA.CUSTOMER_TRX_ID
          --AND RCTTA.CUST_TRX_TYPE_ID           = RCTA.CUST_TRX_TYPE_ID
          --AND RCTTA.ORG_ID                     = RCTA.ORG_ID
          AND RCTA.INTERFACE_HEADER_ATTRIBUTE1(+) =
                 TO_CHAR (OOH.ORDER_NUMBER)
          --AND RCTL.INTERFACE_LINE_ATTRIBUTE6   = TO_CHAR (OOL.LINE_ID)
          --AND RCTL.INVENTORY_ITEM_ID           = OOL.INVENTORY_ITEM_ID
          AND MSIB.INVENTORY_ITEM_ID = OOL.INVENTORY_ITEM_ID
          AND MSIB.ORGANIZATION_ID = OOL.SHIP_FROM_ORG_ID
          AND OOH.ORDER_TYPE_ID = OTTT.TRANSACTION_TYPE_ID(+)
          AND OOH.HEADER_ID = OOL.HEADER_ID
          AND OTTT.LANGUAGE = USERENV ('LANG')
          --AND RCTL.SET_OF_BOOKS_ID             = GL.SET_OF_BOOKS_ID
          --AND GL.COGS_REQUEST_ID              IS NOT NULL
          AND MICV.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
          AND MICV.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
          AND MICV.CATEGORY_SET_ID(+) = 5
          AND MCB.CATEGORY_ID = MICV.CATEGORY_ID
          AND FTT.TERRITORY_CODE = HL.COUNTRY
          AND qlh.list_header_id = ool.price_list_id
          AND qlh.language = USERENV ('LANG')
          AND FTT.LANGUAGE = USERENV ('LANG')
          AND MCB.SEGMENT4 = 'SPINE'
          AND FTT.TERRITORY_SHORT_NAME = 'United States';


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_SPN_RPT_PKG_V FOR APPS.XX_BI_SALES_SPN_RPT_PKG_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_SPN_RPT_PKG_V FOR APPS.XX_BI_SALES_SPN_RPT_PKG_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_SPN_RPT_PKG_V FOR APPS.XX_BI_SALES_SPN_RPT_PKG_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_SPN_RPT_PKG_V FOR APPS.XX_BI_SALES_SPN_RPT_PKG_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_SPN_RPT_PKG_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_SPN_RPT_PKG_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_SALES_SPN_RPT_PKG_V TO XXINTG;
