DROP VIEW APPS.XX_BI_OE_CUST_V;

/* Formatted on 6/6/2016 4:59:26 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_OE_CUST_V
(
   ALTERNATE_NAME,
   ANALYSIS_YEAR,
   AUTOCASH_RULE_SET,
   CLEARING_DAYS,
   CREATION_DATE,
   CUSTOMER_CLASS,
   CUSTOMER_NAME,
   CUSTOMER_NUMBER,
   CUSTOMER_WEB_SITE,
   DUNNING_SITE,
   FISCAL_YEAR_END_MONTH,
   FREIGHT_CARRIER,
   INVOICE_LINE_GROUPING_RULE,
   LAST_UPDATE_DATE,
   MISSION_STATEMENT,
   NUMBER_OF_EMPLOYEES,
   ORDER_TYPE,
   ORIGINAL_SYSTEM_REFERENCE,
   PRICE_LIST,
   REMAINDER_RULE_SET,
   SALESPERSON,
   SIC_CODE,
   STANDARD_TERMS,
   STATEMENT_CYCLE,
   STATEMENT_SITE,
   TAXPAYER_ID,
   TAX_CODE,
   TAX_REGISTRATION_NUMBER,
   WAREHOUSE,
   YEAR_ESTABLISHED,
   CREATION_DATE_DAY,
   CREATION_DATE_MONTH,
   CREATION_DATE_QUARTER,
   CREATION_DATE_YEAR,
   LAST_UPDATE_DATE_DAY,
   LAST_UPDATE_DATE_MONTH,
   LAST_UPDATE_DATE_QUARTER,
   LAST_UPDATE_DATE_YEAR,
   ACTIVE_FLAG,
   PROSPECT_FLAG,
   CUSTOMER_TYPE,
   CUSTOMER_CATEGORY,
   TAX_ROUNDING_RULE,
   TAX_HEADER_LEVEL_FLAG,
   GSA_INDICATOR,
   SHIP_PARTIAL_FLAG,
   FOB_POINT,
   FREIGHT_TERMS,
   SALES_CHANNEL,
   SALES_PARTNER_FLAG,
   USE_AS_REFERENCE_FLAG,
   COMPETITOR_FLAG,
   ACCOUNT_STATUS,
   CREDIT_RATING,
   RISK_CODE,
   CREDIT_CHECK_FLAG,
   CREDIT_HOLD_FLAG,
   OVERRIDE_TERMS_FLAG,
   ALLOW_DISCOUNT_FLAG,
   DISPUTED_ITEM_FLAG,
   SEND_STATEMENT_FLAG,
   SEND_CREDIT_BALANCE,
   SEND_DUNNING_LETTER_FLAG,
   CONSOLIDATED_BILL_FLAG,
   CONSOLIDATED_BILL_FORMAT,
   CHARGE_INTEREST_FLAG,
   COMPOUND_INTEREST_FLAG,
   TAX_PRINTING_OPTION,
   LOCKBOX_MATCHING_OPTION,
   GLOBAL_FLEX_CONTEXT_VALUE,
   GLOBAL_FLEX_REMIT_PROTEST_IN_2,
   GLOBAL_FLEX_REMIT_INTEREST_I_2,
   INTEREST_PERIOD_DAYS,
   RECEIPT_GRACE_DAYS,
   DISCOUNT_GRACE_DAYS,
   PERCENT_COLLECTABLE,
   NEXT_YEAR_REVENUE,
   CURRENT_YEAR_REVENUE
)
AS
   SELECT                                              /* UNIQUE ATTRIBUTES */
         DECODE (PARTY.PARTY_TYPE,
                 'ORGANIZATION', PARTY.ORGANIZATION_NAME_PHONETIC,
                 NULL),
          DECODE (PARTY.PARTY_TYPE, 'ORGANIZATION', PARTY.ANALYSIS_FY, NULL),
          AHI.HIERARCHY_NAME,
          CP.CLEARING_DAYS,
          CUST_ACCT.CREATION_DATE,
          CUST_ACCT.CUSTOMER_CLASS_CODE,
          PARTY.PARTY_NAME,
          CUST_ACCT.ACCOUNT_NUMBER,
          PARTY.URL,
          NULL,                          /* DUNSU.LOCATION FK Not available,*/
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.FISCAL_YEAREND_MONTH,
                  NULL),
          CUST_ACCT.SHIP_VIA,
          GR.NAME,
          CUST_ACCT.LAST_UPDATE_DATE,
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.MISSION_STATEMENT,
                  NULL),
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.EMPLOYEES_TOTAL,
                  TO_NUMBER (NULL)),
          ORTY.NAME,
          CUST_ACCT.ORIG_SYSTEM_REFERENCE,
          PL.NAME,
          AHIR.HIERARCHY_NAME,
          SAL.NAME,
          DECODE (PARTY.PARTY_TYPE, 'ORGANIZATION', PARTY.SIC_CODE, NULL),
          TE.NAME,
          SCY.NAME,
          NULL,                          /* STASU.LOCATION FK Not available,*/
          PARTY.JGZZ_FISCAL_CODE,
          CUST_ACCT.TAX_CODE,
          PARTY.TAX_REFERENCE,
          ORDE.NAME,
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.YEAR_ESTABLISHED,
                  TO_NUMBER (NULL)),
          (DECODE (
              CUST_ACCT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.CREATION_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             CREATION_DATE_DAY,
          (DECODE (
              CUST_ACCT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.CREATION_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             CREATION_DATE_MONTH,
          (DECODE (
              CUST_ACCT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.CREATION_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             CREATION_DATE_QUARTER,
          (DECODE (
              CUST_ACCT.CREATION_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.CREATION_DATE, 'YYYY'), 'YYYY')
                 || '01',
                 'YYYYMM')))
             CREATION_DATE_YEAR,
          (DECODE (
              CUST_ACCT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.LAST_UPDATE_DATE, 'DD'), 'DD')
                 || '190001',
                 'DDYYYYMM')))
             LAST_UPDATE_DATE_DAY,
          (DECODE (
              CUST_ACCT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.LAST_UPDATE_DATE, 'MM'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_MONTH,
          (DECODE (
              CUST_ACCT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.LAST_UPDATE_DATE, 'Q'), 'MM')
                 || '1900',
                 'MMYYYY')))
             LAST_UPDATE_DATE_QUARTER,
          (DECODE (
              CUST_ACCT.LAST_UPDATE_DATE,
              NULL, TO_DATE (NULL, 'MMDDYYYY'),
              TO_DATE (
                    TO_CHAR (TRUNC (CUST_ACCT.LAST_UPDATE_DATE, 'YYYY'),
                             'YYYY')
                 || '01',
                 'YYYYMM')))
             LAST_UPDATE_DATE_YEAR,
          DECODE (CUST_ACCT.STATUS,
                  'A', 'Active',
                  'D', 'Deleted',
                  'I', 'Inactive',
                  NULL),
          DECODE (
             DECODE (party.TOTAL_NUM_OF_ORDERS,
                     0, 'PROSPECT',
                     1, 'CUSTOMER',
                     'CUSTOMER'),
             'CUSTOMER', 'Customer',
             'NEITHER', 'Neither',
             'PROSPECT', 'Prospect',
             NULL),
          DECODE (CUST_ACCT.CUSTOMER_TYPE,
                  'I', 'Internal',
                  'R', 'External',
                  NULL),
          DECODE (PARTY.CATEGORY_CODE,
                  'CUSTOMER', 'Customer',
                  'PROSPECT', 'Prospect',
                  NULL),
          DECODE (CUST_ACCT.TAX_ROUNDING_RULE,
                  'DOWN', 'Down',
                  'NEAREST', 'Nearest',
                  'UP', 'Up',
                  NULL),
          DECODE (CUST_ACCT.TAX_HEADER_LEVEL_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (
             DECODE (PARTY.PARTY_TYPE,
                     'ORGANIZATION', PARTY.GSA_INDICATOR_FLAG,
                     'N'),
             'N', 'No',
             'Y', 'Yes',
             NULL),
          DECODE (CUST_ACCT.SHIP_PARTIAL,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CUST_ACCT.FOB_POINT,
                  'BUY', 'Buyer',
                  'CUSTOMER SITE', 'Customer Site',
                  'FACTORY', 'Factory',
                  'LOAD', 'Loading Dock',
                  'SEL', 'Seller',
                  'SHIP POINT', 'Shipping Point',
                  NULL),
          DECODE (
             CUST_ACCT.FREIGHT_TERM,
             'COLLECT', 'Collect',
             'DUECOST', 'Prepay 		@/u01/app/oracle/PROD/apps/apps_st/appl/xxintg/12.0.0/patch/115/sql/XX_BI_OE_LOTS_V.sql with cost conversion',
             'Due', 'Prepay 		@/u01/app/oracle/PROD/apps/apps_st/appl/xxintg/12.0.0/patch/115/sql/XX_BI_OE_ODR_LN_V.sql',
             'Paid', 'Prepaid',
             'TBD', 'To Be Determined',
             'THIRD_PARTY', 'Third Party Billing',
             NULL),
          DECODE (CUST_ACCT.SALES_CHANNEL_CODE,
                  '-1', 'Unassigned',
                  'DIRECT', 'Direct',
                  'EMAIL_CENTER', 'Email Center',
                  'INDIRECT', 'Indirect',
                  NULL),
          DECODE (THIRD_PARTY_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (REFERENCE_USE_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (COMPETITOR_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          NULL,
          NULL,
          NULL,
          DECODE (CP.CREDIT_CHECKING,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.CREDIT_HOLD,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.OVERRIDE_TERMS,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.DISCOUNT_TERMS,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.AUTO_REC_INCL_DISPUTED_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (CP.SEND_STATEMENTS,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.CREDIT_BALANCE_STATEMENTS,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (CP.DUNNING_LETTERS,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.CONS_INV_FLAG,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.CONS_INV_TYPE,
                  'DETAIL', 'Detailed Consolidated Billing Invoice',
                  'IMPORTED', 'Imported Consolidated Billing Invoice',
                  'SUMMARY', 'Summary Consolidated Billing Invoice',
                  NULL),
          DECODE (CP.INTEREST_CHARGES,  'N', 'No',  'Y', 'Yes',  NULL),
          DECODE (CP.CHARGE_ON_FINANCE_CHARGE_FLAG,
                  'N', 'No',
                  'Y', 'Yes',
                  NULL),
          DECODE (CP.TAX_PRINTING_OPTION,
                  'EUROPEAN TAX FORMAT', 'European Tax Format',
                  'ITEMIZE AND SUM', 'Itemize And Sum',
                  'ITEMIZE TAXES', 'Itemize Taxes',
                  'ITEMIZE WITH RECAP', 'Itemize With Recap',
                  'RECAP', 'Recap',
                  'RECAP_BY_NAME', 'Summarize By Tax Name',
                  'SUM TAXES', 'Sum Taxes',
                  'TOTAL ONLY', 'Total Tax Only',
                  NULL),
          DECODE (CP.LOCKBOX_MATCHING_OPTION,
                  'CONSOLIDATE_BILL', 'Consolidated Billing Number',
                  'INVOICE', 'Transaction Number',
                  'PURCHASE_ORDER', 'Purchase Order',
                  'SALES_ORDER', 'Sales Order',
                  NULL),
          CP.GLOBAL_ATTRIBUTE_CATEGORY,
          CP.GLOBAL_ATTRIBUTE1,
          CP.GLOBAL_ATTRIBUTE2,                                      /* IDS */
          CP.INTEREST_PERIOD_DAYS,
          CP.PAYMENT_GRACE_DAYS,
          CP.DISCOUNT_GRACE_DAYS,
          CP.PERCENT_COLLECTABLE,
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.NEXT_FY_POTENTIAL_REVENUE,
                  TO_NUMBER (NULL)),
          DECODE (PARTY.PARTY_TYPE,
                  'ORGANIZATION', PARTY.CURR_FY_POTENTIAL_REVENUE,
                  TO_NUMBER (NULL))
     FROM HZ_PARTIES PARTY,
          HZ_CUST_ACCOUNTS CUST_ACCT,
          HZ_CUSTOMER_PROFILES CP,
          SO_PRICE_LISTS PL,
          RA_TERMS TE,
          AR_STATEMENT_CYCLES SCY,
          RA_GROUPING_RULES GR,
          AR_AUTOCASH_HIERARCHIES AHI,
          AR_AUTOCASH_HIERARCHIES AHIR,
          HR_ALL_ORGANIZATION_UNITS orde,
          RA_SALESREPS_ALL SAL,
          SO_ORDER_TYPES_ALL ORTY
    WHERE     CUST_ACCT.PARTY_ID = PARTY.PARTY_ID
          AND CUST_ACCT.CUST_ACCOUNT_ID = CP.CUST_ACCOUNT_ID
          AND CP.SITE_USE_ID IS NULL
          AND CUST_ACCT.PRICE_LIST_ID = PL.PRICE_LIST_ID(+)
          AND CP.STANDARD_TERMS = TE.TERM_ID(+)
          AND CP.STATEMENT_CYCLE_ID = SCY.STATEMENT_CYCLE_ID(+)
          AND CP.GROUPING_RULE_ID = GR.GROUPING_RULE_ID(+)
          AND CP.AUTOCASH_HIERARCHY_ID = AHI.AUTOCASH_HIERARCHY_ID(+)
          AND CP.AUTOCASH_HIERARCHY_ID_FOR_ADR =
                 AHIR.AUTOCASH_HIERARCHY_ID(+)
          AND CUST_ACCT.WAREHOUSE_ID = ORDE.ORGANIZATION_ID(+)
          AND CUST_ACCT.PRIMARY_SALESREP_ID = SAL.SALESREP_ID(+)
          AND CUST_ACCT.ORDER_TYPE_ID = ORTY.ORDER_TYPE_ID(+);


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_OE_CUST_V FOR APPS.XX_BI_OE_CUST_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_OE_CUST_V FOR APPS.XX_BI_OE_CUST_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_OE_CUST_V FOR APPS.XX_BI_OE_CUST_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_OE_CUST_V FOR APPS.XX_BI_OE_CUST_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_CUST_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_CUST_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_OE_CUST_V TO XXINTG;
