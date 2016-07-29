DROP PACKAGE APPS.XX_INV_BOMDEPRES_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_BOMDEPRES_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMDEPRES.pks
Description   : This script creates the specification of the package xx_inv_BOMDEPRES_pkg
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

   TYPE g_xx_inv_BOMDEPRES_rec_type
   IS
   RECORD (
          BATCH_ID                      VARCHAR2(50 BYTE),
          SOURCE_SYSTEM_NAME            VARCHAR2(20 BYTE),
          RECORD_NUMBER                 NUMBER,
          ORG_CODE                      VARCHAR2(10  BYTE),
          ORG_ID                        NUMBER,
          DEPT_CODE                     VARCHAR2(30  BYTE),
          DEPT_ID                       NUMBER,
          RES_CODE                      VARCHAR2(10  BYTE),
          RES_ID                        NUMBER,
          SHARE_CAPACITY_FLAG           VARCHAR2(10 BYTE),
          SHARE_CAPACITY_FLAG_ID        NUMBER,
          CAPACITY_UNITS                NUMBER,
          AVAILABLE_24_HOURS_FLAG       VARCHAR2(10 BYTE),
          AVLBL_24_ID                   NUMBER,
          CTP_FLAG                      VARCHAR2(10 BYTE),
          CTP_FLAG_ID                   NUMBER,
          EXCEPTION_SET_NAME            VARCHAR2(50 BYTE),
          ATP_RULE                      VARCHAR2(50 BYTE),
          ATP_RULE_ID                   NUMBER,
          UTILIZATION                   NUMBER,
          EFFICIENCY                    NUMBER,
          SCHEDULE_TO_INSTANCE          NUMBER,
          SEQUENCING_WINDOW             NUMBER,
          REQUEST_ID                    NUMBER,
          LAST_UPDATED_BY               NUMBER,
          LAST_UPDATE_DATE              DATE,
          PHASE_CODE                    VARCHAR2(100 BYTE),
          ERROR_CODE                    VARCHAR2(10 BYTE),
          ERROR_MSG                     VARCHAR2(500 BYTE)
      );


   TYPE xx_inv_BOMDEPRES_tab_type IS TABLE OF xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE
   INDEX BY BINARY_INTEGER;

    g_miss_BOMDEPRES_tab        xx_inv_BOMDEPRES_tab_type;

    g_miss_BOMDEPRES_rec        xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE;

   -- Main Procedure
   PROCEDURE main (errbuf                   OUT VARCHAR2,
                   retcode                  OUT VARCHAR2,
                   p_batch_id               IN  VARCHAR2,
                   p_restart_flag           IN  VARCHAR2,
                   p_validate_and_load      IN  VARCHAR2);


END xx_inv_BOMDEPRES_pkg;
/
