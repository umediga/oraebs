DROP VIEW APPS.XX_BI_SALES_SPINE_COMM_V;

/* Formatted on 6/6/2016 4:58:56 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_SALES_SPINE_COMM_V
(
   ORGANIZATION_CODE,
   ORG_ID,
   INVOICE_NUMBER,
   INVOICE_DATE,
   INVOICE_CREATION_DATE,
   GL_DATE,
   CUSTOMER_NUMBER,
   BILL_TO_LOCATION,
   BILL_TO_CUSTOMER,
   SHIP_TO_LOCATION,
   SHIP_TO_CUSTOMER,
   TRX_TYPE_REFERENCE,
   SALES_ORDER_NUMBER,
   SALES_ORDER_DATE,
   ORIG_SOURCE_ORDER_NUMBER,
   ORDER_HEADER_ID,
   PO_NUMBER,
   SALES_ORDER_LINE_NUMBER,
   INVOICE_LINE_ITEM_NUMBER,
   DESCRIPTION,
   SKU,
   SKU_DESCRIPTION,
   GROUP_4_DESCRIPTION,
   SELL_QTY,
   EXTENDED_AMOUNT,
   EXTENDED_UNIT_PRICE,
   GL_ACCOUNT,
   SURGEON,
   DATE_OF_SURGERY,
   DEALER,
   PATIENT_ID,
   CUSTOMER_NAME,
   ADDRESS1,
   ADDRESS2,
   CITY,
   POSTAL_CODE,
   STATE,
   DIVISON,
   SUBDIVISON,
   BRAND,
   C_CODE,
   D_CODE,
   TERRITORY
)
AS
   (SELECT OOD.ORGANIZATION_CODE,
           RCTA.ORG_ID,
           RCTA.TRX_NUMBER INVOICE_NO,
           RCTA.TRX_DATE INVOICE_DATE,
           RCTA.CREATION_DATE "Invoice_Creation_date",
           GL.GL_DATE,
           HCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
           HCS1.LOCATION BILL_TO_LOC,
           HP.PARTY_NAME BILL_CUST_NAME,
           HCS.LOCATION SHIP_TO_LOC,
           HP1.PARTY_NAME SHIP_CUST_NAME,
           RCTTA.DESCRIPTION "TRX_type Reference",
           OOH.ORDER_NUMBER,
           OOH.ORDERED_DATE,
           OOH.ORIG_SYS_DOCUMENT_REF "Orig_Source_Order_Number",
           OOH.HEADER_ID "Order_Header_Id",
           RCTA.PURCHASE_ORDER "PO_Number",
           OOL.LINE_NUMBER "Sales_Order_Line_Number",
           MSIB.SEGMENT1 "Invoice_Line_Item_Number",
           RCTL.DESCRIPTION,
           MSIB.SEGMENT1 "SKU",
           MSIB.DESCRIPTION "SKU_Description",
           MICV.SEGMENT7 "Group_4_Description",
           RCTL.QUANTITY_INVOICED,
           RCTL.EXTENDED_AMOUNT "ExtendedPrice",
           RCTL.UNIT_SELLING_PRICE "ExtUnitPrice",
           (SELECT concatenated_segments
              FROM gl_code_combinations_kfv
             WHERE code_combination_id = GL.code_combination_id)
              acccount,
           OOH.ATTRIBUTE4 "Surgeon",
           OOH.ATTRIBUTE7 "Date_of_Surgery",
           (SELECT JRSV.NAME
              FROM APPS.JTF_RS_SRP_VL JRSV
             WHERE JRSV.SALESREP_ID = GL.CUST_TRX_LINE_SALESREP_ID)
              "Dealer",
           OOH.ATTRIBUTE13 "Patient_Id",
           HP.PARTY_NAME CUST_NAME,
           HL.ADDRESS1,
           HL.ADDRESS2,
           HL.CITY,
           HL.POSTAL_CODE,
           HL.STATE,
           MCB.SEGMENT4 DIVISION,
           MCB.SEGMENT5 SUB_DIVISION,
           mcb.segment7 Brand,
           MCB.SEGMENT8 "C_Code",
           MCB.SEGMENT9 "D_Code",
           FTT.TERRITORY_SHORT_NAME "Territory"
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
           APPS.RA_CUSTOMER_TRX_LINES_ALL RCTL,
           APPS.MTL_SYSTEM_ITEMS_B MSIB,
           APPS.HZ_CUST_SITE_USES_ALL HCS2,
           APPS.HZ_CUST_ACCT_SITES_ALL HCAS2,
           APPS.HZ_LOCATIONS HL2,
           APPS.HZ_PARTY_SITES HPS2,
           APPS.HZ_PARTIES HP1,
           APPS.HZ_CUST_ACCOUNTS HCA1,
           APPS.HZ_PARTIES HP2,
           APPS.HZ_CUST_ACCOUNTS HCA2,
           APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
           APPS.OE_ORDER_HEADERS_ALL OOH,
           APPS.OE_ORDER_LINES_ALL OOL,
           APPS.RA_CUST_TRX_LINE_GL_DIST_ALL GL,
           APPS.RA_CUST_TRX_TYPES_ALL RCTTA,
           APPS.MTL_ITEM_CATEGORIES_V MICV,
           APPS.MTL_CATEGORIES_B MCB,
           APPS.FND_TERRITORIES_TL FTT
     WHERE     RCTA.SOLD_TO_CUSTOMER_ID = HCA.CUST_ACCOUNT_ID
           AND HCA.PARTY_ID = HP.PARTY_ID
           AND RCTA.SHIP_TO_CUSTOMER_ID = HCA1.CUST_ACCOUNT_ID
           AND HCA1.PARTY_ID = HP1.PARTY_ID
           AND RCTA.SHIP_TO_SITE_USE_ID = HCS.SITE_USE_ID
           AND HCS.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID
           AND RCTA.SHIP_TO_SITE_USE_ID = HCS.SITE_USE_ID
           AND HCS.CUST_ACCT_SITE_ID = HCAS.CUST_ACCT_SITE_ID
           AND HCAS.PARTY_SITE_ID = HPS.PARTY_SITE_ID
           AND HPS.LOCATION_ID = HL.LOCATION_ID
           AND RCTA.BILL_TO_CUSTOMER_ID = HCA2.CUST_ACCOUNT_ID
           AND HCA2.PARTY_ID = HP2.PARTY_ID
           AND RCTA.BILL_TO_SITE_USE_ID = HCS1.SITE_USE_ID
           AND HCS1.CUST_ACCT_SITE_ID = HCAS1.CUST_ACCT_SITE_ID
           AND RCTA.BILL_TO_SITE_USE_ID = HCS1.SITE_USE_ID
           AND HCS1.CUST_ACCT_SITE_ID = HCAS1.CUST_ACCT_SITE_ID
           AND HCAS1.PARTY_SITE_ID = HPS1.PARTY_SITE_ID
           AND HPS1.LOCATION_ID = HL1.LOCATION_ID
           AND RCTA.REMIT_TO_ADDRESS_ID = HCS2.SITE_USE_ID
           AND HCS2.CUST_ACCT_SITE_ID = HCAS2.CUST_ACCT_SITE_ID
           AND HCAS2.PARTY_SITE_ID = HPS2.PARTY_SITE_ID
           AND HPS2.LOCATION_ID = HL2.LOCATION_ID
           AND RCTL.CUSTOMER_TRX_ID = RCTA.CUSTOMER_TRX_ID
           AND RCTL.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
           AND RCTL.WAREHOUSE_ID = MSIB.ORGANIZATION_ID
           AND OOD.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
           AND GL.CUSTOMER_TRX_LINE_ID = RCTL.CUSTOMER_TRX_LINE_ID
           AND GL.CUSTOMER_TRX_ID = RCTA.CUSTOMER_TRX_ID
           AND RCTTA.CUST_TRX_TYPE_ID = RCTA.CUST_TRX_TYPE_ID
           AND RCTTA.ORG_ID = RCTA.ORG_ID
           AND RCTA.INTERFACE_HEADER_ATTRIBUTE1 = TO_CHAR (OOH.ORDER_NUMBER)
           AND RCTL.INTERFACE_LINE_ATTRIBUTE6 = TO_CHAR (OOL.LINE_ID)
           AND RCTL.INVENTORY_ITEM_ID = OOL.INVENTORY_ITEM_ID
           AND RCTL.SET_OF_BOOKS_ID = GL.SET_OF_BOOKS_ID
           AND GL.COGS_REQUEST_ID IS NOT NULL
           AND MICV.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID
           AND MICV.ORGANIZATION_ID = MSIB.ORGANIZATION_ID
           AND MICV.CATEGORY_SET_ID(+) = 5
           AND MCB.CATEGORY_ID = MICV.CATEGORY_ID
           AND FTT.TERRITORY_CODE = HL.COUNTRY
           AND FTT.LANGUAGE = USERENV ('LANG'));


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_SALES_SPINE_COMM_V FOR APPS.XX_BI_SALES_SPINE_COMM_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_SALES_SPINE_COMM_V FOR APPS.XX_BI_SALES_SPINE_COMM_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_SALES_SPINE_COMM_V FOR APPS.XX_BI_SALES_SPINE_COMM_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_SALES_SPINE_COMM_V FOR APPS.XX_BI_SALES_SPINE_COMM_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SPINE_COMM_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SPINE_COMM_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK ON APPS.XX_BI_SALES_SPINE_COMM_V TO XXINTG;