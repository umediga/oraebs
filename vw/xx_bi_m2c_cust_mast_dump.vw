DROP VIEW APPS.XX_BI_M2C_CUST_MAST_DUMP;

/* Formatted on 6/6/2016 4:59:30 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_CUST_MAST_DUMP
(
   PARTY_NUMBER,
   PARTY_SYSTEM_REFERENCE,
   PARTY_NAME,
   PARTY_TYPE,
   PARTY_STATUS,
   ACCOUNT_NUMBER,
   ACCOUNT_REFERENCE,
   CUST_ACCOUNT_ID,
   ACCOUNT_DESCRIPTION,
   ACCOUNT_STATUS,
   CUSTOMER_TYPE,
   CUSTOMER_CLASS_CODE,
   ACCOUNT_PRICE_LIST,
   SITE_USE_ID,
   SITE_USE_CODE,
   PRIMARY_FLAG,
   SITE_USE_STATUS,
   SITE_USE_THIRD_PARTY_FREIGHT,
   SITE_USE_PRICE_LIST,
   SHIP_VIA,
   FREIGHT_TERM,
   FOB_POINT,
   FREIGHT_ACCOUNT_NUMBER1,
   FREIGHT_ACCOUNT_NUMBER2,
   PARTY_SITE_NUMBER,
   IDENTIFYING_ADDRESS_FLAG,
   SITE_ATTRIBUTE_CATEGORY,
   GPO_ENTITY,
   GLN_NUMBER,
   CERTIFICATE_COMPLIANCE,
   NATIONALITY,
   B2B_TRANSLATION,
   B2B_EDI_LOCATION,
   EDI_DOCUMENT_TYPE,
   EDI_FLAG,
   ADDRESS1,
   ADDRESS2,
   ADDRESS3,
   ADDRESS4,
   CITY,
   POSTAL_CODE,
   STATE,
   COUNTY,
   COUNTRY,
   OVERALL_CREDIT_LIMIT,
   CURRENCY_CODE,
   PAYMENT_TERMS,
   PROFILE_CLASS,
   RELATED_CUST_ACCOUNT_ID,
   RELATED_ACCOUNT_NUMBER,
   RELATIONSHIP_TYPE,
   RELATE_BILL_TO_FLAG,
   RELATE_SHIP_TO_FLAG,
   RELATIONSHIP_COMMENTS,
   RELATE_RECIPROCAL_FLAG,
   RELATED_ACC_NUM_ATTRIB_CAT,
   INTERNAL_LOCATION,
   INTERNAL_ORGANIZATION
)
AS
     SELECT P.PARTY_NUMBER,
            P.ORIG_SYSTEM_REFERENCE PARTY_SYSTEM_REFERENCE,
            P.PARTY_NAME,
            P.PARTY_TYPE,
            P.STATUS AS PARTY_STATUS,
            CA.ACCOUNT_NUMBER,
            CA.ORIG_SYSTEM_REFERENCE ACCOUNT_REFERENCE,
            CA.CUST_ACCOUNT_ID,
            CA.ACCOUNT_NAME ACCOUNT_DESCRIPTION,
            CA.STATUS AS ACCOUNT_STATUS,
            CA.CUSTOMER_TYPE,
            CA.CUSTOMER_CLASS_CODE,
            --CA.ATTRIBUTE9 ACCOUNT_PRICE_LIST,
            (SELECT PL.NAME
               FROM QP_LIST_HEADERS_TL PL
              WHERE     PL.LIST_HEADER_ID = CA.PRICE_LIST_ID
                    AND PL.LANGUAGE(+) = USERENV ('LANG'))
               ACCOUNT_PRICE_LIST,
            CSUA.SITE_USE_ID,
            CSUA.SITE_USE_CODE,
            CSUA.PRIMARY_FLAG,
            CSUA.STATUS AS SITE_USE_STATUS,
            CSUA.ATTRIBUTE3 SITE_USE_THIRD_PARTY_FREIGHT,
            CSUA.ATTRIBUTE9 SITE_USE_PRICE_LIST,
            CSUA.SHIP_VIA,
            CSUA.FREIGHT_TERM,
            CSUA.FOB_POINT,
            CSUA.ATTRIBUTE3 FREIGHT_ACCOUNT_NUMBER1,
            CSUA.ATTRIBUTE4 FREIGHT_ACCOUNT_NUMBER2,
            PS.PARTY_SITE_NUMBER,
            PS.IDENTIFYING_ADDRESS_FLAG,
            CSA.ATTRIBUTE_CATEGORY SITE_ATTRIBUTE_CATEGORY,
            CSA.ATTRIBUTE1 GPO_ENTITY,
            CSA.ATTRIBUTE2 GLN_NUMBER,
            CSA.ATTRIBUTE10 CERTIFICATE_COMPLIANCE,
            CSA.ATTRIBUTE3 NATIONALITY,
            CSA.ATTRIBUTE4 B2B_TRANSLATION,
            CSA.ATTRIBUTE5 B2B_EDI_LOCATION,
            CSA.ATTRIBUTE7 EDI_DOCUMENT_TYPE,
            CSA.ATTRIBUTE8 EDI_FLAG,
            L.ADDRESS1,
            L.ADDRESS2,
            L.ADDRESS3,
            L.ADDRESS4,
            L.CITY,
            L.POSTAL_CODE,
            L.STATE,
            L.COUNTY,
            L.COUNTRY,
            CP.OVERALL_CREDIT_LIMIT,
            CP.CURRENCY_CODE,
            CP.PAYMENT_TERMS,
            CP.PROFILE_CLASS_NAME,
            RA.RELATED_CUST_ACCOUNT_ID,
            RA.ACCOUNT_NUMBER RELATED_ACCOUNT_NUMBER,
            RA.RELATIONSHIP_TYPE,
            RA.BILL_TO_FLAG RELATE_BILL_TO_FLAG,
            RA.SHIP_TO_FLAG RELATE_SHIP_TO_FLAG,
            RA.COMMENTS RELATIONSHIP_COMMENTS,
            HCAR.CUSTOMER_RECIPROCAL_FLAG RELATE_RECIPROCAL_FLAG,
            CA.ACCOUNT_NUMBER RELATED_ACC_NUM_ATTRIB_CAT,
            (SELECT HRL.LOCATION_CODE
               --INV_ORG.NAME
               FROM PO_LOCATION_ASSOCIATIONS_ALL PLA,
                    HR_LOCATIONS HRL,
                    --HZ_CUST_SITE_USES_ALL SU,
                    --HZ_CUST_ACCT_SITES_ALL HCS,
                    --HZ_CUST_ACCOUNTS HCA,
                    --HZ_PARTY_SITES HPS,
                    --HZ_PARTIES HP,
                    HR_ORGANIZATION_UNITS INV_ORG
              WHERE     PLA.ORGANIZATION_ID = INV_ORG.ORGANIZATION_ID(+)
                    AND PLA.LOCATION_ID = HRL.LOCATION_ID(+)
                    AND CSUA.SITE_USE_ID = PLA.SITE_USE_ID(+)
                    AND CSA.CUST_ACCT_SITE_ID = CSUA.CUST_ACCT_SITE_ID
                    AND CA.CUST_ACCOUNT_ID = CSA.CUST_ACCOUNT_ID
                    AND PS.PARTY_SITE_ID = CSA.PARTY_SITE_ID
                    AND P.PARTY_ID = PS.PARTY_ID
                    AND P.PARTY_ID = CA.PARTY_ID
                    AND CSUA.SITE_USE_CODE = 'SHIP_TO')
               INTERNAL_LOCATION,
            (SELECT INV_ORG.NAME
               FROM PO_LOCATION_ASSOCIATIONS_ALL PLA,
                    HR_LOCATIONS HRL,
                    --HZ_CUST_SITE_USES_ALL SU,
                    --HZ_CUST_ACCT_SITES_ALL HCS,
                    --HZ_CUST_ACCOUNTS HCA,
                    --HZ_PARTY_SITES HPS,
                    --HZ_PARTIES HP,
                    HR_ORGANIZATION_UNITS INV_ORG
              WHERE     PLA.ORGANIZATION_ID = INV_ORG.ORGANIZATION_ID(+)
                    AND PLA.LOCATION_ID = HRL.LOCATION_ID(+)
                    AND CSUA.SITE_USE_ID = PLA.SITE_USE_ID(+)
                    AND CSA.CUST_ACCT_SITE_ID = CSUA.CUST_ACCT_SITE_ID
                    AND CA.CUST_ACCOUNT_ID = CSA.CUST_ACCOUNT_ID
                    AND PS.PARTY_SITE_ID = CSA.PARTY_SITE_ID
                    AND P.PARTY_ID = PS.PARTY_ID
                    AND P.PARTY_ID = CA.PARTY_ID
                    AND CSUA.SITE_USE_CODE = 'SHIP_TO')
               INTERNAL_ORGANIZATION
       FROM AR.HZ_CUST_ACCOUNTS CA
            INNER JOIN AR.HZ_PARTIES P ON CA.PARTY_ID = P.PARTY_ID
            INNER JOIN AR.HZ_PARTY_SITES PS ON P.PARTY_ID = PS.PARTY_ID
            INNER JOIN AR.HZ_CUST_ACCT_SITES_ALL CSA
               ON PS.PARTY_SITE_ID = CSA.PARTY_SITE_ID
            INNER JOIN AR.HZ_CUST_SITE_USES_ALL CSUA
               ON CSA.CUST_ACCT_SITE_ID = CSUA.CUST_ACCT_SITE_ID
            INNER JOIN AR.HZ_LOCATIONS L ON PS.LOCATION_ID = L.LOCATION_ID
            LEFT OUTER JOIN
            (SELECT CA2.ACCOUNT_NUMBER,
                    RA2.RELATED_CUST_ACCOUNT_ID,
                    RA2.RELATIONSHIP_TYPE,
                    RA2.BILL_TO_FLAG,
                    RA2.SHIP_TO_FLAG,
                    RA2.COMMENTS,
                    RA2.CUST_ACCOUNT_ID
               FROM AR.HZ_CUST_ACCOUNTS CA2, AR.HZ_CUST_ACCT_RELATE_ALL RA2
              WHERE CA2.CUST_ACCOUNT_ID = RA2.RELATED_CUST_ACCOUNT_ID) RA
               ON CA.CUST_ACCOUNT_ID = RA.CUST_ACCOUNT_ID
            LEFT OUTER JOIN
            (SELECT CPRO.PARTY_ID,
                    CPRO.CUST_ACCOUNT_ID,
                    CPRO.SEND_STATEMENTS,
                    CPC.NAME PROFILE_CLASS_NAME,
                    CPRO.STATEMENT_CYCLE_ID,
                    SC.NAME STATEMENT_CYCLE_NAME,
                    CPA.OVERALL_CREDIT_LIMIT,
                    CPRO.CREDIT_HOLD,
                    CPA.CURRENCY_CODE,
                    CPRO.CREDIT_CHECKING,
                    COL.NAME AS COLLECTOR_NAME,
                    TERMS.NAME AS PAYMENT_TERMS
               FROM AR.HZ_CUSTOMER_PROFILES CPRO
                    INNER JOIN AR.RA_TERMS_TL TERMS
                       ON     CPRO.STANDARD_TERMS = TERMS.TERM_ID
                          AND TERMS.LANGUAGE = 'US'
                    INNER JOIN AR.HZ_CUST_PROFILE_CLASSES CPC
                       ON CPRO.PROFILE_CLASS_ID = CPC.PROFILE_CLASS_ID
                    LEFT OUTER JOIN AR.AR_STATEMENT_CYCLES SC
                       ON CPRO.STATEMENT_CYCLE_ID = SC.STATEMENT_CYCLE_ID
                    LEFT OUTER JOIN AR.AR_COLLECTORS COL
                       ON CPRO.COLLECTOR_ID = COL.COLLECTOR_ID
                    LEFT OUTER JOIN AR.HZ_CUST_PROFILE_AMTS CPA
                       ON CPRO.CUST_ACCOUNT_PROFILE_ID =
                             CPA.CUST_ACCOUNT_PROFILE_ID
              WHERE CPRO.SITE_USE_ID IS NULL) CP
               ON CA.CUST_ACCOUNT_ID = CP.CUST_ACCOUNT_ID
            LEFT OUTER JOIN AR.HZ_CUST_ACCT_RELATE_ALL HCAR
               ON HCAR.CUST_ACCOUNT_ID = CA.CUST_ACCOUNT_ID
   ORDER BY CA.ACCOUNT_NUMBER;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_CUST_MAST_DUMP FOR APPS.XX_BI_M2C_CUST_MAST_DUMP;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_CUST_MAST_DUMP FOR APPS.XX_BI_M2C_CUST_MAST_DUMP;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_CUST_MAST_DUMP FOR APPS.XX_BI_M2C_CUST_MAST_DUMP;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_CUST_MAST_DUMP FOR APPS.XX_BI_M2C_CUST_MAST_DUMP;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CUST_MAST_DUMP TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CUST_MAST_DUMP TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_CUST_MAST_DUMP TO XXINTG;
