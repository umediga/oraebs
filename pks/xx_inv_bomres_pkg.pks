DROP PACKAGE APPS.XX_INV_BOMRES_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_BOMRES_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMRES.pks
Description   : This script creates the specification of the package xx_inv_bomres_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
06-Dec-2013  ABHARGAVA            Initial Draft.
*/
----------------------------------------------------------------------

   -- Global Variables
   G_STAGE               VARCHAR2 (2000);
   G_BATCH_ID            VARCHAR2 (200);
   G_API_NAME            VARCHAR2 (100);
   G_VALIDATE_AND_LOAD   VARCHAR2 (100)          := 'VALIDATE_AND_LOAD';
   G_CREATED_BY_MODULE   CONSTANT VARCHAR2 (20)  := 'TCA_V2_API';

   TYPE g_xx_inv_bomres_rec_type
   IS
   RECORD (
      BATCH_ID                      VARCHAR2(50 BYTE),
      SOURCE_SYSTEM_NAME            VARCHAR2(20 BYTE),
      RECORD_NUMBER                 NUMBER,
      RESOURCE_CODE                 VARCHAR2(10  BYTE),
      RESOURCE_ID                   NUMBER,
      ORG_CODE                      VARCHAR2(10  BYTE),
      ORG_ID                        NUMBER,
      DESCRIPTION                   VARCHAR2(240 BYTE),
      DISABLE_DATE                  DATE,
      RESOURCE_TYPE                 VARCHAR2(100  BYTE),
      RESOURCE_TYPE_ID              NUMBER,
      CHARGE_TYPE                   VARCHAR2(100  BYTE),
      AUTOCHARGE_TYPE_ID            NUMBER,
      COST_CODE                     VARCHAR2(100  BYTE),
      COST_CODE_TYPE                NUMBER,
      PURCHASE_ITEM                 VARCHAR2(240 BYTE),
      PURCHASE_ITEM_ID              NUMBER,
      UOM                           VARCHAR2(3 BYTE),
      ABSORPTION_ACCOUNT            VARCHAR2(240 BYTE),
      ABSORPTION_ACCOUNT_ID         NUMBER,
      RATE_VARIANCE_ACCOUNT         VARCHAR2(240 BYTE),
      RATE_VARIANCE_ACCOUNT_ID      NUMBER,
      ALLOW_COST_FLAG               VARCHAR2(240 BYTE),
      ALLOW_COST_FLAG_ID            NUMBER,
      COST_ELEMENT_ID               NUMBER,
      FUNCTIONAL_CURRENCY_FLAG_ID   NUMBER,
      DEFAULT_ACTIVITY_ID           NUMBER,
      STANDARD_RATE_FLAG_ID         NUMBER,
      ATTRIBUTE_CATEGORY            VARCHAR2(30 BYTE),
      ATTRIBUTE1                    VARCHAR2(150 BYTE),
      ATTRIBUTE2                    VARCHAR2(150 BYTE),
      ATTRIBUTE3                    VARCHAR2(150 BYTE),
      ATTRIBUTE4                    VARCHAR2(150 BYTE),
      ATTRIBUTE5                    VARCHAR2(150 BYTE),
      ATTRIBUTE6                    VARCHAR2(150 BYTE),
      ATTRIBUTE7                    VARCHAR2(150 BYTE),
      ATTRIBUTE8                    VARCHAR2(150 BYTE),
      ATTRIBUTE9                    VARCHAR2(150 BYTE),
      ATTRIBUTE10                   VARCHAR2(150 BYTE),
      ATTRIBUTE11                   VARCHAR2(150 BYTE),
      ATTRIBUTE12                   VARCHAR2(150 BYTE),
      ATTRIBUTE13                   VARCHAR2(150 BYTE),
      ATTRIBUTE14                   VARCHAR2(150 BYTE),
      ATTRIBUTE15                   VARCHAR2(150 BYTE),
      BATCHABLE_FLAG                VARCHAR2(10  BYTE),
      BATCHABLE_FLAG_ID             NUMBER,
      MIN_BATCH_CAPACITY            NUMBER,
      MAX_BATCH_CAPACITY            NUMBER,
      BATCH_CAPACITY_UOM            VARCHAR2(3 BYTE),
      BATCH_WINDOW                  NUMBER,
      BATCH_WINDOW_UOM              VARCHAR2(3 BYTE),
      BILLABLE_ITEM                 VARCHAR2(240 BYTE),
      BILLABLE_ITEM_ID              NUMBER,
      REQUEST_ID                    NUMBER,
      LAST_UPDATED_BY               NUMBER,
      LAST_UPDATE_DATE              DATE,
      PHASE_CODE                    VARCHAR2(100 BYTE),
      ERROR_CODE                    VARCHAR2(10 BYTE),
      ERROR_MSG                     VARCHAR2(500 BYTE)
      );


   TYPE xx_inv_bomres_tab_type IS TABLE OF xxconv.XX_INV_BOMRES_STG%ROWTYPE
   INDEX BY BINARY_INTEGER;

    g_miss_bomres_tab        xx_inv_bomres_tab_type;

    g_miss_bomres_rec        xxconv.XX_INV_BOMRES_STG%ROWTYPE;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_inv_bomres_pkg;
/
