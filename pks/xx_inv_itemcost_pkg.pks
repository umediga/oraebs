DROP PACKAGE APPS.XX_INV_ITEMCOST_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_INV_ITEMCOST_PKG" AUTHID CURRENT_USER AS
 /* $Header: XXINVITEMCOSTCNV.pks 1.0.1 2012/03/12 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 14-FEB-2012
  -- Filename       : XXINVITEMCOSTCNV.pks
  -- Description    : Package specification for Item Cost Import

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 20-Jan-2012   1.0       Partha S Mohanty    Initial development.
--====================================================================================

   -- Global Variables
    G_STAGE		VARCHAR2(2000);
    G_BATCH_ID		VARCHAR2(200);
    G_COMP_BATCH_ID	VARCHAR2(200);
    G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';

    g_api_name		VARCHAR2(200);
    g_make_buy		VARCHAR2(15);
    g_transaction_type	VARCHAR2(10) := 'CREATE';

    g_process_flag	NUMBER := 1;

  TYPE G_XX_ITEMCOST_STG_REC_TYPE  IS RECORD
    (   ITEM_NUMBER                   	VARCHAR2(81),
        INV_ORGANIZATION_CODE           VARCHAR2(50), -- Added for data file actually not in interface table
        OVERHEAD_CODE                   VARCHAR2(150), -- Added for data file actually not in interface table
        ORGANIZATION_ID               	NUMBER,
        USAGE_RATE_OR_AMOUNT          	NUMBER,
        COST_ELEMENT                  	VARCHAR2(50),
        INVENTORY_ITEM_ID             	NUMBER,
        COST_TYPE_ID                  	NUMBER,
        LAST_UPDATE_DATE              	DATE,
        LAST_UPDATED_BY               	NUMBER,
        CREATION_DATE                 	DATE,
        CREATED_BY                    	NUMBER,
        LAST_UPDATE_LOGIN             	NUMBER,
        GROUP_ID                      	NUMBER,
        OPERATION_SEQUENCE_ID         	NUMBER,
        OPERATION_SEQ_NUM             	NUMBER,
        DEPARTMENT_ID                 	NUMBER,
        LEVEL_TYPE                    	NUMBER,
        ACTIVITY_ID                   	NUMBER,
        RESOURCE_SEQ_NUM              	NUMBER,
        RESOURCE_ID                   	NUMBER,
        RESOURCE_RATE                 	NUMBER,
        ITEM_UNITS                    	NUMBER,
        ACTIVITY_UNITS                	NUMBER,
        BASIS_TYPE                    	NUMBER,
        BASIS_RESOURCE_ID             	NUMBER,
        BASIS_FACTOR                  	NUMBER,
        NET_YIELD_OR_SHRINKAGE_FACTOR 	NUMBER,
        ITEM_COST                     	NUMBER,
        COST_ELEMENT_ID               	NUMBER,
        ROLLUP_SOURCE_TYPE            	NUMBER,
        ACTIVITY_CONTEXT              	VARCHAR2(30),
        REQUEST_ID                    	NUMBER,
        ORGANIZATION_CODE             	VARCHAR2(3),
        COST_TYPE                     	VARCHAR2(10),
        INVENTORY_ITEM                	VARCHAR2(240),
        DEPARTMENT                    	VARCHAR2(10),
        ACTIVITY                      	VARCHAR2(10),
        RESOURCE_CODE                 	VARCHAR2(10),
        BASIS_RESOURCE_CODE           	VARCHAR2(10),
        PROGRAM_APPLICATION_ID        	NUMBER,
        PROGRAM_ID                    	NUMBER,
        PROGRAM_UPDATE_DATE           	DATE,
        ATTRIBUTE_CATEGORY            	VARCHAR2(30),
        ATTRIBUTE1                    	VARCHAR2(150),
        ATTRIBUTE2                    	VARCHAR2(150),
        ATTRIBUTE3                    	VARCHAR2(150),
        ATTRIBUTE4                    	VARCHAR2(150),
        ATTRIBUTE5                    	VARCHAR2(150),
        ATTRIBUTE6                    	VARCHAR2(150),
        ATTRIBUTE7                    	VARCHAR2(150),
        ATTRIBUTE8                    	VARCHAR2(150),
        ATTRIBUTE9                    	VARCHAR2(150),
        ATTRIBUTE10                   	VARCHAR2(150),
        ATTRIBUTE11                   	VARCHAR2(150),
        ATTRIBUTE12                   	VARCHAR2(150),
        ATTRIBUTE13                   	VARCHAR2(150),
        ATTRIBUTE14                   	VARCHAR2(150),
        ATTRIBUTE15                   	VARCHAR2(150),
        TRANSACTION_ID                	NUMBER,
        TRANSACTION_TYPE              	VARCHAR2(10),
        YIELDED_COST                  	NUMBER,
        LOT_SIZE                      	NUMBER,
        BASED_ON_ROLLUP_FLAG          	NUMBER,
        SHRINKAGE_RATE                	NUMBER,
        INVENTORY_ASSET_FLAG          	NUMBER,
        GROUP_DESCRIPTION             	VARCHAR2(80),
        PROCESS_FLAG                  	NUMBER,
        ERROR_CODE                    	VARCHAR2(240),
        ERROR_TYPE                    	NUMBER,
        ERROR_EXPLANATION             	VARCHAR2(240),
        ERROR_FLAG                    	VARCHAR2(1),
        BATCH_ID			                  VARCHAR2(200),  -- Custom column added
        PROCESS_CODE			              VARCHAR2(100),  -- Custom column added
        ERROR_MESG                    	VARCHAR2(2000), -- Custom column added
        SOURCE_SYSTEM_NAME              VARCHAR2(100),  -- Custom column added on 04 jun 2013
        RECORD_NUMBER	                  NUMBER          -- Custom column added
   );


  -- Item Cost Staging Table Type
  TYPE g_xx_itemcost_tab_type IS TABLE OF G_XX_ITEMCOST_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;


   PROCEDURE main(x_errbuf   OUT VARCHAR2
                                ,x_retcode  OUT VARCHAR2
                                ,p_batch_id      IN  VARCHAR2
                                ,p_restart_flag  IN  VARCHAR2
				                        ,p_cost_type     IN  VARCHAR2
                                ,p_make_buy      IN  VARCHAR2
                                ,p_validate_and_load     IN VARCHAR2);

END xx_inv_itemcost_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEMCOST_PKG TO INTG_XX_NONHR_RO;
