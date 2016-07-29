DROP VIEW APPS.XXINTG_SLSRPT_INVOICES_EXT_V;

/* Formatted on 6/6/2016 5:00:11 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_SLSRPT_INVOICES_EXT_V
(
   INVOICE_NUMBER,
   INVOICE_DATE,
   SALES_ORDER_NUMBER,
   ORDER_HEADER_ID,
   ORDER_LINE_ID,
   SALES_ORDER_DATE,
   CUSTOMER_NUMBER,
   CUSTOMER_ORDER_NUMBER,
   ORDER_DUE_DATE,
   DATE_CLOSED,
   FOB_POINT,
   SALESREP_ID,
   DISTRIBUTOR_ID,
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
   DESCRIPTION,
   FED_EX_TRACKING,
   SHIP_DESCRIPTION,
   SHIP_METHOD,
   ORG_ID,
   INV_TYPE,
   INV_TYPE_DESC,
   INV_SOURCE,
   INV_SOURCE_DESC,
   GL_DATE,
   TXN_CREATION_DATE,
   TXN_LINE_LAST_UPD_DATE,
   ACCTPERNUM,
   REGION,
   COGS,
   INTEGRATION_ID
)
AS
   (SELECT DISTINCT "INVOICE_NUMBER",
                    "INVOICE_DATE",
                    "SALES_ORDER_NUMBER",
                    "ORDER_HEADER_ID",
                    "ORDER_LINE_ID",
                    "SALES_ORDER_DATE",
                    "CUSTOMER_NUMBER",
                    "CUSTOMER_ORDER_NUMBER",
                    "ORDER_DUE_DATE",
                    "DATE_CLOSED",
                    "FOB_POINT",
                    "SALESREP_ID",
                    "DISTRIBUTOR_ID",
                    "GL_ACCOUNT",
                    "ORDER_CLASS",
                    "ORDER_STATUS",
                    "LINE_ITEM_NUMBER",
                    "INVOICE_LINE_NUMBER",
                    "SKU",
                    "UNIT_OF_MEASURE",
                    "SHIP_DATE",
                    "INVOICE_TYPE",
                    "BASE_QTY",
                    "SELL_QTY",
                    "EXTENDED_PRICE",
                    "EXT_UNIT_PRICE",
                    "PRICE_CODE",
                    "TRANS_CURRENCY",
                    "FUNC_CURRENCY",
                    "USER_DEFINED1",
                    "USER_DEFINED2",
                    "USER_DEFINED3",
                    "USER_DEFINED4",
                    "USER_DEFINED5",
                    "USER_DEFINED_DTL1",
                    "USER_DEFINED_DTL2",
                    "USER_DEFINED_DTL3",
                    "USER_DEFINED_DTL4",
                    "USER_DEFINED_DTL5",
                    "DESCRIPTION",
                    "FED_EX_TRACKING",
                    "SHIP_DESCRIPTION",
                    "SHIP_METHOD",
                    "ORG_ID",
                    "INV_TYPE",
                    "INV_TYPE_DESC",
                    "INV_SOURCE",
                    "INV_SOURCE_DESC",
                    "GL_DATE",
                    "TXN_CREATION_DATE",
                    "TXN_LINE_LAST_UPD_DATE",
                    "ACCTPERNUM",
                    "REGION",
                    "COGS",
                    "INTEGRATION_ID"
      FROM (WITH COGS
                    AS (SELECT DISTINCT OH.HEADER_ID,
                                        OL.LINE_ID,
                                        OH.ORDER_NUMBER,
                                        OL.LINE_NUMBER,
                                        R.ACCT_PERIOD_NUM,
                                        R.REVENUE_RECOGNITION_PERCENT,
                                        C.UNIT_MATERIAL_COST,
                                        C.UNIT_RESOURCE_COST,
                                        C.UNIT_OVERHEAD_COST,
                                        C.UNIT_OP_COST,
                                        C.UNIT_MOH_COST,
                                        C.UNIT_COST
                          FROM CST_REVENUE_COGS_MATCH_LINES C,
                               CST_REVENUE_RECOGNITION_LINES R,
                               OE_ORDER_LINES_ALL OL,
                               OE_ORDER_HEADERS_ALL OH
                         WHERE     C.REVENUE_OM_LINE_ID =
                                      R.REVENUE_OM_LINE_ID
                               AND OL.HEADER_ID = OH.HEADER_ID
                               AND C.COGS_OM_LINE_ID = OL.LINE_ID),
                 SLSCREDITS AS (SELECT * FROM ONT.OE_SALES_CREDITS),
                 SLSCREDITS2
                    AS (SELECT *
                          FROM oe_Sales_credits
                         WHERE     attribute1 IS NOT NULL
                               AND last_update_date < '09-MAY-2016'
                        UNION ALL
                        SELECT *
                          FROM oe_sales_credits
                         WHERE     last_update_date >= '09-MAY-2016'
                               AND sales_credit_type_id = 2),
                 INVOICE_DATA
                    AS (SELECT "INVOICE_NUMBER",
                               "INVOICE_DATE",
                               "SALES_ORDER_NUMBER",
                               "ORDER_HEADER_ID",
                               "ORDER_LINE_ID",
                               "SALES_ORDER_DATE",
                               "CUSTOMER_NUMBER",
                               "CUSTOMER_ORDER_NUMBER",
                               "ORDER_DUE_DATE",
                               "DATE_CLOSED",
                               "FOB_POINT",                 /*"SALESREP_ID",*/
                               "GL_ACCOUNT",
                               "ORDER_CLASS",
                               "ORDER_STATUS",
                               "LINE_ITEM_NUMBER",
                               "INVOICE_LINE_NUMBER",
                               "SKU",
                               "UNIT_OF_MEASURE",
                               "SHIP_DATE",
                               "INVOICE_TYPE",
                               "BASE_QTY",
                               "SELL_QTY",
                               "EXTENDED_PRICE",
                               "EXT_UNIT_PRICE",
                               "PRICE_CODE",
                               "TRANS_CURRENCY",
                               "FUNC_CURRENCY",
                               "USER_DEFINED1",
                               "USER_DEFINED2",
                               "USER_DEFINED3",
                               "USER_DEFINED4",
                               "USER_DEFINED5",
                               "USER_DEFINED_DTL1",
                               "USER_DEFINED_DTL2",
                               "USER_DEFINED_DTL3",
                               "USER_DEFINED_DTL4",
                               "USER_DEFINED_DTL5",
                               "DESCRIPTION",
                               "FED_EX_TRACKING",
                               "SHIP_DESCRIPTION",
                               "SHIP_METHOD",
                               "ORG_ID",
                               "INV_TYPE",
                               "INV_TYPE_DESC",
                               "INV_SOURCE",
                               "INV_SOURCE_DESC",
                               "GL_DATE",
                               "TXN_CREATION_DATE",
                               "TXN_LINE_LAST_UPD_DATE",
                               TO_NUMBER (
                                     TO_CHAR (
                                        TO_DATE (GL_DATE, 'DD-MON-YYYY'),
                                        'YYYY')
                                  || '00'
                                  || TO_CHAR (
                                        TO_DATE (GL_DATE, 'DD-MON-YYYY'),
                                        'MM'))
                                  "ACCTPERNUM"
                          FROM (SELECT RCT.TRX_NUMBER Invoice_Number,
                                       TRUNC (RCT.TRX_DATE) INVOICE_DATE,
                                       RCTL.SALES_ORDER SALES_ORDER_NUMBER,
                                       OOH.HEADER_ID ORDER_HEADER_ID,
                                       TO_NUMBER (
                                          rctl.interface_line_attribute6)
                                          ORDER_LINE_ID,
                                       RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
                                          HCA.ACCOUNT_NUMBER
                                       || '-'
                                       || (SELECT hps.party_site_number
                                             FROM hz_party_sites hps,
                                                  hz_cust_site_uses_all hcsua,
                                                  hz_cust_acct_sites_all hcasa
                                            WHERE     rct.ship_to_site_use_id =
                                                         hcsua.site_use_id(+)
                                                  AND hcsua.site_use_code =
                                                         'SHIP_TO'
                                                  AND hcsua.cust_acct_site_id =
                                                         hcasa.cust_acct_site_id(+)
                                                  AND hcasa.party_site_id =
                                                         hps.party_site_id(+))
                                          CUSTOMER_NUMBER,
                                       RCT.PURCHASE_ORDER
                                          CUSTOMER_ORDER_NUMBER,
                                       ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (
                                          RCT.CUSTOMER_TRX_ID,
                                          RCT.TERM_ID,
                                          RCT.TRX_DATE)
                                          ORDER_DUE_DATE,
                                       NULL DATE_CLOSED,
                                       RCT.FOB_POINT,
                                       NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                                                       ,
                                       XX_AR_GL_CC (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'GL')
                                          GL_Account,
                                       NULL ORDER_CLASS,
                                       NULL ORDER_STATUS,
                                       TO_CHAR (RCTL.LINE_NUMBER)
                                          LINE_ITEM_NUMBER,
                                       RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
                                       NVL (MSIB.SEGMENT1, 'MISSING_ITEM')
                                          SKU,
                                       MSIB.PRIMARY_UNIT_OF_MEASURE
                                          UNIT_OF_MEASURE,
                                       NULL ship_date,
                                       NULL INVOICE_TYPE,
                                       NVL (rctl.quantity_ordered, 0)
                                          base_qty,
                                       rctl.description,
                                       DECODE (
                                          SUBSTR (rctl.description, 1, 6),
                                          '@DSCNT', 0,
                                          NVL (
                                             DECODE (
                                                rctl.quantity_invoiced,
                                                NULL, rctl.quantity_credited,
                                                rctl.quantity_invoiced),
                                             0))
                                          SELL_QTY,
                                       NVL (RCTL.EXTENDED_AMOUNT, 0)
                                          EXTENDED_PRICE,
                                       NVL (rctl.unit_selling_price, 0)
                                          ext_unit_price,
                                       NULL price_code,
                                       RCT.INVOICE_CURRENCY_CODE
                                          TRANS_CURRENCY,
                                       rct.INVOICE_CURRENCY_CODE
                                          Func_Currency --,rct.set_of_books_id Func_Currency
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
                                        || ott.name              -- || '|TEST'
                                                               --|| al.meaning
                                       )
                                          user_defined_dtl4,
                                       NULL USER_DEFINED_DTL5,
                                       (SELECT DISTINCT meaning
                                          FROM fnd_lookup_values_vl
                                         WHERE     lookup_type =
                                                      'CREDIT_MEMO_REASON'
                                               AND (view_application_id = 222)
                                               AND (security_group_id = 0)
                                               AND lookup_code =
                                                      RCT.REASON_CODE)
                                          SHIP_METHOD,
                                       RCT.WAYBILL_NUMBER FED_EX_TRACKING,
                                       RCT.SHIP_VIA SHIP_DESCRIPTION,
                                       RCT.ORG_ID,
                                       rct.creation_date TXN_CREATION_DATE,
                                       rctt.name INV_TYPE,
                                       rctt.DESCRIPTION INV_TYPE_DESC,
                                       RBS.NAME INV_SOURCE,
                                       RBS.DESCRIPTION INV_SOURCE_DESC --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                                                                      ,
                                       XX_AR_GL_CC (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'DATE')
                                          GL_DATE --,TO_DATE(rctl.last_update_date,'DD-MON-YYYY HH24:MI:SS') TXN_LINE_LAST_UPD_DATE
                                                 ,
                                       rctl.last_update_date
                                          TXN_LINE_LAST_UPD_DATE
                                  FROM RA_CUSTOMER_TRX_ALL RCT,
                                       RA_CUSTOMER_TRX_LINES_ALL RCTL --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                                                     ,
                                       HZ_CUST_ACCOUNTS_ALL HCA,
                                       MTL_SYSTEM_ITEMS_B MSIB,
                                       RA_CUST_TRX_TYPES_ALL RCTT,
                                       AR.RA_BATCH_SOURCES_ALL RBS --,AR_LOOKUPS AL
                                                                  ,
                                       OE_ORDER_HEADERS_ALL OOH,
                                       OE_ORDER_LINES_ALL OOL,
                                       OE_TRANSACTION_TYPES_TL OTT,
                                       MTL_PARAMETERS MP
                                 WHERE     RCT.CUSTOMER_TRX_ID =
                                              RCTL.CUSTOMER_TRX_ID
                                       AND HCA.CUST_ACCOUNT_ID(+) =
                                              RCT.SHIP_TO_CUSTOMER_ID
                                       --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
                                       AND rctl.inventory_item_id =
                                              MSIB.INVENTORY_ITEM_ID
                                       AND ool.ship_from_org_id =
                                              MSIB.ORGANIZATION_ID
                                       AND RCTT.CUST_TRX_TYPE_ID =
                                              RCT.CUST_TRX_TYPE_ID
                                       AND RBS.BATCH_SOURCE_ID =
                                              RCT.BATCH_SOURCE_ID
                                       AND rctt.org_id = rct.org_id
                                       --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
                                       --AND AL.LOOKUP_CODE = RCT.REASON_CODE
                                       --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
                                       AND ooh.header_id(+) = ool.header_id
                                       --AND RCTL.INVENTORY_ITEM_ID = ool.inventory_item_id
                                       AND rctl.interface_line_attribute6 =
                                              TO_CHAR (ool.line_id(+))
                                       --and rctl.interface_line_attribute1 = OOH.ORDER_NUMBER
                                       AND OTT.TRANSACTION_TYPE_ID(+) =
                                              OOL.LINE_TYPE_ID
                                       AND RCTL.LINE_TYPE <> 'TAX'
                                       AND ott.language(+) = 'US'
                                       AND mp.organization_id(+) =
                                              ool.ship_from_org_id
                                       AND rctl.sales_order_line IS NOT NULL
                                UNION ALL
                                SELECT RCT.TRX_NUMBER Invoice_Number,
                                       TRUNC (RCT.TRX_DATE) INVOICE_DATE,
                                       RCTL.SALES_ORDER SALES_ORDER_NUMBER,
                                       OOH.HEADER_ID ORDER_HEADER_ID,
                                       TO_NUMBER (
                                          rctl.interface_line_attribute6)
                                          ORDER_LINE_ID,
                                       RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
                                          HCA.ACCOUNT_NUMBER
                                       || '-'
                                       || (SELECT hps.party_site_number
                                             FROM hz_party_sites hps,
                                                  hz_cust_site_uses_all hcsua,
                                                  hz_cust_acct_sites_all hcasa
                                            WHERE     rct.ship_to_site_use_id =
                                                         hcsua.site_use_id(+)
                                                  AND hcsua.site_use_code =
                                                         'SHIP_TO'
                                                  AND hcsua.cust_acct_site_id =
                                                         hcasa.cust_acct_site_id(+)
                                                  AND hcasa.party_site_id =
                                                         hps.party_site_id(+))
                                          CUSTOMER_NUMBER,
                                       RCT.PURCHASE_ORDER
                                          CUSTOMER_ORDER_NUMBER,
                                       ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (
                                          RCT.CUSTOMER_TRX_ID,
                                          RCT.TERM_ID,
                                          RCT.TRX_DATE)
                                          ORDER_DUE_DATE,
                                       NULL DATE_CLOSED,
                                       RCT.FOB_POINT,
                                       NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                                                       ,
                                       XX_AR_GL_CC (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'GL')
                                          GL_Account,
                                       NULL ORDER_CLASS,
                                       NULL ORDER_STATUS,
                                       TO_CHAR (RCTL.LINE_NUMBER)
                                          LINE_ITEM_NUMBER,
                                       RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
                                       NVL (MSIB.SEGMENT1, 'MISSING_ITEM')
                                          SKU,
                                       MSIB.PRIMARY_UNIT_OF_MEASURE
                                          UNIT_OF_MEASURE,
                                       NULL ship_date,
                                       NULL INVOICE_TYPE,
                                       NVL (rctl.quantity_ordered, 0)
                                          base_qty,
                                       rctl.description,
                                       DECODE (
                                          SUBSTR (rctl.description, 1, 6),
                                          '@DSCNT', 0,
                                          NVL (
                                             DECODE (
                                                rctl.quantity_invoiced,
                                                NULL, rctl.quantity_credited,
                                                rctl.quantity_invoiced),
                                             0))
                                          SELL_QTY,
                                       NVL (RCTL.EXTENDED_AMOUNT, 0)
                                          EXTENDED_PRICE,
                                       NVL (rctl.unit_selling_price, 0)
                                          ext_unit_price,
                                       NULL price_code,
                                       RCT.INVOICE_CURRENCY_CODE
                                          TRANS_CURRENCY,
                                       rct.INVOICE_CURRENCY_CODE
                                          Func_Currency --,rct.set_of_books_id Func_Currency
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
                                        || ott.name              -- || '|TEST'
                                                               --|| al.meaning
                                       )
                                          user_defined_dtl4,
                                       NULL USER_DEFINED_DTL5,
                                       (SELECT DISTINCT meaning
                                          FROM fnd_lookup_values_vl
                                         WHERE     lookup_type =
                                                      'CREDIT_MEMO_REASON'
                                               AND (view_application_id = 222)
                                               AND (security_group_id = 0)
                                               AND lookup_code =
                                                      RCT.REASON_CODE)
                                          SHIP_METHOD,
                                       RCT.WAYBILL_NUMBER FED_EX_TRACKING,
                                       RCT.SHIP_VIA SHIP_DESCRIPTION,
                                       RCT.ORG_ID,
                                       rct.creation_date TXN_CREATION_DATE,
                                       rctt.name INV_TYPE,
                                       rctt.DESCRIPTION INV_TYPE_DESC,
                                       RBS.NAME INV_SOURCE,
                                       RBS.DESCRIPTION INV_SOURCE_DESC --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                                                                      ,
                                       xx_ar_gl_cc (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'DATE')
                                          gl_date --,TO_DATE(rctl.last_update_date,'DD-MON-YYYY HH24:MI:SS') TXN_LINE_LAST_UPD_DATE
                                                 ,
                                       rctl.last_update_date
                                          TXN_LINE_LAST_UPD_DATE
                                  FROM RA_CUSTOMER_TRX_ALL RCT,
                                       RA_CUSTOMER_TRX_LINES_ALL RCTL --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                                                     ,
                                       HZ_CUST_ACCOUNTS_ALL HCA,
                                       MTL_SYSTEM_ITEMS_B MSIB,
                                       RA_CUST_TRX_TYPES_ALL RCTT,
                                       AR.RA_BATCH_SOURCES_ALL RBS --,AR_LOOKUPS AL
                                                                  ,
                                       OE_ORDER_HEADERS_ALL OOH,
                                       OE_TRANSACTION_TYPES_TL OTT,
                                       MTL_PARAMETERS MP
                                 WHERE     RCT.CUSTOMER_TRX_ID =
                                              RCTL.CUSTOMER_TRX_ID
                                       AND HCA.CUST_ACCOUNT_ID(+) =
                                              RCT.SHIP_TO_CUSTOMER_ID
                                       --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
                                       AND RCTL.INVENTORY_ITEM_ID =
                                              MSIB.INVENTORY_ITEM_ID(+)
                                       AND RCTT.CUST_TRX_TYPE_ID =
                                              RCT.CUST_TRX_TYPE_ID
                                       AND RBS.BATCH_SOURCE_ID =
                                              RCT.BATCH_SOURCE_ID
                                       AND rctt.org_id = rct.org_id
                                       --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
                                       --AND AL.LOOKUP_CODE = RCT.REASON_CODE
                                       --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
                                       AND rctl.interface_line_attribute1 =
                                              TO_CHAR (ooh.order_number(+))
                                       AND msib.organization_id =
                                              (SELECT master_organization_id
                                                 FROM MTL_PARAMETERS MP
                                                WHERE organization_id =
                                                         msib.organization_id)
                                       AND ott.transaction_type_id(+) =
                                              ooh.order_type_id
                                       AND mp.organization_id(+) =
                                              msib.organization_id
                                       AND ott.language(+) = 'US'
                                       AND RCTL.LINE_TYPE <> 'TAX'
                                       AND msib.segment1 NOT LIKE 'FREIGHT%'
                                       AND rctl.sales_order_line IS NULL
                                UNION ALL
                                SELECT RCT.TRX_NUMBER Invoice_Number,
                                       TRUNC (RCT.TRX_DATE) INVOICE_DATE,
                                       RCTL.SALES_ORDER SALES_ORDER_NUMBER,
                                       OOH.HEADER_ID ORDER_HEADER_ID,
                                       TO_NUMBER (
                                          rctl.interface_line_attribute6)
                                          ORDER_LINE_ID,
                                       RCTL.SALES_ORDER_DATE SALES_ORDER_DATE,
                                          HCA.ACCOUNT_NUMBER
                                       || '-'
                                       || (SELECT hps.party_site_number
                                             FROM hz_party_sites hps,
                                                  hz_cust_site_uses_all hcsua,
                                                  hz_cust_acct_sites_all hcasa
                                            WHERE     rct.ship_to_site_use_id =
                                                         hcsua.site_use_id(+)
                                                  AND hcsua.site_use_code =
                                                         'SHIP_TO'
                                                  AND hcsua.cust_acct_site_id =
                                                         hcasa.cust_acct_site_id(+)
                                                  AND hcasa.party_site_id =
                                                         hps.party_site_id(+))
                                          CUSTOMER_NUMBER,
                                       RCT.PURCHASE_ORDER
                                          CUSTOMER_ORDER_NUMBER,
                                       ARPT_SQL_FUNC_UTIL.GET_FIRST_REAL_DUE_DATE (
                                          RCT.CUSTOMER_TRX_ID,
                                          RCT.TERM_ID,
                                          RCT.TRX_DATE)
                                          ORDER_DUE_DATE,
                                       NULL DATE_CLOSED,
                                       RCT.FOB_POINT,
                                       NULL salesrep_id --,xx_ar_gl_cc(rctl.customer_trx_line_id,'GL') gl_account
                                                       ,
                                       XX_AR_GL_CC (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'GL')
                                          GL_Account,
                                       NULL ORDER_CLASS,
                                       NULL ORDER_STATUS,
                                       TO_CHAR (RCTL.LINE_NUMBER)
                                          LINE_ITEM_NUMBER,
                                       RCTL.LINE_NUMBER INVOICE_LINE_NUMBER,
                                       NVL (MSIB.SEGMENT1, 'MISSING_ITEM')
                                          SKU,
                                       MSIB.PRIMARY_UNIT_OF_MEASURE
                                          UNIT_OF_MEASURE,
                                       NULL ship_date,
                                       NULL INVOICE_TYPE,
                                       NVL (rctl.quantity_ordered, 0)
                                          base_qty,
                                       rctl.description,
                                       DECODE (
                                          SUBSTR (rctl.description, 1, 6),
                                          '@DSCNT', 0,
                                          NVL (
                                             DECODE (
                                                rctl.quantity_invoiced,
                                                NULL, rctl.quantity_credited,
                                                rctl.quantity_invoiced),
                                             0))
                                          SELL_QTY,
                                       NVL (RCTL.EXTENDED_AMOUNT, 0)
                                          EXTENDED_PRICE,
                                       NVL (rctl.unit_selling_price, 0)
                                          ext_unit_price,
                                       NULL price_code,
                                       RCT.INVOICE_CURRENCY_CODE
                                          TRANS_CURRENCY,
                                       rct.INVOICE_CURRENCY_CODE
                                          Func_Currency --,rct.set_of_books_id Func_Currency
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
                                        || ott.name              -- || '|TEST'
                                                               --|| al.meaning
                                       )
                                          user_defined_dtl4,
                                       NULL USER_DEFINED_DTL5,
                                       (SELECT DISTINCT meaning
                                          FROM fnd_lookup_values_vl
                                         WHERE     lookup_type =
                                                      'CREDIT_MEMO_REASON'
                                               AND (view_application_id = 222)
                                               AND (security_group_id = 0)
                                               AND lookup_code =
                                                      RCT.REASON_CODE)
                                          SHIP_METHOD,
                                       RCT.WAYBILL_NUMBER FED_EX_TRACKING,
                                       RCT.SHIP_VIA SHIP_DESCRIPTION,
                                       RCT.ORG_ID,
                                       rct.creation_date TXN_CREATION_DATE,
                                       rctt.name INV_TYPE,
                                       rctt.DESCRIPTION INV_TYPE_DESC,
                                       RBS.NAME INV_SOURCE,
                                       RBS.DESCRIPTION INV_SOURCE_DESC --,xx_ar_gl_cc(rctl.customer_trx_line_id,'DATE') gl_date
                                                                      ,
                                       xx_ar_gl_cc (
                                          rctl.customer_trx_line_id,
                                          rctl.line_type,
                                          'DATE')
                                          gl_date --,TO_DATE(rctl.last_update_date,'DD-MON-YYYY HH24:MI:SS') TXN_LINE_LAST_UPD_DATE
                                                 ,
                                       rctl.last_update_date
                                          TXN_LINE_LAST_UPD_DATE
                                  FROM RA_CUSTOMER_TRX_ALL RCT,
                                       RA_CUSTOMER_TRX_LINES_ALL RCTL --,RA_CUST_TRX_LINE_GL_DIST_ALL RCGL
                                                                     ,
                                       HZ_CUST_ACCOUNTS_ALL HCA,
                                       MTL_SYSTEM_ITEMS_B MSIB,
                                       RA_CUST_TRX_TYPES_ALL RCTT,
                                       AR.RA_BATCH_SOURCES_ALL RBS --,AR_LOOKUPS AL
                                                                  ,
                                       OE_ORDER_HEADERS_ALL OOH,
                                       OE_TRANSACTION_TYPES_TL OTT,
                                       MTL_PARAMETERS MP
                                 WHERE     RCT.CUSTOMER_TRX_ID =
                                              RCTL.CUSTOMER_TRX_ID
                                       AND HCA.CUST_ACCOUNT_ID(+) =
                                              RCT.SHIP_TO_CUSTOMER_ID
                                       --and rctl.customer_trx_line_id = rcgl.customer_trx_line_id
                                       AND RCTL.INVENTORY_ITEM_ID =
                                              MSIB.INVENTORY_ITEM_ID(+)
                                       AND RCTT.CUST_TRX_TYPE_ID =
                                              RCT.CUST_TRX_TYPE_ID
                                       AND RBS.BATCH_SOURCE_ID =
                                              RCT.BATCH_SOURCE_ID
                                       AND rctt.org_id = rct.org_id
                                       --AND AL.LOOKUP_TYPE = 'CREDIT_MEMO_REASON'
                                       --AND AL.LOOKUP_CODE = RCT.REASON_CODE
                                       --AND OOH.ORDER_NUMBER = RCTL.SALES_ORDER
                                       AND rctl.interface_line_attribute1 =
                                              TO_CHAR (ooh.order_number(+))
                                       AND msib.organization_id =
                                              (SELECT master_organization_id
                                                 FROM MTL_PARAMETERS MP
                                                WHERE organization_id =
                                                         msib.organization_id)
                                       AND ott.transaction_type_id(+) =
                                              ooh.order_type_id
                                       AND mp.organization_id(+) =
                                              msib.organization_id
                                       AND ott.language(+) = 'US'
                                       AND RCTL.LINE_TYPE <> 'TAX'
                                       AND msib.segment1 LIKE 'FREIGHT%'
                                       AND rctl.sales_order_line IS NULL))
            SELECT I."INVOICE_NUMBER",
                   I."INVOICE_DATE",
                   I."SALES_ORDER_NUMBER",
                   I."ORDER_HEADER_ID",
                   I."ORDER_LINE_ID",
                   I."SALES_ORDER_DATE",
                   I."CUSTOMER_NUMBER",
                   I."CUSTOMER_ORDER_NUMBER",
                   I."ORDER_DUE_DATE",
                   I."DATE_CLOSED",
                   I."FOB_POINT",                           /*"SALESREP_ID",*/
                   "GL_ACCOUNT",
                   I."ORDER_CLASS",
                   I."ORDER_STATUS",
                   I."LINE_ITEM_NUMBER",
                   I."INVOICE_LINE_NUMBER",
                   I."SKU",
                   I."UNIT_OF_MEASURE",
                   I."SHIP_DATE",
                   I."INVOICE_TYPE",
                   I."BASE_QTY",
                   I."SELL_QTY",
                   I."EXTENDED_PRICE",
                   I."EXT_UNIT_PRICE",
                   I."PRICE_CODE",
                   I."TRANS_CURRENCY",
                   I."FUNC_CURRENCY",
                   I."USER_DEFINED1",
                   I."USER_DEFINED2",
                   I."USER_DEFINED3",
                   I."USER_DEFINED4",
                   I."USER_DEFINED5",
                   I."USER_DEFINED_DTL1",
                   I."USER_DEFINED_DTL2",
                   I."USER_DEFINED_DTL3",
                   I."USER_DEFINED_DTL4",
                   I."USER_DEFINED_DTL5",
                   I."DESCRIPTION",
                   I."FED_EX_TRACKING",
                   I."SHIP_DESCRIPTION",
                   I."SHIP_METHOD",
                   I."ORG_ID",
                   I."INV_TYPE",
                   I."INV_TYPE_DESC",
                   I."INV_SOURCE",
                   I."INV_SOURCE_DESC",
                   I."GL_DATE",
                   I."TXN_CREATION_DATE",
                   (TO_CHAR (
                       GREATEST (
                          NVL (
                             (SELECT NVL (
                                        s1.last_update_date,
                                        TO_DATE ('01-JAN-1900', 'DD-MM-YYYY'))
                                FROM SLSCREDITS S1
                               WHERE     I.ORDER_HEADER_ID = S1.HEADER_ID(+)
                                     AND I.ORDER_LINE_ID = S1.LINE_ID(+)
                                     AND S1.SALES_CREDIT_TYPE_ID = 1),
                             TO_DATE ('01-JAN-1900', 'DD-MM-YYYY')),
                          NVL (
                             (SELECT NVL (
                                        s2.last_update_date,
                                        TO_DATE ('01-JAN-1900', 'DD-MM-YYYY'))
                                FROM SLSCREDITS S2
                               WHERE     I.ORDER_HEADER_ID = S2.HEADER_ID(+)
                                     AND I.ORDER_LINE_ID = S2.LINE_ID(+)
                                     AND S2.SALES_CREDIT_TYPE_ID = 2),
                             TO_DATE ('01-JAN-1900', 'DD-MM-YYYY')),
                          TO_DATE (I.TXN_LINE_LAST_UPD_DATE,
                                   'DD-MON-YY HH24:MI:SS')),
                       'DD-MON-YYYY HH24:MI:SS'))
                      "TXN_LINE_LAST_UPD_DATE",
                   I."ACCTPERNUM",
                   C.UNIT_COST "COGS",
                   (SELECT S2.ATTRIBUTE1
                      FROM SLSCREDITS2 S2
                     WHERE     I.ORDER_HEADER_ID = S2.HEADER_ID
                           AND I.ORDER_LINE_ID = S2.LINE_ID)
                      "REGION",
                   (SELECT NVL (S1.ATTRIBUTE3, S1.SALESREP_ID)
                      FROM SLSCREDITS S1
                     WHERE     I.ORDER_HEADER_ID = S1.HEADER_ID(+)
                           AND I.ORDER_LINE_ID = S1.LINE_ID(+)
                           AND S1.SALES_CREDIT_TYPE_ID = 1)
                      DISTRIBUTOR_ID,
                   (SELECT NVL (S2.ATTRIBUTE3, S2.SALESREP_ID)
                      FROM SLSCREDITS S2
                     WHERE     I.ORDER_HEADER_ID = S2.HEADER_ID(+)
                           AND I.ORDER_LINE_ID = S2.LINE_ID(+)
                           AND S2.SALES_CREDIT_TYPE_ID = 2)
                      SALESREP_ID,
                   I.INVOICE_NUMBER || '~' || I.LINE_ITEM_NUMBER
                      "INTEGRATION_ID"
              FROM INVOICE_DATA I, COGS C
             WHERE     TO_NUMBER (I.ORDER_LINE_ID) = C.LINE_ID(+)
                   AND I.ORDER_HEADER_ID = C.HEADER_ID(+)
                   AND I.ACCTPERNUM = C.ACCT_PERIOD_NUM(+)));


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_SLSRPT_INVOICES_EXT_V FOR APPS.XXINTG_SLSRPT_INVOICES_EXT_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXINTG_SLSRPT_INVOICES_EXT_V FOR APPS.XXINTG_SLSRPT_INVOICES_EXT_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_SLSRPT_INVOICES_EXT_V FOR APPS.XXINTG_SLSRPT_INVOICES_EXT_V;


CREATE OR REPLACE SYNONYM XXINTG.XXINTG_SLSRPT_INVOICES_EXT_V FOR APPS.XXINTG_SLSRPT_INVOICES_EXT_V;


GRANT SELECT ON APPS.XXINTG_SLSRPT_INVOICES_EXT_V TO ETLEBSUSER;
