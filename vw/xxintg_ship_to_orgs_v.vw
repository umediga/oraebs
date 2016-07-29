DROP VIEW APPS.XXINTG_SHIP_TO_ORGS_V;

/* Formatted on 6/6/2016 5:00:12 PM (QP5 v5.277) */
CREATE OR REPLACE FORCE VIEW APPS.XXINTG_SHIP_TO_ORGS_V
(
   ORGANIZATION_ID,
   BUSINESS_GROUP_ID,
   COST_ALLOCATION_KEYFLEX_ID,
   LOCATION_ID,
   SOFT_CODING_KEYFLEX_ID,
   START_DATE_ACTIVE,
   NAME,
   COMMENTS,
   END_DATE_ACTIVE,
   INTERNAL_EXTERNAL_FLAG,
   INTERNAL_ADDRESS_LINE,
   TYPE,
   REQUEST_ID,
   PROGRAM_APPLICATION_ID,
   PROGRAM_ID,
   PROGRAM_UPDATE_DATE,
   ATTRIBUTE_CATEGORY,
   ATTRIBUTE1,
   ATTRIBUTE2,
   ATTRIBUTE3,
   ATTRIBUTE4,
   ATTRIBUTE5,
   ATTRIBUTE6,
   ATTRIBUTE7,
   ATTRIBUTE8,
   ATTRIBUTE9,
   ATTRIBUTE10,
   ATTRIBUTE11,
   ATTRIBUTE12,
   ATTRIBUTE13,
   ATTRIBUTE14,
   ATTRIBUTE15,
   ATTRIBUTE16,
   ATTRIBUTE17,
   ATTRIBUTE18,
   ATTRIBUTE19,
   ATTRIBUTE20,
   LAST_UPDATE_DATE,
   LAST_UPDATED_BY,
   LAST_UPDATE_LOGIN,
   CREATED_BY,
   CREATION_DATE,
   SITE_USE_ID,
   STATUS,
   CUST_ACCT_SITE_ID,
   BILL_TO_SITE_USE_ID,
   PRICE_LIST_ID,
   PAYMENT_TERM_ID,
   FOB_POINT_CODE,
   FREIGHT_TERMS_CODE,
   SHIP_PARTIAL_ALLOWED,
   SHIPPING_METHOD_CODE,
   DEMAND_CLASS_CODE,
   PRIMARY_SALESREP_ID,
   CONTACT_ID,
   SOLD_FROM_ORG_ID,
   SHIP_FROM_ORG_ID,
   PRIMARY_FLAG,
   LOCATION_CODE,
   CUST_ACCOUNT_ID,
   ADDRESS_LINE_1,
   ADDRESS_LINE_2,
   ADDRESS_LINE_3,
   ADDRESS_LINE_4,
   REGION_1,
   REGION_2,
   REGION_3,
   TOWN_OR_CITY,
   STATE,
   POSTAL_CODE,
   COUNTRY,
   OVER_SHIPMENT_TOLERANCE,
   UNDER_SHIPMENT_TOLERANCE,
   DATES_NEGATIVE_TOLERANCE,
   DATES_POSITIVE_TOLERANCE,
   DATE_TYPE_PREFERENCE,
   OVER_RETURN_TOLERANCE,
   UNDER_RETURN_TOLERANCE,
   ITEM_CROSS_REF_PREF,
   ORDER_TYPE_ID,
   ADDRESS_STATUS,
   ORG_ID
)
AS
   SELECT SITE.SITE_USE_ID ORGANIZATION_ID,
          NULL BUSINESS_GROUP_ID,
          NULL COST_ALLOCATION_KEYFLEX_ID,
          SITE.SITE_USE_ID LOCATION_ID,
          NULL SOFT_CODING_KEYFLEX_ID,
          NULL START_DATE_ACTIVE,
          SITE.LOCATION "NAME",
          NULL COMMENTS,
          NULL END_DATE_ACTIVE,
          NULL INTERNAL_EXTERNAL_FLAG,
          NULL INTERNAL_ADDRESS_LINE,
          NULL "TYPE",
          NULL REQUEST_ID,
          NULL PROGRAM_APPLICATION_ID,
          NULL PROGRAM_ID,
          NULL PROGRAM_UPDATE_DATE,
          NULL ATTRIBUTE_CATEGORY,
          NULL ATTRIBUTE1,
          NULL ATTRIBUTE2,
          NULL ATTRIBUTE3,
          NULL ATTRIBUTE4,
          NULL ATTRIBUTE5,
          NULL ATTRIBUTE6,
          NULL ATTRIBUTE7,
          NULL ATTRIBUTE8,
          NULL ATTRIBUTE9,
          NULL ATTRIBUTE10,
          NULL ATTRIBUTE11,
          NULL ATTRIBUTE12,
          NULL ATTRIBUTE13,
          NULL ATTRIBUTE14,
          NULL ATTRIBUTE15,
          NULL ATTRIBUTE16,
          NULL ATTRIBUTE17,
          NULL ATTRIBUTE18,
          NULL ATTRIBUTE19,
          NULL ATTRIBUTE20,
          NULL LAST_UPDATE_DATE,
          NULL LAST_UPDATED_BY,
          NULL LAST_UPDATE_LOGIN,
          NULL CREATED_BY,
          NULL CREATION_DATE,
          SITE.SITE_USE_ID,
          SITE.STATUS,
          SITE.CUST_ACCT_SITE_ID,
          SITE.BILL_TO_SITE_USE_ID,
          SITE.PRICE_LIST_ID,
          SITE.PAYMENT_TERM_ID,
          SITE.FOB_POINT FOB_POINT_CODE,
          SITE.FREIGHT_TERM FREIGHT_TERMS_CODE,
          SITE.SHIP_PARTIAL SHIP_PARTIAL_ALLOWED,
          SITE.SHIP_VIA SHIPPING_METHOD_CODE,
          SITE.DEMAND_CLASS_CODE,
          SITE.PRIMARY_SALESREP_ID,
          SITE.CONTACT_ID,
          SITE.WAREHOUSE_ID SOLD_FROM_ORG_ID,
          SITE.WAREHOUSE_ID SHIP_FROM_ORG_ID,
          SITE.PRIMARY_FLAG,
          SITE.LOCATION LOCATION_CODE,
          ACCT_SITE.CUST_ACCOUNT_ID,
          LOC.ADDRESS1 ADDRESS_LINE_1,
          LOC.ADDRESS2 ADDRESS_LINE_2,
          LOC.ADDRESS3 ADDRESS_LINE_3,
          LOC.ADDRESS4 ADDRESS_LINE_4,
          NULL REGION_1,
          NULL REGION_2,
          NULL REGION_3,
          LOC.CITY town_or_city,
          NVL (LOC.STATE, LOC.PROVINCE) STATE,
          LOC.postal_code,
          LOC.country,
          SITE.OVER_SHIPMENT_TOLERANCE,
          SITE.UNDER_SHIPMENT_TOLERANCE,
          SITE.DATES_NEGATIVE_TOLERANCE,
          SITE.DATES_POSITIVE_TOLERANCE,
          SITE.DATE_TYPE_PREFERENCE,
          SITE.OVER_RETURN_TOLERANCE,
          SITE.UNDER_RETURN_TOLERANCE,
          SITE.ITEM_CROSS_REF_PREF,
          SITE.ORDER_TYPE_ID,
          ACCT_SITE.STATUS ADDRESS_STATUS,
          ACCT_SITE.ORG_ID AS ORG_ID
     FROM HZ_CUST_SITE_USES_ALL SITE,
          HZ_PARTY_SITES PARTY_SITE,
          HZ_LOCATIONS LOC,
          HZ_CUST_ACCT_SITES_ALL ACCT_SITE
    WHERE     SITE.SITE_USE_CODE = 'SHIP_TO'
          AND SITE.CUST_ACCT_SITE_ID = ACCT_SITE.CUST_ACCT_SITE_ID
          AND ACCT_SITE.PARTY_SITE_ID = PARTY_SITE.PARTY_SITE_ID
          AND PARTY_SITE.LOCATION_ID = LOC.LOCATION_ID
          AND SITE.ORG_ID = ACCT_SITE.ORG_ID;


CREATE OR REPLACE SYNONYM ETLEBSUSER.XXINTG_SHIP_TO_ORGS_V FOR APPS.XXINTG_SHIP_TO_ORGS_V;


CREATE OR REPLACE SYNONYM XXAPPSREAD.XXINTG_SHIP_TO_ORGS_V FOR APPS.XXINTG_SHIP_TO_ORGS_V;


CREATE OR REPLACE SYNONYM XXBI.XXINTG_SHIP_TO_ORGS_V FOR APPS.XXINTG_SHIP_TO_ORGS_V;


CREATE OR REPLACE SYNONYM XXINTG.XXINTG_SHIP_TO_ORGS_V FOR APPS.XXINTG_SHIP_TO_ORGS_V;


GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_SHIP_TO_ORGS_V TO ETLEBSUSER;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_SHIP_TO_ORGS_V TO XXAPPSREAD;

GRANT DELETE, INSERT, REFERENCES, SELECT, UPDATE, ON COMMIT REFRESH, QUERY REWRITE, DEBUG, FLASHBACK, MERGE VIEW ON APPS.XXINTG_SHIP_TO_ORGS_V TO XXINTG;
