DROP PACKAGE APPS.XX_AR_CUST_ATTACH_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_AR_CUST_ATTACH_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 17-June-2013
File Name     : XXARCUSTATT.pks
Description   : This script creates the specification of the package xx_ar_cust_attach_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
17-June-2013  ABHARGAVA            Initial Draft.
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';

   TYPE g_xx_ar_cust_att_rec_type
   IS
   RECORD (
      BATCH_ID                      VARCHAR2(100 BYTE)
     ,SOURCE_SYSTEM_NAME            VARCHAR2(240 BYTE)
     ,DOCUMENT_ID                   NUMBER
     ,ATTACHED_DOCUMENT_ID          NUMBER
     ,MEDIA_ID                      NUMBER
     ,ENTITY_NAME                   VARCHAR2(40  BYTE)
     ,DOCUMENT_ENTITY_ID            NUMBER
     ,ACCOUNT_NUMBER                VARCHAR2(30  BYTE)
     ,CUST_ACCOUNT_ID               NUMBER
     ,SEQ_NUM                       NUMBER
     ,DATATYPE_NAME                 VARCHAR2(30  BYTE)
     ,DATATYPE_ID                   NUMBER
     ,CATEGORY_NAME                 VARCHAR2(30  BYTE)
     ,CATEGORY_ID                   NUMBER
     ,SECURITY_TYPE                 VARCHAR2(30  BYTE)
     ,TITLE                         VARCHAR2(100 BYTE)
     ,DESCRIPTION                   VARCHAR2(200 BYTE)
     ,URL                           VARCHAR2(200 BYTE)
     ,SHORT_TEXT                    VARCHAR2(4000 BYTE)
     ,LONG_TEXT                     LONG
     ,FILE_NAME                     VARCHAR2(2048 BYTE)
     ,FILE_CONTENT_TYPE             VARCHAR2(100 BYTE)
     ,FILE_DATA                     BLOB
     ,ATTRIBUTE_CATEGORY            VARCHAR2(100 BYTE)
     ,ATTRIBUTE1                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE2                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE3                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE4                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE5                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE6                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE7                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE8                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE9                    VARCHAR2(100 BYTE)
     ,ATTRIBUTE10                   VARCHAR2(100 BYTE)
     ,RECORD_NUMBER                 NUMBER
     ,REQUEST_ID                    NUMBER
     ,LAST_UPDATED_BY               NUMBER
     ,LAST_UPDATE_DATE              DATE
     ,PHASE_CODE                    VARCHAR2(100 BYTE)
     ,ERROR_CODE                    VARCHAR2(10 BYTE)
     ,ERROR_MSG                     VARCHAR2(500 BYTE)
      );


   TYPE xx_otc_cust_attach_tab_type IS TABLE OF xxconv.xx_ar_cust_attach%ROWTYPE
   INDEX BY BINARY_INTEGER;

    g_miss_cust_attach_tab        xx_otc_cust_attach_tab_type;

    g_miss_cust_attach_rec        xxconv.xx_ar_cust_attach%ROWTYPE;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_ar_cust_attach_pkg;
/
