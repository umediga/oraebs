DROP VIEW APPS.XX_BI_M2C_QUOTE_V;

/* Formatted on 6/6/2016 4:59:28 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_QUOTE_V
(
   QUOTE_TAKER,
   QUOTE_NUMBER,
   CUSTOMER_NUMBER,
   CUSTOMER_NAME,
   QUOTE_AMOUNT,
   STATUS_OF_QUOTE,
   SALES_ORDER_NUMBER,
   SALES_ORDER_AMOUNT,
   SALES_ORDER_DATE,
   QUOTE_DATE,
   SALES_REP_NAME,
   MARGIN,
   QUOTE_EXPIRATION_DATE,
   DIVISION,
   CURRENCY,
   NEW_BUSINESS,
   EXISTING_BUSINESS,
   DATE_OF_LAST_INCREASE,
   BUSINESS_RATIONAL_FOR_DISCOUNT,
   DESC_OF_PROPOSED_DISCOUNT,
   INTERNAL_NOTES
)
AS
   SELECT AQH.QUOTE_NAME Quote_Taker,
          AQH.QUOTE_NUMBER Quote_Number,
          SOLD_HP.PARTY_NUMBER Customer_Number,
          SOLD_HP.PARTY_NAME Customer_Name,
          AQH.TOTAL_QUOTE_PRICE Quote_Amount,
          AQS.STATUS_CODE Status_of_Quote,
          OOH.ORDER_NUMBER Sales_Order_Number,
          OOH.PAYMENT_AMOUNT Sales_Order_Amount,
          OOH.CREATION_DATE Sales_Order_Date,
          AQH.CREATION_DATE Quote_Date,
          JRS.NAME Sales_Rep_Name,
          NULL Margin,             ---This can't be calculated at header level
          AQH.QUOTE_EXPIRATION_DATE Quote_Expiration_Date,
          NULL Division,
          AQH.CURRENCY_CODE Currency,
          NULL New_Business,
          NULL Existing_Business,
          NULL Date_of_Last_Increase,
          NULL Business_Rational_For_Discount,
          NULL Desc_of_Proposed_Discount,
          NULL Internal_Notes
     FROM ASO_QUOTE_HEADERS_ALL AQH,
          ASO_QUOTE_STATUSES_B AQS,
          OE_ORDER_HEADERS_ALL OOH,
          HZ_CUST_ACCT_SITES_ALL hcasa,
          HZ_CUST_SITE_USES_ALL hcsua,
          HZ_PARTIES sold_hp,
          HZ_PARTY_SITES hps,
          HZ_CUST_ACCOUNTS sold_ca,
          JTF_RS_SALESREPS JRS
    --- XX_SDC_QUOTE_HDR_STG                      ----This staging table does not contain data,hence hardcoded null values for that columns
    WHERE     AQH.QUOTE_STATUS_ID = AQS.QUOTE_STATUS_ID
          AND AQH.ORDER_ID = OOH.HEADER_ID
          AND AQH.QUOTE_HEADER_ID = OOH.SOURCE_DOCUMENT_ID
          AND JRS.SALESREP_ID = OOH.SALESREP_ID
          AND sold_hp.party_id = sold_ca.party_id
          AND sold_ca.cust_account_id = OOH.sold_to_org_id
          AND OOH.ship_to_org_id = hcsua.site_use_id
          AND sold_ca.cust_account_id = hcasa.cust_account_id
          AND AQH.CUST_ACCOUNT_ID = hcasa.CUST_ACCOUNT_ID
          AND hcasa.cust_acct_site_id = hcsua.cust_acct_site_id
          AND hcasa.PARTY_SITE_ID = hps.PARTY_SITE_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_QUOTE_V FOR APPS.XX_BI_M2C_QUOTE_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_QUOTE_V FOR APPS.XX_BI_M2C_QUOTE_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_QUOTE_V FOR APPS.XX_BI_M2C_QUOTE_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_QUOTE_V FOR APPS.XX_BI_M2C_QUOTE_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_QUOTE_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_QUOTE_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_QUOTE_V TO XXINTG;
