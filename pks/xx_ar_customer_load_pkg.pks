DROP PACKAGE APPS.XX_AR_CUSTOMER_LOAD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUSTOMER_LOAD_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 14-May-2013
File Name     : XXARCUSTLOAD.pks
Description   : This script creates the specification of the package X_AR_CUSTOMER_LOAD_PKG
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
14-May-2013  IBM Development Team   Initial Draft.
05-SEP-2014  Sharath Babu           Added new field account_estd_date as per Wave2
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';
   
   TYPE g_xx_ar_cust_rec_type
   IS
      RECORD (
      BATCH_ID                      VARCHAR2(100 BYTE),
      ORIG_SYSTEM_REF               VARCHAR2(240 BYTE),
      PERSON_FLAG                   VARCHAR2(10 BYTE),
      SOURCE_SYSTEM_NAME            VARCHAR2(240 BYTE),
      CUSTOMER_ID                   NUMBER,
      CUSTOMER_TYPE                 VARCHAR2(30 BYTE),
      PARTY_TYPE                    VARCHAR2(30 BYTE),    
      CUSTOMER_FIRST_NAME           VARCHAR2(150 BYTE),
      CUSTOMER_LAST_NAME            VARCHAR2(150 BYTE),
      CUSTOMER_TITLE                VARCHAR2(60 BYTE),
      CUSTOMER_STATUS               VARCHAR2(10 BYTE),
      DOB                           DATE,
      GENDER                        VARCHAR2(30 BYTE),
      NATIONALITY                   VARCHAR2(150 BYTE),
      CUSTOMER_NAME                 VARCHAR2(300 BYTE),
      ORGANIZATION_NAME             VARCHAR2(300 BYTE),
      LANGUAGE                      VARCHAR2(30 BYTE),
      CATEGORY_CODE                 VARCHAR2(30 BYTE),
      CUSTOMER_CLASS                VARCHAR2(30 BYTE),
      PAYMENT_TERM                  VARCHAR2(100 BYTE),
      PAYMENT_TERM_ID               NUMBER,
      ORG_ID                        NUMBER,
      CUST_ACCOUNT_ID               NUMBER,
      ACCOUNT_NUMBER                VARCHAR2(30 BYTE),
      PARTY_ID                      NUMBER,
      PARTY_NUMBER                  VARCHAR2(500 BYTE),
      PROFILE_CLASS                 VARCHAR2(500 BYTE),
      PROFILE_CLASS_ID              NUMBER,
      PROFILE                       VARCHAR2(500 BYTE),
      PROFILE_ID                    NUMBER,
      SEND_STATEMENTS               VARCHAR2(10 BYTE),
      STATEMENT_CYCLE_ID            NUMBER,
      STATEMENT_CYCLE_NAME          VARCHAR2(100 BYTE),
      ATTRIBUTE_CATEGORY            VARCHAR2(100 BYTE),
      ATTRIBUTE1                    VARCHAR2(100 BYTE),
      ATTRIBUTE2                    VARCHAR2(100 BYTE),
      ATTRIBUTE3                    VARCHAR2(100 BYTE),
      ATTRIBUTE4                    VARCHAR2(100 BYTE),
      ATTRIBUTE5                    VARCHAR2(100 BYTE),
      ATTRIBUTE6                    VARCHAR2(100 BYTE),
      ATTRIBUTE7                    VARCHAR2(100 BYTE),
      ATTRIBUTE8                    VARCHAR2(100 BYTE),
      ATTRIBUTE9                    VARCHAR2(100 BYTE),
      ATTRIBUTE10                   VARCHAR2(100 BYTE),
      OVERALL_CREDIT_LIMIT          NUMBER,
      CURRENCY_CODE                 VARCHAR2(10 BYTE),
      CREDIT_CHECKING               VARCHAR2(10 BYTE),
      COLLECTOR_ID                  NUMBER,
      COLLECTOR_NAME                VARCHAR2(100 BYTE),
      DISCOUNT_TERMS                VARCHAR2(100 BYTE),
      AUTO_REC_INCL_DISPUTED_FLAG   VARCHAR2(10  BYTE),
      GROUPING_RULE                 VARCHAR2(100 BYTE),
      GROUPING_RULE_ID              NUMBER,
      TOLERANCE                     VARCHAR2(100 BYTE),
      FILE_NAME                     VARCHAR2(150 BYTE),
      RECORD_NUMBER                 NUMBER,
      REQUEST_ID                    NUMBER,
      LAST_UPDATED_BY               NUMBER,
      LAST_UPDATE_DATE              DATE,
      PHASE_CODE                    VARCHAR2(100 BYTE),
      ERROR_CODE                    VARCHAR2(10 BYTE),
      ERROR_MSG                     VARCHAR2(500 BYTE),
      ACCOUNT_ESTD_DATE             DATE               --Added as per Wave2
    );   
      
   TYPE g_xx_ar_address_rec_type
   IS
      RECORD (   
      BATCH_ID                      VARCHAR2(100 BYTE),
      ORIG_SYSTEM_REF               VARCHAR2(240 BYTE),
      ORIG_SYS_ADDR_REF             VARCHAR2(240 BYTE),
      ORIG_SYS_SITE_USE_REF         VARCHAR2(240 BYTE),
      SOURCE_SYSTEM_NAME            VARCHAR2(240 BYTE),
      ADDRESS_ID                    NUMBER,
      PRIMARY_ADDRESS               VARCHAR2(30 BYTE),
      IDENTIFYING_FLAG              VARCHAR2(30 BYTE),
      SITE_USE_STATUS               VARCHAR2(30 BYTE),
      ADDRESS_TYPE                  VARCHAR2(150 BYTE),
      LOCATION                      VARCHAR2(240 BYTE),
      ADDRESS1                      VARCHAR2(240 BYTE),
      ADDRESS2                      VARCHAR2(240 BYTE),
      ADDRESS3                      VARCHAR2(240 BYTE),
      ADDRESS4                      VARCHAR2(240 BYTE),
      CITY                          VARCHAR2(60 BYTE),
      STATE                         VARCHAR2(60 BYTE),
      POSTAL_CODE                   VARCHAR2(60 BYTE),
      COUNTY                        VARCHAR2(60 BYTE),
      PROVINCE                      VARCHAR2(60 BYTE),
      COUNTRY                       VARCHAR2(60 BYTE),
      COUNTRY_CODE                  VARCHAR2(3 BYTE),
      ADDRESS_STYLE                 VARCHAR2(60 BYTE),
      SITE_USE_OPERATING_UNIT       VARCHAR2(60 BYTE),
      ORG_ID                        NUMBER,
      GLOBAL_LOCATION_NUMBER        VARCHAR2(150 BYTE),
      PARTY_SITE_ID                 NUMBER,
      PARTY_SITE_NUMBER             VARCHAR2(100 BYTE),
      PARTY_NUMBER                  VARCHAR2(500 BYTE),
      CUST_ACCT_SITE_ID             NUMBER,
      SITE_USE_ID                   NUMBER,
      ATTRIBUTE_CATEGORY            VARCHAR2(100 BYTE),
      ATTRIBUTE1                    VARCHAR2(100 BYTE),
      ATTRIBUTE2                    VARCHAR2(100 BYTE),
      ATTRIBUTE3                    VARCHAR2(150 BYTE),
      ATTRIBUTE4                    VARCHAR2(100 BYTE),
      ATTRIBUTE5                    VARCHAR2(100 BYTE),
      ATTRIBUTE6                    VARCHAR2(100 BYTE),
      ATTRIBUTE7                    VARCHAR2(100 BYTE),
      ATTRIBUTE8                    VARCHAR2(100 BYTE),
      ATTRIBUTE9                    VARCHAR2(100 BYTE),
      ATTRIBUTE10                   VARCHAR2(100 BYTE),
      ATTRIBUTE11                   VARCHAR2(100 BYTE),
      ORG_COMP_CODE                 VARCHAR2(100 BYTE),
      SITE_FREIGHT_TERMS            VARCHAR2(30 BYTE),
      SHIP_METHOD                   VARCHAR2(30 BYTE),
      FOB_CODE                      VARCHAR2(30 BYTE),
      SITE_USE_ATTRIBUTE_CATEGORY   VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE1           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE2           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE3           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE4           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE5           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE6           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE7           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE8           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE9           VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE10          VARCHAR2(100 BYTE),
      SITE_USE_ATTRIBUTE19          VARCHAR2(100 BYTE),
      FILE_NAME                     VARCHAR2(150 BYTE),
      RECORD_NUMBER                 NUMBER,
      REQUEST_ID                    NUMBER,
      LAST_UPDATED_BY               NUMBER,
      LAST_UPDATE_DATE              DATE,
      PHASE_CODE                    VARCHAR2(100 BYTE),
      ERROR_CODE                    VARCHAR2(10 BYTE),
      ERROR_MSG                     VARCHAR2(500 BYTE)
    );

   -- Customer Table Type 
   TYPE xx_otc_cust_hdr_cnv_tab_type IS TABLE OF xxconv.xx_ar_cust_stg%ROWTYPE
      INDEX BY BINARY_INTEGER;
   -- Address Table Type 
   TYPE xx_otc_cust_addr_cnv_tab_type IS TABLE OF xxconv.xx_ar_address_stg%ROWTYPE
      INDEX BY BINARY_INTEGER;

   g_miss_cust_hdr_cnv_tab        xx_otc_cust_hdr_cnv_tab_type;
   g_miss_cust_addr_cnv_tab       xx_otc_cust_addr_cnv_tab_type;

   g_miss_cust_hdr_cnv_rec        xxconv.xx_ar_cust_stg%ROWTYPE;
   g_miss_cust_addr_cnv_rec       xxconv.xx_ar_address_stg%ROWTYPE;

   g_miss_cust_account_rec        hz_cust_account_v2pub.cust_account_rec_type;
   g_miss_organization_rec        hz_party_v2pub.organization_rec_type;
   g_miss_customer_profile_rec    hz_customer_profile_v2pub.customer_profile_rec_type;
   g_miss_location_rec            hz_location_v2pub.location_rec_type;
   g_miss_party_site_rec          hz_party_site_v2pub.party_site_rec_type;
   g_miss_cust_acct_site_rec      hz_cust_account_site_v2pub.cust_acct_site_rec_type;
   g_miss_cust_site_use_rec       hz_cust_account_site_v2pub.cust_site_use_rec_type;
   g_miss_create_person_rec       hz_party_v2pub.person_rec_type;
   g_miss_org_contact_rec         hz_party_contact_v2pub.org_contact_rec_type;
   g_miss_cr_cust_acc_role_rec    hz_cust_account_role_v2pub.cust_account_role_rec_type;
   g_miss_contact_point_rec       hz_contact_point_v2pub.contact_point_rec_type;
   g_miss_segment_array           fnd_flex_ext.segmentarray;   
         
   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);
                   
                   
END xx_ar_customer_load_pkg;
/
