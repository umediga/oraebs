DROP VIEW APPS.XX_BI_M2C_OIC_V;

/* Formatted on 6/6/2016 4:59:29 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XX_BI_M2C_OIC_V
(
   "PROCESSED MM-YY",
   "PROCESSED PERIOD",
   "A4-DIVISION",
   "A5-SUB DIVISION",
   "CREDIT TYPE",
   SALESREP_DEALER_NAME,
   "GROUP NAME",
   "ROLE NAME",
   "PLAN ELEMENT NAME",
   "A20-CUSTOMER NAME",
   "A21-ACCOUNT NUMBER",
   "SHIP TO CUSTOMER NAME",
   "A22-SHIP TO ADDRESS1",
   "A23-SHIP TO ADDRESS2",
   "A26-CITY",
   "A27-POSTAL CODE",
   "A29-STATE",
   "A30-PROVINCE",
   "A31-COUNTRY",
   "A32-PARTY SITE NUMBER",
   "A38-SURGEON NAME",
   "A39-SURGERY DATE",
   "A40-PATIENT ID",
   "ORDER NBR",
   "INVOICE NBR",
   "INVOICE LINE NUMBER",
   "INVOICE DATE",
   "BOOKED DATE",
   "PROCESSED DATE",
   "A45-PO NBR",
   "REVENUE CLASS",
   "A1-ITEM NAME",
   "A2-ITEM DESCRIPTION",
   QUANTITY,
   "A6-DCODE",
   "TRANSACTION AMOUNT",
   "COMMISSION RATE",
   "COMMISSION AMOUNT",
   "TRX TYPE",
   "HEADER STATUS",
   "LINE STATUS",
   "CREATION DATE",
   "A60-TERRITORY NAME",
   "A61-TERRITORY START DATE",
   "A62-TERRITORY END DATE",
   "COMMISSION HEADER_ID",
   "ORDER SOURCE",
   "A42-Sales Order Line Number",
   "A65-DIRECT"
)
AS
   SELECT TO_CHAR (CCH.PROCESSED_DATE, 'MM/YYYY') "PROCESSED MM-YY",
          CCH.PROCESSED_PERIOD_ID "PROCESSED PERIOD",
          SUBSTR (CCH.ATTRIBUTE4, 1, 30) "A4-DIVISION",
          SUBSTR (CCH.ATTRIBUTE5, 1, 30) "A5-SUB DIVISION",
          DECODE (CCL.DIRECT_SALESREP_ID,
                  CCL.CREDITED_SALESREP_ID, 'DIRECT',
                  'INDIRECT')
             "CREDIT TYPE",
          DECODE (CS.NAME,
                  NULL, SUBSTR (T.RESOURCE_NAME, 1, 40),
                  SUBSTR (CS.NAME, 1, 40))
             "SALESREP_DEALER_NAME",
          GTL.GROUP_NAME "GROUP NAME",
          RRT.ROLE_NAME "ROLE NAME",
          CQ.NAME "PLAN ELEMENT NAME",
          SUBSTR (CCH.ATTRIBUTE20, 1, 40) "A20-CUSTOMER NAME",
          SUBSTR (CCH.ATTRIBUTE21, 1, 10) "A21-ACCOUNT NUMBER",
          HP.PARTY_NAME "SHIP TO CUSTOMER NAME",
          SUBSTR (CCH.ATTRIBUTE22, 1, 40) "A22-SHIP TO ADDRESS1",
          SUBSTR (CCH.ATTRIBUTE23, 1, 40) "A23-SHIP TO ADDRESS2",
          SUBSTR (CCH.ATTRIBUTE26, 1, 40) "A26-CITY",
          SUBSTR (CCH.ATTRIBUTE27, 1, 10) "A27-POSTAL CODE",
          SUBSTR (CCH.ATTRIBUTE29, 1, 10) "A29-STATE",
          SUBSTR (CCH.ATTRIBUTE30, 1, 10) "A30-PROVINCE",
          SUBSTR (CCH.ATTRIBUTE31, 1, 20) "A31-COUNTRY",
          SUBSTR (CCH.ATTRIBUTE32, 1, 10) "A32-PARTY SITE NUMBER",
          SUBSTR (CCH.ATTRIBUTE38, 1, 20) "A38-SURGEON NAME",
          SUBSTR (CCH.ATTRIBUTE39, 1, 20) "A39-SURGERY DATE",
          SUBSTR (CCH.ATTRIBUTE40, 1, 20) "A40-PATIENT ID",
          CCH.ORDER_NUMBER "ORDER NBR",
          CCH.INVOICE_NUMBER "INVOICE NBR",
          CCH.LINE_NUMBER "INVOICE LINE NUMBER",
          CCH.INVOICE_DATE "INVOICE DATE",
          CCH.BOOKED_DATE "BOOKED DATE",
          CCH.PROCESSED_DATE "PROCESSED DATE",
          SUBSTR (CCH.ATTRIBUTE45, 1, 10) "A45-PO NBR",
          RC.NAME "REVENUE CLASS",
          SUBSTR (CCH.ATTRIBUTE1, 1, 30) "A1-ITEM NAME",
          SUBSTR (CCH.ATTRIBUTE2, 1, 30) "A2-ITEM DESCRIPTION",
          CCH.QUANTITY "QUANTITY",
          SUBSTR (CCH.ATTRIBUTE6, 1, 10) "A6-DCODE",
          --SUBSTR(CCH.ATTRIBUTE95,1,10) "SKU_DESCR",
          CCH.TRANSACTION_AMOUNT,                      --"TRANSACTION AMOUNT",
          CCL.COMMISSION_RATE * 100 "COMMISSION RATE",
          CCL.COMMISSION_AMOUNT "COMMISSION AMOUNT",
          CCL.TRX_TYPE "TRX TYPE",
          CCH.STATUS "HEADER STATUS",
          CCL.STATUS "LINE STATUS",
          CCL.CREATION_DATE "CREATION DATE",
          SUBSTR (CCH.ATTRIBUTE60, 1, 30) "A60-TERRITORY NAME",
          SUBSTR (CCH.ATTRIBUTE61, 1, 30) "A61-TERRITORY START DATE",
          SUBSTR (CCH.ATTRIBUTE62, 1, 30) "A62-TERRITORY END DATE",
          CCH.COMMISSION_HEADER_ID "COMMISSION HEADER_ID",
          OS.NAME "ORDER SOURCE",
          SUBSTR (cch.attribute42, 1, 20) "A42-Sales Order Line Number",
          SUBSTR (cch.attribute65, 1, 30) "A65-DIRECT"
     FROM APPS.CN_COMMISSION_LINES_ALL CCL,
          APPS.CN_COMMISSION_HEADERS_ALL CCH,
          APPS.JTF_RS_SALESREPS CS,
          APPS.JTF_RS_SALESREPS DS,
          APPS.JTF_RS_RESOURCE_EXTNS B,
          APPS.JTF_RS_RESOURCE_EXTNS_TL T,
          APPS.JTF_OBJECTS_TL JOT,
          APPS.JTF_OBJECTS_B JOBS,
          --APPS.FND_APPLICATION_VL FAPPS,
          APPS.FND_APPLICATION_TL FAT,
          APPS.FND_APPLICATION FA,
          APPS.CN_QUOTAS_ALL CQ,
          APPS.CN_REVENUE_CLASSES_ALL RC,
          APPS.JTF_RS_GROUPS_TL GTL,
          APPS.JTF_RS_ROLES_TL RRT,
          APPS.OE_ORDER_HEADERS_ALL OH,
          APPS.OE_ORDER_SOURCES OS,
          APPS.HZ_CUST_SITE_USES_ALL HCSU,
          APPS.HZ_CUST_ACCT_SITES_ALL HCAS,
          APPS.HZ_CUST_ACCOUNTS HCA,
          APPS.HZ_PARTIES HP
    WHERE     T.LANGUAGE = USERENV ('LANG')
          AND B.RESOURCE_ID = T.RESOURCE_ID
          AND B.CATEGORY = T.CATEGORY
          AND B.RESOURCE_ID(+) = DS.RESOURCE_ID
          AND JOBS.OBJECT_CODE = JOT.OBJECT_CODE
          AND JOT.LANGUAGE = USERENV ('LANG')
          AND FA.APPLICATION_ID(+) = JOBS.APPLICATION_ID
          AND FA.APPLICATION_ID = FAT.APPLICATION_ID
          AND FAT.LANGUAGE = USERENV ('LANG')
          AND B.CATEGORY = JOBS.OBJECT_CODE
          --AND CCH.ATTRIBUTE4 = 'INSTR'
          --AND CCH.ATTRIBUTE5 NOT IN ('ALSIS', 'ALSID')
          AND CCL.COMMISSION_HEADER_ID(+) = CCH.COMMISSION_HEADER_ID
          AND CCL.STATUS NOT IN ('OBSOLETE')
          AND CS.SALESREP_ID = CCL.CREDITED_SALESREP_ID
          AND DS.SALESREP_ID = CCH.DIRECT_SALESREP_ID
          AND CQ.QUOTA_ID(+) = CCL.QUOTA_ID
          AND CQ.QUOTA_GROUP_CODE(+) = 'QUOTA'
          AND RC.REVENUE_CLASS_ID = CCL.REVENUE_CLASS_ID
          AND GTL.GROUP_ID(+) = CCL.CREDITED_COMP_GROUP_ID
          AND GTL.GROUP_NAME LIKE 'US_OIC%'
          AND GTL.LANGUAGE(+) = 'US'
          AND RRT.ROLE_ID(+) = CCL.ROLE_ID
          AND RRT.LANGUAGE(+) = 'US'
          AND OH.ORDER_NUMBER(+) = CCH.ORDER_NUMBER
          AND OS.ORDER_SOURCE_ID(+) = OH.ORDER_SOURCE_ID
          AND HCSU.SITE_USE_ID(+) = OH.SHIP_TO_ORG_ID
          AND HCAS.CUST_ACCT_SITE_ID(+) = HCSU.CUST_ACCT_SITE_ID
          AND HCA.CUST_ACCOUNT_ID(+) = HCAS.CUST_ACCOUNT_ID
          AND HP.PARTY_ID(+) = HCA.PARTY_ID
   UNION ALL
   SELECT TO_CHAR (CCH.PROCESSED_DATE, 'MM/YYYY') "PROCESSED MM-YY",
          CCH.PROCESSED_PERIOD_ID "PROCESSED PERIOD",
          SUBSTR (CCH.ATTRIBUTE4, 1, 30) "A4-DIVISION",
          SUBSTR (CCH.ATTRIBUTE5, 1, 30) "A5-SUB DIVISION",
          'XROL' "CREDIT TYPE",
          DECODE (DS.NAME,
                  NULL, SUBSTR (T.RESOURCE_NAME, 1, 40),
                  SUBSTR (DS.NAME, 1, 40))
             "SALESREP_DEALER_NAME",
          GTL.GROUP_NAME "GROUP NAME",
          RRT.ROLE_NAME "ROLE NAME",
          CQ.NAME "PLAN ELEMENT NAME",
          SUBSTR (CCH.ATTRIBUTE20, 1, 40) "A20-CUSTOMER NAME",
          SUBSTR (CCH.ATTRIBUTE21, 1, 10) "A21-ACCOUNT NUMBER",
          HP.PARTY_NAME "SHIP TO CUSTOMER NAME",
          SUBSTR (CCH.ATTRIBUTE22, 1, 40) "A22-SHIP TO ADDRESS1",
          SUBSTR (CCH.ATTRIBUTE23, 1, 40) "A23-SHIP TO ADDRESS2",
          SUBSTR (CCH.ATTRIBUTE26, 1, 40) "A26-CITY",
          SUBSTR (CCH.ATTRIBUTE27, 1, 10) "A27-POSTAL CODE",
          SUBSTR (CCH.ATTRIBUTE29, 1, 10) "A29-STATE",
          SUBSTR (CCH.ATTRIBUTE30, 1, 10) "A30-PROVINCE",
          SUBSTR (CCH.ATTRIBUTE31, 1, 20) "A31-COUNTRY",
          SUBSTR (CCH.ATTRIBUTE32, 1, 10) "A32-PARTY SITE NUMBER",
          SUBSTR (CCH.ATTRIBUTE38, 1, 20) "A38-SURGEON NAME",
          SUBSTR (CCH.ATTRIBUTE39, 1, 20) "A39-SURGERY DATE",
          SUBSTR (CCH.ATTRIBUTE40, 1, 20) "A40-PATIENT ID",
          CCH.ORDER_NUMBER "ORDER NBR",
          CCH.INVOICE_NUMBER "INVOICE NBR",
          CCH.LINE_NUMBER "INVOICE LINE NUMBER",
          CCH.INVOICE_DATE "INVOICE DATE",
          CCH.BOOKED_DATE "BOOKED DATE",
          CCH.PROCESSED_DATE "PROCESSED DATE",
          SUBSTR (CCH.ATTRIBUTE45, 1, 10) "A45-PO NBR",
          '' "REVENUE CLASS",
          SUBSTR (CCH.ATTRIBUTE1, 1, 30) "A1-ITEM NAME",
          SUBSTR (CCH.ATTRIBUTE2, 1, 30) "A2-ITEM DESCRIPTION",
          CCH.QUANTITY "QUANTITY",
          SUBSTR (CCH.ATTRIBUTE6, 1, 10) "A6-DCODE",
          --SUBSTR(CCH.ATTRIBUTE95,1,10) "SKU_DESCR",
          CCH.TRANSACTION_AMOUNT,                      --"TRANSACTION AMOUNT",
          0 "COMMISSION RATE",
          0 "COMMISSION AMOUNT",
          '' "TRX TYPE",
          CCH.STATUS "HEADER STATUS",
          '' "LINE STATUS",
          NULL "CREATION DATE",
          SUBSTR (CCH.ATTRIBUTE60, 1, 30) "A60-TERRITORY NAME",
          SUBSTR (CCH.ATTRIBUTE61, 1, 30) "A61-TERRITORY START DATE",
          SUBSTR (CCH.ATTRIBUTE62, 1, 30) "A62-TERRITORY END DATE",
          CCH.COMMISSION_HEADER_ID "COMMISSION HEADER_ID",
          OS.NAME "ORDER SOURCE",
          SUBSTR (cch.attribute42, 1, 20) "A42-Sales Order Line Number",
          SUBSTR (cch.attribute65, 1, 30) "A65-DIRECT"
     FROM APPS.CN_COMMISSION_LINES_ALL CCL,
          APPS.CN_COMMISSION_HEADERS_ALL CCH,
          APPS.JTF_RS_SALESREPS CS,
          APPS.JTF_RS_SALESREPS DS,
          APPS.JTF_RS_RESOURCE_EXTNS B,
          APPS.JTF_RS_RESOURCE_EXTNS_TL T,
          APPS.JTF_OBJECTS_TL JOT,
          APPS.JTF_OBJECTS_B JOBS,
          --APPS.FND_APPLICATION_VL FAPPS,
          APPS.FND_APPLICATION_TL FAT,
          APPS.FND_APPLICATION FA,
          APPS.CN_QUOTAS_ALL CQ,
          APPS.CN_REVENUE_CLASSES_ALL RC,
          APPS.JTF_RS_GROUPS_TL GTL,
          APPS.JTF_RS_ROLES_TL RRT,
          APPS.OE_ORDER_HEADERS_ALL OH,
          APPS.OE_ORDER_SOURCES OS,
          APPS.HZ_CUST_SITE_USES_ALL HCSU,
          APPS.HZ_CUST_ACCT_SITES_ALL HCAS,
          APPS.HZ_CUST_ACCOUNTS HCA,
          APPS.HZ_PARTIES HP
    WHERE     T.LANGUAGE = USERENV ('LANG')
          AND B.RESOURCE_ID = T.RESOURCE_ID
          AND B.CATEGORY = T.CATEGORY
          AND B.RESOURCE_ID(+) = DS.RESOURCE_ID
          AND JOBS.OBJECT_CODE = JOT.OBJECT_CODE
          AND JOT.LANGUAGE = USERENV ('LANG')
          AND FA.APPLICATION_ID(+) = JOBS.APPLICATION_ID
          AND FA.APPLICATION_ID = FAT.APPLICATION_ID
          AND FAT.LANGUAGE = USERENV ('LANG')
          AND B.CATEGORY = JOBS.OBJECT_CODE
          --AND CCH.ATTRIBUTE4 = 'INSTR'
          --AND CCH.ATTRIBUTE5 NOT IN ('ALSIS', 'ALSID')
          AND CCL.COMMISSION_HEADER_ID(+) = CCH.COMMISSION_HEADER_ID
          AND CCH.STATUS NOT IN ('OBSOLETE')
          AND CCH.STATUS NOT IN ('ROLL')
          AND CS.SALESREP_ID(+) = CCL.CREDITED_SALESREP_ID
          AND DS.SALESREP_ID = CCH.DIRECT_SALESREP_ID
          --AND DS.SALESREP_NUMBER NOT IN ('-3', '-9999')
          AND CQ.QUOTA_ID(+) = CCL.QUOTA_ID
          AND CQ.QUOTA_GROUP_CODE(+) = 'QUOTA'
          AND RC.REVENUE_CLASS_ID(+) = CCH.REVENUE_CLASS_ID
          AND GTL.GROUP_ID(+) = CCL.CREDITED_COMP_GROUP_ID
          AND GTL.LANGUAGE(+) = 'US'
          AND RRT.ROLE_ID(+) = CCL.ROLE_ID
          AND RRT.LANGUAGE(+) = 'US'
          AND OH.ORDER_NUMBER(+) = CCH.ORDER_NUMBER
          AND OS.ORDER_SOURCE_ID(+) = OH.ORDER_SOURCE_ID
          AND HCSU.SITE_USE_ID(+) = OH.SHIP_TO_ORG_ID
          AND HCAS.CUST_ACCT_SITE_ID(+) = HCSU.CUST_ACCT_SITE_ID
          AND HCA.CUST_ACCOUNT_ID(+) = HCAS.CUST_ACCOUNT_ID
          AND HP.PARTY_ID(+) = HCA.PARTY_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XX_BI_M2C_OIC_V FOR APPS.XX_BI_M2C_OIC_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XX_BI_M2C_OIC_V FOR APPS.XX_BI_M2C_OIC_V;


CREATE OR REPLACE SYNONYM XXBI.XX_BI_M2C_OIC_V FOR APPS.XX_BI_M2C_OIC_V;


CREATE OR REPLACE SYNONYM XXINTG.XX_BI_M2C_OIC_V FOR APPS.XX_BI_M2C_OIC_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_OIC_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_OIC_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XX_BI_M2C_OIC_V TO XXINTG;