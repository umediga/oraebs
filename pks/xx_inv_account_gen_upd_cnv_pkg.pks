DROP PACKAGE APPS.XX_INV_ACCOUNT_GEN_UPD_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ACCOUNT_GEN_UPD_CNV_PKG" AUTHID CURRENT_USER AS

----------------------------------------------------------------------------------
/* $Header: XXINVACCOUNTGENUPDCNV.pks 1.0 2012/05/02 12:00:00 Damd noship $ */
/*
Created By    : IBM Development Team
Creation Date : 02-May-2012
File Name     : XXINVACCOUNTGENUPDCNV.pkb
Description   : This script creates the spec for the Account Generation Revenue Conversion

Change History:

Version Date        Name                   Remarks
------- ----------- -------------------    ----------------------
1.0     20-Feb-12   IBM Development Team   Initial development.

*/
----------------------------------------------------------------------

   -- Global Variables
    G_PROCESS_NAME VARCHAR2(60)  :='XXINVACGENCNV';
    G_STAGE		VARCHAR2(2000);
    G_REQUEST_ID		VARCHAR2(200);
    G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';
    G_PROCESS_FLAG	NUMBER := 1;
    G_API_NAME          VARCHAR2(100);
    G_CAT_SET_NAME      VARCHAR2(50);
    G_TRANS_TYPE_MAST   VARCHAR2(10) := 'UPDATE';
    G_SET_PROCESS_ID    NUMBER:=0;



  TYPE G_XX_ACCOUNT_GEN_STG_REC_TYPE  IS RECORD
    (   RECORD_NUMBER	                NUMBER,
        ORGANIZATION_CODE               VARCHAR2(3),
        ORGANIZATION_ID                 NUMBER,
        ORG_HIERACHY_NAME               VARCHAR2(30),
        CHILD_ORG                       VARCHAR2(30),
        CHILD_ORG_ID                    NUMBER,
        ITEM_NUMBER                     VARCHAR2(40),
        INV_ITEM_ID                     NUMBER,
        CATEGORY_NAME                   VARCHAR2(40),
        CATEGORY_SET_ID                 NUMBER,
        CATEGORY_ID                     NUMBER,
        CAT_SEGMENT1			VARCHAR2(40),
        COST_OF_SALES_ACCOUNT           NUMBER,
        COGS_SEGMENT1                   VARCHAR2(25),
        COGS_SEGMENT2                   VARCHAR2(25),
        COGS_SEGMENT3                   VARCHAR2(25),
        COGS_SEGMENT4                   VARCHAR2(25),
        COGS_SEGMENT5                   VARCHAR2(25),
        COGS_SEGMENT6                   VARCHAR2(25),
        COGS_SEGMENT7                   VARCHAR2(25),
        COGS_SEGMENT8                   VARCHAR2(25),
        COGS_SEGMENT9                   VARCHAR2(25),
        SALES_ACCOUNT                   NUMBER,
        SALES_SEGMENT1                  VARCHAR2(25),
        SALES_SEGMENT2                  VARCHAR2(25),
        SALES_SEGMENT3                  VARCHAR2(25),
        SALES_SEGMENT4                  VARCHAR2(25),
        SALES_SEGMENT5                  VARCHAR2(25),
        SALES_SEGMENT6                  VARCHAR2(25),
        SALES_SEGMENT7                  VARCHAR2(25),
        SALES_SEGMENT8                  VARCHAR2(25),
        SALES_SEGMENT9                  VARCHAR2(25),
        COGS_NEW_CCID                   NUMBER,
        SALES_NEW_CCID                  NUMBER,
        PROCESS_CODE	                VARCHAR2(100),
        ERROR_CODE  	                VARCHAR2(240),
        ERROR_TYPE                    	NUMBER,
        ERROR_EXPLANATION             	VARCHAR2(240),
        ERROR_FLAG                    	VARCHAR2(1),
        ERROR_MESG                    	VARCHAR2(2000),
        PROGRAM_APPLICATION_ID          NUMBER,
        PROGRAM_ID                      NUMBER,
        PROGRAM_UPDATE_DATE             DATE,
        PROCESS_FLAG                  	NUMBER,
        SET_PROCESS_ID                  NUMBER,
        CREATION_DATE                   DATE,
        CREATED_BY                      NUMBER,
        LAST_UPDATE_DATE                DATE,
        LAST_UPDATED_BY                 NUMBER,
        LAST_UPDATE_LOGIN               NUMBER,
        REQUEST_ID                      NUMBER
        );


  -- Applicant Staging Table Type
  TYPE g_xx_account_gen_tab_type IS TABLE OF G_XX_ACCOUNT_GEN_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

   PROCEDURE main(o_errbuf   OUT VARCHAR2
                 ,o_retcode  OUT VARCHAR2
                 ,p_org_hierachy_name IN VARCHAR2
                 ,p_inventory_organization IN NUMBER
                 ,p_item_number       IN VARCHAR2);

END xx_inv_account_gen_upd_cnv_pkg;
/
