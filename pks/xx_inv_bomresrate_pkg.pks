DROP PACKAGE APPS.XX_INV_BOMRESRATE_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_BOMRESRATE_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMRESRATE.pks
Description   : This script creates the specification of the package xx_inv_bomresrate_pkg
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

   TYPE g_xx_inv_bomresrate_rec_type
   IS
   RECORD (
      BATCH_ID                      VARCHAR2(50 BYTE),
      SOURCE_SYSTEM_NAME            VARCHAR2(20 BYTE),
      RECORD_NUMBER                 NUMBER,
      ORG_CODE                      VARCHAR2(10  BYTE),
      ORG_ID                        NUMBER,
      RES_CODE				              VARCHAR2(10 BYTE),
      RESOURCE_ID                   NUMBER,
      COST_TYPE 					          VARCHAR2(100 BYTE),
      COST_TYPE_ID                  NUMBER,
      RESOURCE_RATE   			        NUMBER,
      REQUEST_ID                    NUMBER,
      LAST_UPDATED_BY               NUMBER,
      LAST_UPDATE_DATE              DATE,
      PHASE_CODE                    VARCHAR2(100 BYTE),
      ERROR_CODE                    VARCHAR2(10 BYTE),
      ERROR_MSG                     VARCHAR2(500 BYTE)
      );


   TYPE xx_inv_bomresrate_tab_type IS TABLE OF xxconv.XX_INV_BOMRESRATE_STG%ROWTYPE
   INDEX BY BINARY_INTEGER;

    g_miss_bomresrat_tab        xx_inv_bomresrate_tab_type;

    g_miss_bomresrate_rec       xxconv.XX_INV_BOMRESrate_STG%ROWTYPE;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_cost_type              IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_inv_bomresrate_pkg;
/
