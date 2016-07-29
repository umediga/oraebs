DROP PACKAGE APPS.XX_AR_CUSTCONT_LOAD_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUSTCONT_LOAD_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 14-May-2013
File Name     : XXARCUSTCONTLOAD.pks
Description   : This script creates the specification of the package xx_ar_custcon_load_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
14-May-2013  IBM Development Team   Initial Draft.
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';

   TYPE g_xx_ar_cust_cont_rec_type
   IS
      RECORD (
      BATCH_ID              VARCHAR2(100 BYTE),
      ORIG_SYSTEM_REF       VARCHAR2(240 BYTE),
      ORIG_SYS_ADDR_REF     VARCHAR2(240 BYTE),
      ORIG_SYS_CONTACT_REF  VARCHAR2(240 BYTE),
      CONTACT_TYPE          VARCHAR2(50 BYTE),
      CONTACT_ID            NUMBER,
      PARTY_REL_ID          NUMBER,
      CUSTOMER_ID           NUMBER,
      JOB_TITLE             VARCHAR2(50 BYTE),
      DEPARTMENT_CODE       VARCHAR2(500 BYTE),
      PRE_NAME              VARCHAR2(10 BYTE),
      FIRST_NAME            VARCHAR2(500 BYTE),
      MIDDLE_NAME           VARCHAR2(500 BYTE),
      LAST_NAME             VARCHAR2(500 BYTE),
      ADDRESS_ID            NUMBER,
      ADDRESS1              VARCHAR2(240 BYTE),
      ADDRESS2              VARCHAR2(240 BYTE),
      ADDRESS3              VARCHAR2(240 BYTE),
      ADDRESS4              VARCHAR2(240 BYTE),
      CITY                  VARCHAR2(60 BYTE),
      STATE                 VARCHAR2(60 BYTE),
      POSTAL_CODE           VARCHAR2(60 BYTE),
      COUNTY                VARCHAR2(60 BYTE),
      PROVINCE              VARCHAR2(60 BYTE),
      COUNTRY               VARCHAR2(60 BYTE),
      COUNTRY_CODE          VARCHAR2(3 BYTE),
      MAIL_STOP             VARCHAR2(500 BYTE),
      PHONE_PURPOSE         VARCHAR2(100 BYTE),
      PHONE                 VARCHAR2(60 BYTE),
      PHONE_EXT             VARCHAR2(10 BYTE),
      PHONE_AREA_CODE       VARCHAR2(10 BYTE),
      PHONE_COUNTRY_CODE    VARCHAR2(10 BYTE),
      FAX_PURPOSE           VARCHAR2(100 BYTE),
      FAX                   VARCHAR2(20 BYTE),
      MOBILE                VARCHAR2(20 BYTE),
      EMAIL_PURPOSE         VARCHAR2(100 BYTE),
      EMAIL                 VARCHAR2(100 BYTE),
      USAGE_TYPE            VARCHAR2(100 BYTE),
      ORG_COMP_CODE         VARCHAR2(100 BYTE),
      PARTY_ID              NUMBER,
      PARTY_ID2             NUMBER,
      PARTY_SITE_ID         NUMBER,
      PARTY_SITE_NUMBER     NUMBER,
      CUST_ACCOUNT_ROLE_ID  NUMBER,
      RESPONSIBILITY_TYPE   VARCHAR2(100 BYTE),
      RESPONSIBILITY_ID     NUMBER,
      PARTY_NUMBER          VARCHAR2(2000 BYTE),
      PROFILE_ID            NUMBER,
      ATTRIBUTE_CATEGORY    VARCHAR2(100 BYTE),
      ATTRIBUTE1            VARCHAR2(100 BYTE),
      ATTRIBUTE2            VARCHAR2(100 BYTE),
      ATTRIBUTE3            VARCHAR2(100 BYTE),
      ATTRIBUTE4            VARCHAR2(100 BYTE),
      ATTRIBUTE5            VARCHAR2(100 BYTE),
      ATTRIBUTE6            VARCHAR2(100 BYTE),
      ATTRIBUTE7            VARCHAR2(100 BYTE),
      ATTRIBUTE8            VARCHAR2(100 BYTE),
      ATTRIBUTE9            VARCHAR2(100 BYTE),
      ATTRIBUTE10           VARCHAR2(100 BYTE),
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

   -- Cuontact Table Type
   TYPE xx_otc_cust_cont_cnv_tab_type IS TABLE OF xxconv.xx_ar_contact_stg%ROWTYPE
      INDEX BY BINARY_INTEGER;


   g_miss_cust_cont_cnv_tab       xx_otc_cust_cont_cnv_tab_type;

   g_miss_cust_cont_cnv_rec       xxconv.xx_ar_contact_stg%ROWTYPE;


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


END xx_ar_custcont_load_pkg;
/
