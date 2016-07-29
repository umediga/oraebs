DROP PACKAGE APPS.XX_AR_CUST_RELATE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUST_RELATE_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 14-May-2013
File Name     : XXARCUSTREL.pks
Description   : This script creates the specification of the package xx_ar_cust_relate_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
12-June-2013  ABHARGAVA            Initial Draft.
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';

   TYPE g_xx_ar_cust_rel_rec_type
   IS
   RECORD (
      BATCH_ID                      VARCHAR2(100 BYTE),
      SOURCE_SYSTEM_NAME            VARCHAR2(240 BYTE),
      API_TYPE                      VARCHAR2(100 BYTE),
      CUST_ACCT_RELATE_ID           NUMBER,
      ID_NUMBER                     VARCHAR2(100 BYTE),
      CUST_ACCOUNT_ID               NUMBER,
      ORG_ID                        NUMBER,
      RELATED_ID_NUMBER             VARCHAR2(100 BYTE),
      RELATED_CUST_ACCOUNT_ID       NUMBER,
      RELATIONSHIP_TYPE             VARCHAR2(240 BYTE),
      RELATIONSHIP_CODE             VARCHAR2(100 BYTE),
      CUSTOMER_RECIPORICAL_FLAG     VARCHAR2(10 BYTE),
      BILL_TO_FLAG                  VARCHAR2(10 BYTE),
      SHIP_TO_FLAG                  VARCHAR2(10 BYTE),
      START_DATE                    DATE,
      END_DATE                      DATE,
      COMMENTS                      VARCHAR(100 BYTE),
      RECORD_NUMBER                 NUMBER,
      REQUEST_ID                    NUMBER,
      LAST_UPDATED_BY               NUMBER,
      LAST_UPDATE_DATE              DATE,
      PHASE_CODE                    VARCHAR2(100 BYTE),
      ERROR_CODE                    VARCHAR2(10 BYTE),
      ERROR_MSG                     VARCHAR2(500 BYTE)
        );

    TYPE xx_otc_cust_relate_tab_type IS TABLE OF xxconv.xx_ar_cust_relate%ROWTYPE
      INDEX BY BINARY_INTEGER;

    g_miss_cust_relate_tab        xx_otc_cust_relate_tab_type;

    g_miss_cust_relate_rec        xxconv.xx_ar_cust_relate%ROWTYPE;
    g_miss_cust_acct_relate_rec   hz_cust_account_v2pub.cust_acct_relate_rec_type;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_ar_cust_relate_pkg;
/
