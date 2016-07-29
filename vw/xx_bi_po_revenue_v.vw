DROP VIEW APPS.XX_BI_PO_REVENUE_V;

/* Formatted on 6/6/2016 4:59:02 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_PO_REVENUE_V
(
   OPERATING_UNIT_NAME,
   REGION,
   INVOICE_NUMBER,
   SALES_ORDER_NUMBER,
   SALES_ORDER_TYPE,
   SURGEON_NAME,
   CUSTOMER_NUMBER,
   CUSTOMER_NAME,
   CLASSIFICATION,
   SALES_REP,
   ORDERED_DATE,
   ITEM_NUMBER,
   DESCRIPTION,
   QTY,
   UNIT_PRICE,
   AMOUNT,
   DIVISION,
   PURCHASE_ORDER_NUMBER,
   ACCOUNT_NAME,
   CUSTOMER_TYPE,
   PARTY_TYPE,
   SHIPMENT_PRIORITY_CODE,
   ORDER_QUANTITY_UOM,
   ITEM_TYPE_CODE,
   EXPENSE_ACCOUNT,
   ITEM_TYPE,
   OPERATING_UNIT_ID,
   ORGANIZATION_NAME
)
AS
   (SELECT HR.NAME OU,
           L.TERRITORY_SHORT_NAME "Region",
           rcta.trx_number "Invoice Number",
           --INVOICE_DET.TRX_NUMBER "Invoice Number",
           OEH.ORDER_NUMBER "Sales Order Number",
           OTTT.NAME "SALES_ORDER_TYPE",
           (SELECT ATTRIBUTE8
              FROM apps.oe_order_headers_all ooh1
             WHERE     UPPER (CONTEXT) = UPPER ('Consignment')
                   AND ooh1.header_id = oeh.header_id)
              SURGEON_NAME,
           HZCA.ACCOUNT_NUMBER CUSTOMER_NUMBER,
           HP.PARTY_NAME CUSTOMER_NAME,
           HZCA.CUSTOMER_CLASS_CODE "Classification",
           JRE.RESOURCE_NAME "Sales Rep",
           TRUNC (OEH.ORDERED_DATE) "Ordered date",
           OOL.ORDERED_ITEM "ITEM_NUMBER",
           MSIB.DESCRIPTION "Description",
           OOL.INVOICED_QUANTITY QTY,
           OOL.UNIT_SELLING_PRICE "Unit Price",
           (OOL.UNIT_SELLING_PRICE * OOL.INVOICED_QUANTITY) AMOUNT,
           (SELECT mcb.segment4
              FROM mtl_item_categories mic,
                   mtl_category_sets_tl mcst,
                   mtl_category_sets_b mcsb,
                   mtl_categories_b mcb
             WHERE     mcst.category_set_id = mcsb.category_set_id
                   AND mcst.language = USERENV ('LANG')
                   AND mic.category_set_id = mcsb.category_set_id
                   AND mic.category_id = mcb.category_id
                   AND mcst.category_set_name = 'Sales and Marketing'
                   AND mic.inventory_item_id = msib.inventory_item_id
                   AND mic.organization_id = msib.organization_id)
              DIVISION,
           rcta.purchase_order Purchase_order_Number,
           HZCA.ACCOUNT_NAME,
           HZCA.CUSTOMER_TYPE,
           HP.PARTY_TYPE,
           OEH.SHIPMENT_PRIORITY_CODE,
           OOL.ORDER_QUANTITY_UOM,
           OOL.ITEM_TYPE_CODE,
           MSIB.EXPENSE_ACCOUNT,
           MSIB.ITEM_TYPE,
           OOD.OPERATING_UNIT,
           OOD.ORGANIZATION_NAME
      FROM APPS.HZ_CUST_ACCOUNTS HZCA,
           APPS.HZ_PARTY_SITES PARTY_SITE,
           APPS.HZ_LOCATIONS LOC,
           APPS.HZ_CUST_ACCT_SITES_ALL HZCS,
           APPS.HZ_CUST_SITE_USES_ALL HZCST,
           APPS.HZ_PARTIES HP,
           APPS.OE_ORDER_HEADERS_ALL OEH,
           APPS.OE_ORDER_LINES_ALL OOL,
           APPS.ORG_ORGANIZATION_DEFINITIONS OOD,
           APPS.HR_OPERATING_UNITS HR,
           APPS.FND_TERRITORIES_VL L,
           APPS.OE_TRANSACTION_TYPES_TL OTTT,
           APPS.RA_SALESREPS_ALL RSA,
           APPS.MTL_SYSTEM_ITEMS_B MSIB,
           /*(SELECT CT_REFERENCE,
                   ORG_ID,
                   TRX_NUMBER,
                   TRX_DATE,
                   PURCHASE_ORDER,
                   PRIMARY_SALESREP_ID,
                   INTERFACE_HEADER_ATTRIBUTE1,
                   INTERFACE_HEADER_ATTRIBUTE6,
                   CUSTOMER_TRX_ID
              FROM RA_CUSTOMER_TRX_ALL) INVOICE_DET,*/
           apps.RA_CUSTOMER_TRX_ALL rcta,
           apps.RA_CUSTOMER_TRX_LINES_ALL rctl,
           JTF_RS_RESOURCE_EXTNS_TL JRE
     WHERE     HZCA.CUST_ACCOUNT_ID = HZCS.CUST_ACCOUNT_ID
           AND HZCS.CUST_ACCT_SITE_ID = HZCST.CUST_ACCT_SITE_ID
           -- AND INVOICE_DET.INTERFACE_HEADER_ATTRIBUTE1 =
           --TO_CHAR (OEH.ORDER_NUMBER)
           AND rcta.INTERFACE_HEADER_ATTRIBUTE1 = TO_CHAR (OEH.ORDER_NUMBER)
           AND HZCS.PARTY_SITE_ID = PARTY_SITE.PARTY_SITE_ID
           AND LOC.LOCATION_ID = PARTY_SITE.LOCATION_ID
           AND HZCS.CUST_ACCT_SITE_ID = HZCST.CUST_ACCT_SITE_ID
           AND HP.PARTY_ID = HZCA.PARTY_ID
           AND OEH.SHIP_FROM_ORG_ID = OOD.ORGANIZATION_ID
           AND OOD.OPERATING_UNIT = HR.ORGANIZATION_ID
           AND OEH.ORG_ID = HR.ORGANIZATION_ID
           AND HZCA.CUST_ACCOUNT_ID = OEH.SOLD_TO_ORG_ID
           AND HZCST.SITE_USE_ID = OEH.INVOICE_TO_ORG_ID
           AND HZCST.SITE_USE_CODE = 'BILL_TO'
           AND L.TERRITORY_CODE = LOC.COUNTRY
           AND MSIB.INVENTORY_ITEM_ID = OOL.INVENTORY_ITEM_ID
           AND MSIB.ORGANIZATION_ID = OEH.SHIP_FROM_ORG_ID
           AND OTTT.TRANSACTION_TYPE_ID = OEH.ORDER_TYPE_ID
           AND OTTT.LANGUAGE = USERENV ('LANG')
           --AND RSA.SALESREP_ID = INVOICE_DET.PRIMARY_SALESREP_ID
           AND RSA.SALESREP_ID = rcta.PRIMARY_SALESREP_ID
           AND OOL.HEADER_ID = OEH.HEADER_ID
           AND OOL.ORG_ID = OEH.ORG_ID
           AND HZCS.STATUS = 'A'
           AND HZCST.STATUS = 'A'
           --AND rctl.CUSTOMER_TRX_ID = INVOICE_DET.CUSTOMER_TRX_ID
           AND rctl.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
           AND RCTL.INTERFACE_LINE_ATTRIBUTE6 = TO_CHAR (OOL.LINE_ID)
           AND RCTL.INTERFACE_LINE_ATTRIBUTE1 = TO_CHAR (OEH.ORDER_NUMBER)
           AND OOL.INVENTORY_ITEM_ID = RCTL.INVENTORY_ITEM_ID
           AND RCTL.WAREHOUSE_ID = MSIB.ORGANIZATION_ID
           AND JRE.RESOURCE_ID = RSA.RESOURCE_ID
           AND JRE.LANGUAGE = USERENV ('LANG'));


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_PO_REVENUE_V FOR APPS.XX_BI_PO_REVENUE_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_PO_REVENUE_V FOR APPS.XX_BI_PO_REVENUE_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_PO_REVENUE_V FOR APPS.XX_BI_PO_REVENUE_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_PO_REVENUE_V FOR APPS.XX_BI_PO_REVENUE_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_REVENUE_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_REVENUE_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_PO_REVENUE_V TO XXINTG;