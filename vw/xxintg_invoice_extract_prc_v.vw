DROP VIEW APPS.XXINTG_INVOICE_EXTRACT_PRC_V;

/* Formatted on 6/6/2016 5:00:20 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_INVOICE_EXTRACT_PRC_V
(
   INVOICE_NUMBER,
   INVOICE_DATE,
   SALES_ORDER_NUMBER,
   SALES_ORDER_DATE,
   CUSTOMER_NUMBER,
   CUSTOMER_ORDER_NUMBER,
   ORDER_DUE_DATE,
   DATE_CLOSED,
   FOB_POINT,
   SALESREP_ID,
   GL_ACCOUNT,
   ORDER_CLASS,
   ORDER_STATUS,
   LINE_ITEM_NUMBER,
   INVOICE_LINE_NUMBER,
   SKU,
   UNIT_OF_MEASURE,
   SHIP_DATE,
   INVOICE_TYPE,
   BASE_QTY,
   SELL_QTY,
   EXTENDED_PRICE,
   EXT_UNIT_PRICE,
   PRICE_CODE,
   TRANS_CURRENCY,
   FUNC_CURRENCY,
   USER_DEFINED1,
   USER_DEFINED2,
   USER_DEFINED3,
   USER_DEFINED4,
   USER_DEFINED5,
   USER_DEFINED_DTL1,
   USER_DEFINED_DTL2,
   USER_DEFINED_DTL3,
   USER_DEFINED_DTL4,
   USER_DEFINED_DTL5,
   ORG_ID,
   CREATION_DATE,
   GL_DATE
)
AS
   SELECT RCT.TRX_NUMBER Invoice_Number,
          TRUNC (RCT.TRX_DATE) INVOICE_DATE,
          RCTL.SALES_ORDER SALES_ORDER_NUMBER,
          RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
             HCA.ACCOUNT_NUMBER
          || '-'
          || (SELECT hps.party_site_number
                FROM hz_party_sites hps,
                     hz_cust_site_uses_all hcsua,
                     hz_cust_acct_sites_all hcasa
               WHERE     rct.ship_to_site_use_id = hcsua.site_use_id(+)
                     AND hcsua.site_use_code = 'SHIP_TO'
                     AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
                     AND hcasa.party_site_id = hps.party_site_id(+))
             CUSTOMER_NUMBER,
          RCT.PURCHASE_ORDER CUSTOMER_ORDER_NUMBER,
          ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (RCT.CUSTOMER_TRX_ID,
                                                      RCT.TERM_ID,
                                                      RCT.TRX_DATE)
             ORDER_DUE_DATE,
          NULL DATE_CLOSED,
          RCT.FOB_POINT,
          NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                          ,
          XX_AR_GL_CC (rctl.customer_trx_line_id, rctl.line_type, 'GL')
             GL_Account,
          NULL ORDER_CLASS,
          NULL ORDER_STATUS,
          TO_CHAR (RCTL.LINE_NUMBER) LINE_ITEM_NUMBER,
          RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
          NVL (MSIB.SEGMENT1, 'MISSING_ITEM') SKU,
          MSIB.PRIMARY_UNIT_OF_MEASURE UNIT_OF_MEASURE,
          NULL ship_date,
          NULL INVOICE_TYPE,
          NVL (rctl.quantity_ordered, 0) base_qty,
          DECODE (
             SUBSTR (rctl.description, 1, 6),
             '@DSCNT', 0,
             NVL (
                DECODE (rctl.quantity_invoiced,
                        NULL, rctl.quantity_credited,
                        rctl.quantity_invoiced),
                0))
             SELL_QTY,
          NVL (RCTL.EXTENDED_AMOUNT, 0) EXTENDED_PRICE,
          NVL (rctl.unit_selling_price, 0) ext_unit_price,
          NULL price_code,
          RCT.INVOICE_CURRENCY_CODE TRANS_CURRENCY,
          rct.INVOICE_CURRENCY_CODE Func_Currency --,rct.set_of_books_id Func_Currency
                                                 ,
          NULL USER_DEFINED1,
          NULL user_defined2,
          NULL user_defined3,
          NULL USER_DEFINED4,
          NULL user_defined5,
          NULL user_defined_dtl1,
          NULL USER_DEFINED_DTL2,
          NULL USER_DEFINED_DTL3,
          (   RCTL.INTERFACE_LINE_ATTRIBUTE3
           || '|'
           || mp.organization_code
           || '|'
           || rctl.interface_line_attribute2
           || '|'
           || DECODE (rctt.TYPE,
                      'INV', 'Invoice',
                      'CM', 'Credit Memo',
                      'DM', 'Debit Memo',
                      'CB', 'Chargeback',
                      rctt.TYPE)
           || '|'
           || rctt.name
           || '|'
           || ott.name                                           -- || '|TEST'
                                                               --|| al.meaning
          )
             user_defined_dtl4,
          NULL USER_DEFINED_DTL5,
          RCT.ORG_ID,
          rct.creation_date --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                           ,
          XX_AR_GL_CC (rctl.customer_trx_line_id, rctl.line_type, 'DATE')
             GL_DATE
     FROM RA_CUSTOMER_TRX_ALL RCT,
          RA_CUSTOMER_TRX_LINES_ALL RCTL  --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                        ,
          HZ_CUST_ACCOUNTS_ALL HCA,
          MTL_SYSTEM_ITEMS_B MSIB,
          RA_CUST_TRX_TYPES_ALL RCTT                          --,AR_LOOKUPS AL
                                    ,
          OE_ORDER_HEADERS_ALL OOH,
          OE_ORDER_LINES_ALL OOL,
          OE_TRANSACTION_TYPES_TL OTT,
          MTL_PARAMETERS MP
    WHERE     RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
          AND HCA.CUST_ACCOUNT_ID(+) = RCT.SHIP_TO_CUSTOMER_ID
          --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
          AND rctl.inventory_item_id = MSIB.INVENTORY_ITEM_ID
          AND ool.ship_from_org_id = MSIB.ORGANIZATION_ID
          AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
          AND rctt.org_id = rct.org_id
          --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
          --AND AL.LOOKUP_CODE = RCT.REASON_CODE
          --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
          AND ooh.header_id(+) = ool.header_id
          --AND RCTL.INVENTORY_ITEM_ID = ool.inventory_item_id
          AND rctl.interface_line_attribute6 = TO_CHAR (ool.line_id(+))
          --and rctl.interface_line_attribute1 = OOH.ORDER_NUMBER
          AND OTT.TRANSACTION_TYPE_ID(+) = OOL.LINE_TYPE_ID
          AND RCTL.LINE_TYPE <> 'TAX'
          AND ott.language(+) = 'US'
          AND mp.organization_id(+) = ool.ship_from_org_id
          AND rctl.sales_order_line IS NOT NULL
   UNION ALL
   SELECT RCT.TRX_NUMBER Invoice_Number,
          TRUNC (RCT.TRX_DATE) INVOICE_DATE,
          RCTL.SALES_ORDER SALES_ORDER_NUMBER,
          RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
             HCA.ACCOUNT_NUMBER
          || '-'
          || (SELECT hps.party_site_number
                FROM hz_party_sites hps,
                     hz_cust_site_uses_all hcsua,
                     hz_cust_acct_sites_all hcasa
               WHERE     rct.ship_to_site_use_id = hcsua.site_use_id(+)
                     AND hcsua.site_use_code = 'SHIP_TO'
                     AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
                     AND hcasa.party_site_id = hps.party_site_id(+))
             CUSTOMER_NUMBER,
          RCT.PURCHASE_ORDER CUSTOMER_ORDER_NUMBER,
          ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (RCT.CUSTOMER_TRX_ID,
                                                      RCT.TERM_ID,
                                                      RCT.TRX_DATE)
             ORDER_DUE_DATE,
          NULL DATE_CLOSED,
          RCT.FOB_POINT,
          NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                          ,
          XX_AR_GL_CC (rctl.customer_trx_line_id, rctl.line_type, 'GL')
             GL_Account,
          NULL ORDER_CLASS,
          NULL ORDER_STATUS,
          TO_CHAR (RCTL.LINE_NUMBER) LINE_ITEM_NUMBER,
          RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
          NVL (MSIB.SEGMENT1, 'MISSING_ITEM') SKU,
          MSIB.PRIMARY_UNIT_OF_MEASURE UNIT_OF_MEASURE,
          NULL ship_date,
          NULL INVOICE_TYPE,
          NVL (rctl.quantity_ordered, 0) base_qty,
          DECODE (
             SUBSTR (rctl.description, 1, 6),
             '@DSCNT', 0,
             NVL (
                DECODE (rctl.quantity_invoiced,
                        NULL, rctl.quantity_credited,
                        rctl.quantity_invoiced),
                0))
             SELL_QTY,
          NVL (RCTL.EXTENDED_AMOUNT, 0) EXTENDED_PRICE,
          NVL (rctl.unit_selling_price, 0) ext_unit_price,
          NULL price_code,
          RCT.INVOICE_CURRENCY_CODE TRANS_CURRENCY,
          rct.INVOICE_CURRENCY_CODE Func_Currency --,rct.set_of_books_id Func_Currency
                                                 ,
          NULL USER_DEFINED1,
          NULL user_defined2,
          NULL user_defined3,
          NULL USER_DEFINED4,
          NULL user_defined5,
          NULL user_defined_dtl1,
          NULL USER_DEFINED_DTL2,
          NULL USER_DEFINED_DTL3,
          (   RCTL.INTERFACE_LINE_ATTRIBUTE3
           || '|'
           || mp.organization_code
           || '|'
           || rctl.interface_line_attribute2
           || '|'
           || DECODE (rctt.TYPE,
                      'INV', 'Invoice',
                      'CM', 'Credit Memo',
                      'DM', 'Debit Memo',
                      'CB', 'Chargeback',
                      rctt.TYPE)
           || '|'
           || rctt.name
           || '|'
           || ott.name                                           -- || '|TEST'
                                                               --|| al.meaning
          )
             user_defined_dtl4,
          NULL USER_DEFINED_DTL5,
          RCT.ORG_ID,
          rct.creation_date --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                           ,
          xx_ar_gl_cc (rctl.customer_trx_line_id, rctl.line_type, 'DATE')
             gl_date
     FROM RA_CUSTOMER_TRX_ALL RCT,
          RA_CUSTOMER_TRX_LINES_ALL RCTL  --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                        ,
          HZ_CUST_ACCOUNTS_ALL HCA,
          MTL_SYSTEM_ITEMS_B MSIB,
          RA_CUST_TRX_TYPES_ALL RCTT                          --,AR_LOOKUPS AL
                                    ,
          OE_ORDER_HEADERS_ALL OOH,
          OE_TRANSACTION_TYPES_TL OTT,
          MTL_PARAMETERS MP
    WHERE     RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
          AND HCA.CUST_ACCOUNT_ID(+) = RCT.SHIP_TO_CUSTOMER_ID
          --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
          AND RCTL.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID(+)
          AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
          AND rctt.org_id = rct.org_id
          --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
          --AND AL.LOOKUP_CODE = RCT.REASON_CODE
          --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
          AND rctl.interface_line_attribute1 = TO_CHAR (ooh.order_number(+))
          AND msib.organization_id =
                 (SELECT master_organization_id
                    FROM MTL_PARAMETERS MP
                   WHERE organization_id = msib.organization_id)
          AND ott.transaction_type_id(+) = ooh.order_type_id
          AND mp.organization_id(+) = msib.organization_id
          AND ott.language(+) = 'US'
          AND RCTL.LINE_TYPE <> 'TAX'
          AND msib.segment1 NOT LIKE 'FREIGHT%'
          AND rctl.sales_order_line IS NULL
   UNION ALL
   SELECT RCT.TRX_NUMBER Invoice_Number,
          TRUNC (RCT.TRX_DATE) INVOICE_DATE,
          RCTL.SALES_ORDER SALES_ORDER_NUMBER,
          RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
             HCA.ACCOUNT_NUMBER
          || '-'
          || (SELECT hps.party_site_number
                FROM hz_party_sites hps,
                     hz_cust_site_uses_all hcsua,
                     hz_cust_acct_sites_all hcasa
               WHERE     rct.ship_to_site_use_id = hcsua.site_use_id(+)
                     AND hcsua.site_use_code = 'SHIP_TO'
                     AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
                     AND hcasa.party_site_id = hps.party_site_id(+))
             CUSTOMER_NUMBER,
          RCT.PURCHASE_ORDER CUSTOMER_ORDER_NUMBER,
          ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (RCT.CUSTOMER_TRX_ID,
                                                      RCT.TERM_ID,
                                                      RCT.TRX_DATE)
             ORDER_DUE_DATE,
          NULL DATE_CLOSED,
          RCT.FOB_POINT,
          NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                          ,
          XX_AR_GL_CC (rctl.customer_trx_line_id, rctl.line_type, 'GL')
             GL_Account,
          NULL ORDER_CLASS,
          NULL ORDER_STATUS,
          TO_CHAR (RCTL.LINE_NUMBER) LINE_ITEM_NUMBER,
          RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
          NVL (MSIB.SEGMENT1, 'MISSING_ITEM') SKU,
          MSIB.PRIMARY_UNIT_OF_MEASURE UNIT_OF_MEASURE,
          NULL ship_date,
          NULL INVOICE_TYPE,
          NVL (rctl.quantity_ordered, 0) base_qty,
          DECODE (
             SUBSTR (rctl.description, 1, 6),
             '@DSCNT', 0,
             NVL (
                DECODE (rctl.quantity_invoiced,
                        NULL, rctl.quantity_credited,
                        rctl.quantity_invoiced),
                0))
             SELL_QTY,
          NVL (RCTL.EXTENDED_AMOUNT, 0) EXTENDED_PRICE,
          NVL (rctl.unit_selling_price, 0) ext_unit_price,
          NULL price_code,
          RCT.INVOICE_CURRENCY_CODE TRANS_CURRENCY,
          rct.INVOICE_CURRENCY_CODE Func_Currency --,rct.set_of_books_id Func_Currency
                                                 ,
          NULL USER_DEFINED1,
          NULL user_defined2,
          NULL user_defined3,
          NULL USER_DEFINED4,
          NULL user_defined5,
          NULL user_defined_dtl1,
          NULL USER_DEFINED_DTL2,
          NULL USER_DEFINED_DTL3,
          (   RCTL.INTERFACE_LINE_ATTRIBUTE3
           || '|'
           || mp.organization_code
           || '|'
           || rctl.interface_line_attribute2
           || '|'
           || DECODE (rctt.TYPE,
                      'INV', 'Invoice',
                      'CM', 'Credit Memo',
                      'DM', 'Debit Memo',
                      'CB', 'Chargeback',
                      rctt.TYPE)
           || '|'
           || rctt.name
           || '|'
           || ott.name                                           -- || '|TEST'
                                                               --|| al.meaning
          )
             user_defined_dtl4,
          NULL USER_DEFINED_DTL5,
          RCT.ORG_ID,
          rct.creation_date --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                           ,
          xx_ar_gl_cc (rctl.customer_trx_line_id, rctl.line_type, 'DATE')
             gl_date
     FROM RA_CUSTOMER_TRX_ALL RCT,
          RA_CUSTOMER_TRX_LINES_ALL RCTL  --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                        ,
          HZ_CUST_ACCOUNTS_ALL HCA,
          MTL_SYSTEM_ITEMS_B MSIB,
          RA_CUST_TRX_TYPES_ALL RCTT                          --,AR_LOOKUPS AL
                                    ,
          OE_ORDER_HEADERS_ALL OOH,
          OE_TRANSACTION_TYPES_TL OTT,
          MTL_PARAMETERS MP
    WHERE     RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
          AND HCA.CUST_ACCOUNT_ID(+) = RCT.SHIP_TO_CUSTOMER_ID
          --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
          AND RCTL.INVENTORY_ITEM_ID = MSIB.INVENTORY_ITEM_ID(+)
          AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
          AND rctt.org_id = rct.org_id
          --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
          --AND AL.LOOKUP_CODE = RCT.REASON_CODE
          --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
          AND rctl.interface_line_attribute1 = TO_CHAR (ooh.order_number(+))
          AND msib.organization_id =
                 (SELECT master_organization_id
                    FROM MTL_PARAMETERS MP
                   WHERE organization_id = msib.organization_id)
          AND ott.transaction_type_id(+) = ooh.order_type_id
          AND mp.organization_id(+) = msib.organization_id
          AND ott.language(+) = 'US'
          AND RCTL.LINE_TYPE <> 'TAX'
          AND msib.segment1 LIKE 'FREIGHT%'
          AND rctl.sales_order_line IS NULL
   UNION
   SELECT RCT.TRX_NUMBER Invoice_Number,
          TRUNC (RCT.TRX_DATE) INVOICE_DATE,
          RCTL.SALES_ORDER SALES_ORDER_NUMBER,
          RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
             HCA.ACCOUNT_NUMBER
          || '-'
          || (SELECT hps.party_site_number
                FROM hz_party_sites hps,
                     hz_cust_site_uses_all hcsua,
                     hz_cust_acct_sites_all hcasa
               WHERE     rct.ship_to_site_use_id = hcsua.site_use_id(+)
                     AND hcsua.site_use_code = 'SHIP_TO'
                     AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id(+)
                     AND hcasa.party_site_id = hps.party_site_id(+))
             CUSTOMER_NUMBER,
          RCT.PURCHASE_ORDER CUSTOMER_ORDER_NUMBER,
          ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (RCT.CUSTOMER_TRX_ID,
                                                      RCT.TERM_ID,
                                                      RCT.TRX_DATE)
             ORDER_DUE_DATE,
          NULL DATE_CLOSED,
          RCT.FOB_POINT,
          NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                          ,
          XX_AR_GL_CC (rctl.customer_trx_line_id, rctl.line_type, 'GL')
             GL_Account,
          NULL ORDER_CLASS,
          NULL ORDER_STATUS,
          TO_CHAR (RCTL.LINE_NUMBER) LINE_ITEM_NUMBER,
          RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
          NVL (NULL, 'MISSING_ITEM') SKU,
          'N/A' UNIT_OF_MEASURE,
          NULL ship_date,
          NULL INVOICE_TYPE,
          NVL (rctl.quantity_ordered, 0) base_qty,
          DECODE (
             SUBSTR (rctl.description, 1, 6),
             '@DSCNT', 0,
             NVL (
                DECODE (rctl.quantity_invoiced,
                        NULL, rctl.quantity_credited,
                        rctl.quantity_invoiced),
                0))
             SELL_QTY,
          NVL (RCTL.EXTENDED_AMOUNT, 0) EXTENDED_PRICE,
          NVL (rctl.unit_selling_price, 0) ext_unit_price,
          NULL price_code,
          RCT.INVOICE_CURRENCY_CODE TRANS_CURRENCY,
          rct.INVOICE_CURRENCY_CODE Func_Currency --,rct.set_of_books_id Func_Currency
                                                 ,
          NULL USER_DEFINED1,
          NULL user_defined2,
          NULL user_defined3,
          NULL USER_DEFINED4,
          NULL user_defined5,
          NULL user_defined_dtl1,
          NULL USER_DEFINED_DTL2,
          NULL USER_DEFINED_DTL3,
          (   RCTL.INTERFACE_LINE_ATTRIBUTE3
           || '|'
           || mp.organization_code
           || '|'
           || rctl.interface_line_attribute2
           || '|'
           || DECODE (rctt.TYPE,
                      'INV', 'Invoice',
                      'CM', 'Credit Memo',
                      'DM', 'Debit Memo',
                      'CB', 'Chargeback',
                      rctt.TYPE)
           || '|'
           || rctt.name
           || '|'
           || ott.name                                           -- || '|TEST'
                                                               --|| al.meaning
          )
             user_defined_dtl4,
          NULL USER_DEFINED_DTL5,
          RCT.ORG_ID,
          rct.creation_date --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                           ,
          xx_ar_gl_cc (rctl.customer_trx_line_id, rctl.line_type, 'DATE')
             gl_date
     FROM RA_CUSTOMER_TRX_ALL RCT,
          RA_CUSTOMER_TRX_LINES_ALL RCTL  --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                        ,
          HZ_CUST_ACCOUNTS_ALL HCA,
          RA_CUST_TRX_TYPES_ALL RCTT                          --,AR_LOOKUPS AL
                                    ,
          OE_ORDER_HEADERS_ALL OOH,
          OE_TRANSACTION_TYPES_TL OTT,
          MTL_PARAMETERS MP
    WHERE     RCT.CUSTOMER_TRX_ID = RCTL.CUSTOMER_TRX_ID
          AND HCA.CUST_ACCOUNT_ID(+) = RCT.SHIP_TO_CUSTOMER_ID
          --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
          AND RCTT.CUST_TRX_TYPE_ID = RCT.CUST_TRX_TYPE_ID
          AND rctt.org_id = rct.org_id
          --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
          --AND AL.LOOKUP_CODE = RCT.REASON_CODE
          --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
          AND rctl.interface_line_attribute1 = TO_CHAR (ooh.order_number(+))
          AND mp.organization_id = 83
          AND ott.transaction_type_id(+) = ooh.order_type_id
          AND ott.language(+) = 'US'
          AND RCTL.LINE_TYPE <> 'TAX'
          AND rctl.inventory_item_id IS NULL
          AND rctl.sales_order_line IS NULL
   ORDER BY 1, 15;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_INVOICE_EXTRACT_PRC_V FOR APPS.XXINTG_INVOICE_EXTRACT_PRC_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXINTG_INVOICE_EXTRACT_PRC_V FOR APPS.XXINTG_INVOICE_EXTRACT_PRC_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_INVOICE_EXTRACT_PRC_V FOR APPS.XXINTG_INVOICE_EXTRACT_PRC_V;


CREATE OR REPLACE SYNONYM XXINTG.XXINTG_INVOICE_EXTRACT_PRC_V FOR APPS.XXINTG_INVOICE_EXTRACT_PRC_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_INVOICE_EXTRACT_PRC_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_INVOICE_EXTRACT_PRC_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_INVOICE_EXTRACT_PRC_V TO XXINTG;
