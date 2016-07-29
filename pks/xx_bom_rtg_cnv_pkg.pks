DROP PACKAGE APPS.XX_BOM_RTG_CNV_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_bom_rtg_cnv_pkg AUTHID CURRENT_USER AS
 /* $Header: XXBOMRTGCNV.pks 1.0.0 2012/02/24 00:00:00 dsengupta noship $ */
--==================================================================================
  -- Created By     : Diptiman Sengupta
  -- Creation Date  : 24-FEB-2012
  -- Filename       : XXBOMRTGCNV.pks
  -- Description    : Package specification for Item Routing Import

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 24-Feb-2012   1.0       Diptiman Sengupta   Initial development.
--====================================================================================

   -- Global Variables
    G_STAGE		VARCHAR2(2000);
    G_BATCH_ID		VARCHAR2(200);
    G_COMP_BATCH_ID	VARCHAR2(200);
    G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';

    G_API_NAME		VARCHAR2(200);

    G_TRANSACTION_TYPE	VARCHAR2(10) := null;

    G_PROCESS_FLAG	NUMBER := 1;

    G_REQUEST_ID NUMBER := FND_PROFILE.VALUE('CONC_REQUEST_ID');

    G_USER_ID NUMBER := FND_GLOBAL.USER_ID; --FND_PROFILE.VALUE('USER_ID');

    G_RESP_ID NUMBER := FND_PROFILE.VALUE('RESP_ID');

    G_TRANS_TYPE_CREATE VARCHAR2(10) := 'CREATE';
    G_TRANS_TYPE_DELETE VARCHAR2(10) := 'DELETE';

    G_RTG_DEL_GRP      VARCHAR2(10):= NULL;
    G_OPR_DEL_GRP      VARCHAR2(10):= NULL;


  -- Routing Header Staging Record Type
  TYPE G_XX_RTG_HDR_STG_REC_TYPE  IS RECORD
    (	  ROUTING_SEQUENCE_ID                                NUMBER
	 ,ASSEMBLY_ITEM_ID                                   NUMBER
	 ,ORGANIZATION_ID                                    NUMBER
	 ,ALTERNATE_ROUTING_DESIGNATOR                       VARCHAR2(10)
	 ,LAST_UPDATE_DATE                                   DATE
	 ,LAST_UPDATED_BY                                    NUMBER
	 ,CREATION_DATE                                      DATE
	 ,CREATED_BY                                         NUMBER
	 ,LAST_UPDATE_LOGIN                                  NUMBER
	 ,ROUTING_TYPE                                       NUMBER
	 ,COMMON_ASSEMBLY_ITEM_ID                            NUMBER
	 ,COMMON_ROUTING_SEQUENCE_ID                         NUMBER
	 ,ROUTING_COMMENT                                    VARCHAR2(240)
	 ,COMPLETION_SUBINVENTORY                            VARCHAR2(10)
	 ,COMPLETION_LOCATOR_ID                              NUMBER
	 ,COMPLETION_LOCATOR				     VARCHAR2(30)
	 ,ATTRIBUTE_CATEGORY                                 VARCHAR2(30)
	 ,ATTRIBUTE1                                         VARCHAR2(150)
	 ,ATTRIBUTE2                                         VARCHAR2(150)
	 ,ATTRIBUTE3                                         VARCHAR2(150)
	 ,ATTRIBUTE4                                         VARCHAR2(150)
	 ,ATTRIBUTE5                                         VARCHAR2(150)
	 ,ATTRIBUTE6                                         VARCHAR2(150)
	 ,ATTRIBUTE7                                         VARCHAR2(150)
	 ,ATTRIBUTE8                                         VARCHAR2(150)
	 ,ATTRIBUTE9                                         VARCHAR2(150)
	 ,ATTRIBUTE10                                        VARCHAR2(150)
	 ,ATTRIBUTE11                                        VARCHAR2(150)
	 ,ATTRIBUTE12                                        VARCHAR2(150)
	 ,ATTRIBUTE13                                        VARCHAR2(150)
	 ,ATTRIBUTE14                                        VARCHAR2(150)
	 ,ATTRIBUTE15                                        VARCHAR2(150)
	 ,REQUEST_ID                                         NUMBER
	 ,PROGRAM_APPLICATION_ID                             NUMBER
	 ,PROGRAM_ID                                         NUMBER
	 ,PROGRAM_UPDATE_DATE                                DATE
	 ,DEMAND_SOURCE_LINE                                 VARCHAR2(30)
	 ,SET_ID                                             VARCHAR2(10)
	 ,PROCESS_REVISION                                   VARCHAR2(3)
	 ,DEMAND_SOURCE_TYPE                                 NUMBER
	 ,DEMAND_SOURCE_HEADER_ID                            NUMBER
	 ,ORGANIZATION_CODE                                  VARCHAR2(3)
	 ,ASSEMBLY_ITEM_NUMBER                               VARCHAR2(240)
	 ,COMMON_ITEM_NUMBER                                 VARCHAR2(240)
	 ,LOCATION_NAME                                      VARCHAR2(81)
	 ,TRANSACTION_ID                                     NUMBER
	 ,PROCESS_FLAG                                       NUMBER
	 ,TRANSACTION_TYPE                                   VARCHAR2(10)
	 ,LINE_ID                                            NUMBER
	 ,LINE_CODE                                          VARCHAR2(10)
	 ,MIXED_MODEL_MAP_FLAG                               NUMBER
	 ,PRIORITY                                           NUMBER
	 ,CFM_ROUTING_FLAG                                   NUMBER
	 ,TOTAL_PRODUCT_CYCLE_TIME                           NUMBER
	 ,CTP_FLAG                                           NUMBER
	 ,ORIGINAL_SYSTEM_REFERENCE                          VARCHAR2(50)
	 ,SERIALIZATION_START_OP                             NUMBER
	 ,DELETE_GROUP_NAME                                  VARCHAR2(10)
	 ,DG_DESCRIPTION                                     VARCHAR2(240)
	 ,BATCH_ID                                           VARCHAR2(200)
	 ,ERROR_CODE					     VARCHAR2(240)
	 ,ERROR_TYPE					     NUMBER
	 ,ERROR_EXPLANATION				     VARCHAR2(240)
	 ,ERROR_FLAG					     VARCHAR2(1)
	 ,PROCESS_CODE					     VARCHAR2(100)
	 ,ERROR_MESG					     VARCHAR2(2000)
	 ,RECORD_NUMBER					     NUMBER
   );

  -- Routing Header Staging Table Type
  TYPE g_xx_rtg_hdr_tab_type IS TABLE OF G_XX_RTG_HDR_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

  -- Operation Sequence Staging Record Type
  TYPE G_XX_OP_SEQ_STG_REC_TYPE  IS RECORD
    (	  OPERATION_SEQUENCE_ID                              NUMBER
	 ,ROUTING_SEQUENCE_ID                                NUMBER
	 ,OPERATION_SEQ_NUM                                  NUMBER
	 ,LAST_UPDATE_DATE                                   DATE
	 ,LAST_UPDATED_BY                                    NUMBER
	 ,CREATION_DATE                                      DATE
	 ,CREATED_BY                                         NUMBER
	 ,LAST_UPDATE_LOGIN                                  NUMBER
	 ,STANDARD_OPERATION_ID                              NUMBER
	 ,DEPARTMENT_ID                                      NUMBER
	 ,OPERATION_LEAD_TIME_PERCENT                        NUMBER
	 ,RUN_TIME_OVERLAP_PERCENT                           NUMBER
	 ,MINIMUM_TRANSFER_QUANTITY                          NUMBER
	 ,COUNT_POINT_TYPE                                   NUMBER
	 ,OPERATION_DESCRIPTION                              VARCHAR2(240)
	 ,EFFECTIVITY_DATE                                   DATE
	 ,CHANGE_NOTICE                                      VARCHAR2(10)
	 ,IMPLEMENTATION_DATE                                DATE
	 ,DISABLE_DATE                                       DATE
	 ,BACKFLUSH_FLAG                                     NUMBER
	 ,OPTION_DEPENDENT_FLAG                              NUMBER
	 ,ATTRIBUTE_CATEGORY                                 VARCHAR2(30)
	 ,ATTRIBUTE1                                         VARCHAR2(150)
	 ,ATTRIBUTE2                                         VARCHAR2(150)
	 ,ATTRIBUTE3                                         VARCHAR2(150)
	 ,ATTRIBUTE4                                         VARCHAR2(150)
	 ,ATTRIBUTE5                                         VARCHAR2(150)
	 ,ATTRIBUTE6                                         VARCHAR2(150)
	 ,ATTRIBUTE7                                         VARCHAR2(150)
	 ,ATTRIBUTE8                                         VARCHAR2(150)
	 ,ATTRIBUTE9                                         VARCHAR2(150)
	 ,ATTRIBUTE10                                        VARCHAR2(150)
	 ,ATTRIBUTE11                                        VARCHAR2(150)
	 ,ATTRIBUTE12                                        VARCHAR2(150)
	 ,ATTRIBUTE13                                        VARCHAR2(150)
	 ,ATTRIBUTE14                                        VARCHAR2(150)
	 ,ATTRIBUTE15                                        VARCHAR2(150)
	 ,REQUEST_ID                                         NUMBER
	 ,PROGRAM_APPLICATION_ID                             NUMBER
	 ,PROGRAM_ID                                         NUMBER
	 ,PROGRAM_UPDATE_DATE                                DATE
	 ,MODEL_OP_SEQ_ID                                    NUMBER
	 ,ASSEMBLY_ITEM_ID                                   NUMBER
	 ,ORGANIZATION_ID                                    NUMBER
	 ,ALTERNATE_ROUTING_DESIGNATOR                       VARCHAR2(10)
	 ,ORGANIZATION_CODE                                  VARCHAR2(3)
	 ,ASSEMBLY_ITEM_NUMBER                               VARCHAR2(240)
	 ,DEPARTMENT_CODE                                    VARCHAR2(10)
	 ,OPERATION_CODE                                     VARCHAR2(4)
	 ,RESOURCE_ID1                                       NUMBER
	 ,RESOURCE_ID2                                       NUMBER
	 ,RESOURCE_ID3                                       NUMBER
	 ,RESOURCE_CODE1                                     VARCHAR2(10)
	 ,RESOURCE_CODE2                                     VARCHAR2(10)
	 ,RESOURCE_CODE3                                     VARCHAR2(10)
	 ,INSTRUCTION_CODE1                                  VARCHAR2(10)
	 ,INSTRUCTION_CODE2                                  VARCHAR2(10)
	 ,INSTRUCTION_CODE3                                  VARCHAR2(10)
	 ,TRANSACTION_ID                                     NUMBER
	 ,PROCESS_FLAG                                       NUMBER
	 ,TRANSACTION_TYPE                                   VARCHAR2(10)
	 ,NEW_OPERATION_SEQ_NUM                              NUMBER
	 ,NEW_EFFECTIVITY_DATE                               DATE
	 ,ASSEMBLY_TYPE                                      NUMBER
	 ,OPERATION_TYPE                                     NUMBER
	 ,REFERENCE_FLAG                                     NUMBER
	 ,PROCESS_OP_SEQ_ID                                  NUMBER
	 ,LINE_OP_SEQ_ID                                     NUMBER
	 ,YIELD                                              NUMBER
	 ,CUMULATIVE_YIELD                                   NUMBER
	 ,REVERSE_CUMULATIVE_YIELD                           NUMBER
	 ,LABOR_TIME_CALC                                    NUMBER
	 ,MACHINE_TIME_CALC                                  NUMBER
	 ,TOTAL_TIME_CALC                                    NUMBER
	 ,LABOR_TIME_USER                                    NUMBER
	 ,MACHINE_TIME_USER                                  NUMBER
	 ,TOTAL_TIME_USER                                    NUMBER
	 ,NET_PLANNING_PERCENT                               NUMBER
	 ,INCLUDE_IN_ROLLUP                                  NUMBER
	 ,OPERATION_YIELD_ENABLED                            NUMBER
	 ,PROCESS_SEQ_NUMBER                                 NUMBER
	 ,PROCESS_CODE                                       VARCHAR2(4)
	 ,LINE_OP_SEQ_NUMBER                                 NUMBER
	 ,LINE_OP_CODE                                       VARCHAR2(4)
	 ,ORIGINAL_SYSTEM_REFERENCE                          VARCHAR2(50)
	 ,SHUTDOWN_TYPE                                      VARCHAR2(30)
	 ,LONG_DESCRIPTION                                   VARCHAR2(4000)
	 ,DELETE_GROUP_NAME                                  VARCHAR2(10)
	 ,DG_DESCRIPTION                                     VARCHAR2(240)
	 ,NEW_ROUTING_REVISION                               VARCHAR2(3)
	 ,ACD_TYPE                                           NUMBER
	 ,OLD_START_EFFECTIVE_DATE                           DATE
	 ,CANCEL_COMMENTS                                    VARCHAR2(240)
	 ,ENG_CHANGES_IFCE_KEY                               VARCHAR2(30)
	 ,ENG_REVISED_ITEMS_IFCE_KEY                         VARCHAR2(30)
	 ,BOM_REV_OP_IFCE_KEY                                VARCHAR2(30)
	 ,NEW_REVISED_ITEM_REVISION                          VARCHAR2(3)
	 ,BATCH_ID                                           VARCHAR2(200)
	 ,ERROR_CODE					     VARCHAR2(240)
	 ,ERROR_TYPE					     NUMBER
	 ,ERROR_EXPLANATION				     VARCHAR2(240)
	 ,ERROR_FLAG					     VARCHAR2(1)
	 ,PROCESS_CODE1					     VARCHAR2(100)
	 ,ERROR_MESG					     VARCHAR2(2000)
	 ,RECORD_NUMBER					     NUMBER
   );

  -- Operation Sequence Staging Table Type
  TYPE g_xx_op_seq_tab_type IS TABLE OF G_XX_OP_SEQ_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

  -- Operation Resource Staging Record Type
  TYPE G_XX_OP_RES_STG_REC_TYPE  IS RECORD
    (	  OPERATION_SEQUENCE_ID                              NUMBER
	 ,RESOURCE_SEQ_NUM                                   NUMBER
	 ,RESOURCE_ID                                        NUMBER
	 ,ACTIVITY_ID                                        NUMBER
	 ,STANDARD_RATE_FLAG                                 NUMBER
	 ,ASSIGNED_UNITS                                     NUMBER
	 ,USAGE_RATE_OR_AMOUNT                               NUMBER
	 ,USAGE_RATE_OR_AMOUNT_INVERSE                       NUMBER
	 ,BASIS_TYPE                                         NUMBER
	 ,SCHEDULE_FLAG                                      NUMBER
	 ,LAST_UPDATE_DATE                                   DATE
	 ,LAST_UPDATED_BY                                    NUMBER
	 ,CREATION_DATE                                      DATE
	 ,CREATED_BY                                         NUMBER
	 ,LAST_UPDATE_LOGIN                                  NUMBER
	 ,RESOURCE_OFFSET_PERCENT                            NUMBER
	 ,AUTOCHARGE_TYPE                                    NUMBER
	 ,ATTRIBUTE_CATEGORY                                 VARCHAR2(30)
	 ,ATTRIBUTE1                                         VARCHAR2(150)
	 ,ATTRIBUTE2                                         VARCHAR2(150)
	 ,ATTRIBUTE3                                         VARCHAR2(150)
	 ,ATTRIBUTE4                                         VARCHAR2(150)
	 ,ATTRIBUTE5                                         VARCHAR2(150)
	 ,ATTRIBUTE6                                         VARCHAR2(150)
	 ,ATTRIBUTE7                                         VARCHAR2(150)
	 ,ATTRIBUTE8                                         VARCHAR2(150)
	 ,ATTRIBUTE9                                         VARCHAR2(150)
	 ,ATTRIBUTE10                                        VARCHAR2(150)
	 ,ATTRIBUTE11                                        VARCHAR2(150)
	 ,ATTRIBUTE12                                        VARCHAR2(150)
	 ,ATTRIBUTE13                                        VARCHAR2(150)
	 ,ATTRIBUTE14                                        VARCHAR2(150)
	 ,ATTRIBUTE15                                        VARCHAR2(150)
	 ,REQUEST_ID                                         NUMBER
	 ,PROGRAM_APPLICATION_ID                             NUMBER
	 ,PROGRAM_ID                                         NUMBER
	 ,PROGRAM_UPDATE_DATE                                DATE
	 ,ASSEMBLY_ITEM_ID                                   NUMBER
	 ,ALTERNATE_ROUTING_DESIGNATOR                       VARCHAR2(10)
	 ,ORGANIZATION_ID                                    NUMBER
	 ,OPERATION_SEQ_NUM                                  NUMBER
	 ,EFFECTIVITY_DATE                                   DATE
	 ,ROUTING_SEQUENCE_ID                                NUMBER
	 ,ORGANIZATION_CODE                                  VARCHAR2(3)
	 ,ASSEMBLY_ITEM_NUMBER                               VARCHAR2(240)
	 ,RESOURCE_CODE                                      VARCHAR2(10)
	 ,ACTIVITY                                           VARCHAR2(10)
	 ,TRANSACTION_ID                                     NUMBER
	 ,PROCESS_FLAG                                       NUMBER
	 ,TRANSACTION_TYPE                                   VARCHAR2(10)
	 ,NEW_RESOURCE_SEQ_NUM                               NUMBER
	 ,OPERATION_TYPE                                     NUMBER
	 ,PRINCIPLE_FLAG                                     NUMBER
	 ,SCHEDULE_SEQ_NUM                                   NUMBER
	 ,ORIGINAL_SYSTEM_REFERENCE                          VARCHAR2(50)
	 ,SETUP_CODE                                         VARCHAR2(30)
	 ,ECO_NAME                                           VARCHAR2(10)
	 ,NEW_ROUTING_REVISION                               VARCHAR2(3)
	 ,ACD_TYPE                                           NUMBER
	 ,ENG_CHANGES_IFCE_KEY                               VARCHAR2(30)
	 ,ENG_REVISED_ITEMS_IFCE_KEY                         VARCHAR2(30)
	 ,BOM_REV_OP_IFCE_KEY                                VARCHAR2(30)
	 ,BOM_REV_OP_RES_IFCE_KEY                            VARCHAR2(30)
	 ,NEW_REVISED_ITEM_REVISION                          VARCHAR2(3)
	 ,SUBSTITUTE_GROUP_NUM                               NUMBER
	 ,BATCH_ID                                           VARCHAR2(200)
	 ,ERROR_CODE					     VARCHAR2(240)
	 ,ERROR_TYPE					     NUMBER
	 ,ERROR_EXPLANATION				     VARCHAR2(240)
	 ,ERROR_FLAG					     VARCHAR2(1)
	 ,PROCESS_CODE					     VARCHAR2(100)
	 ,ERROR_MESG					     VARCHAR2(2000)
	 ,RECORD_NUMBER					     NUMBER
   );

  -- Operation Resource Staging Table Type
  TYPE g_xx_op_res_tab_type IS TABLE OF G_XX_OP_RES_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

   --Added as per Wave2
  -- Operation Network Staging Record Type
  TYPE G_XX_OP_NTWRK_STG_REC_TYPE  IS RECORD
    (
      BATCH_ID	                   VARCHAR2(240),
      RECORD_NUMBER	                   NUMBER,
      SOURCE_SYSTEM_NAME                 VARCHAR2(60),
      FROM_OP_SEQ_ID                     NUMBER        ,
      TO_OP_SEQ_ID                       NUMBER        ,
      TRANSITION_TYPE                    NUMBER        ,
      PLANNING_PCT                       NUMBER        ,
      OPERATION_TYPE                     NUMBER        ,
      LAST_UPDATE_DATE                   DATE          ,
      LAST_UPDATED_BY                    NUMBER        ,
      CREATION_DATE                      DATE          ,
      CREATED_BY                         NUMBER        ,
      LAST_UPDATE_LOGIN                  NUMBER        ,
      ATTRIBUTE_CATEGORY                 VARCHAR2(30)  ,
      ATTRIBUTE1                         VARCHAR2(150) ,
      ATTRIBUTE2                         VARCHAR2(150) ,
      ATTRIBUTE3                         VARCHAR2(150) ,
      ATTRIBUTE4                         VARCHAR2(150) ,
      ATTRIBUTE5                         VARCHAR2(150) ,
      ATTRIBUTE6                         VARCHAR2(150) ,
      ATTRIBUTE7                         VARCHAR2(150) ,
      ATTRIBUTE8                         VARCHAR2(150) ,
      ATTRIBUTE9                         VARCHAR2(150) ,
      ATTRIBUTE10                        VARCHAR2(150) ,
      ATTRIBUTE11                        VARCHAR2(150) ,
      ATTRIBUTE12                        VARCHAR2(150) ,
      ATTRIBUTE13                        VARCHAR2(150) ,
      ATTRIBUTE14                        VARCHAR2(150) ,
      ATTRIBUTE15                        VARCHAR2(150) ,
      FROM_X_COORDINATE                  NUMBER        ,
      TO_X_COORDINATE                    NUMBER        ,
      FROM_Y_COORDINATE                  NUMBER        ,
      TO_Y_COORDINATE                    NUMBER        ,
      FROM_OP_SEQ_NUMBER                 NUMBER        ,
      TO_OP_SEQ_NUMBER                   NUMBER        ,
      FROM_START_EFFECTIVE_DATE          DATE          ,
      TO_START_EFFECTIVE_DATE            DATE          ,
      PROGRAM_APPLICATION_ID             NUMBER        ,
      PROGRAM_ID                         NUMBER        ,
      PROGRAM_UPDATE_DATE                DATE          ,
      NEW_FROM_OP_SEQ_NUMBER             NUMBER        ,
      NEW_TO_OP_SEQ_NUMBER               NUMBER        ,
      NEW_FROM_START_EFFECTIVE_DATE      DATE          ,
      NEW_TO_START_EFFECTIVE_DATE        DATE          ,
      ASSEMBLY_ITEM_ID                   NUMBER        ,
      ALTERNATE_ROUTING_DESIGNATOR       VARCHAR2(10)  ,
      ORGANIZATION_ID                    NUMBER        ,
      ROUTING_SEQUENCE_ID                NUMBER        ,
      ORGANIZATION_CODE                  VARCHAR2(3)   ,
      ASSEMBLY_ITEM_NUMBER               VARCHAR2(240) ,
      ORIGINAL_SYSTEM_REFERENCE          VARCHAR2(50)  ,
      TRANSACTION_ID                     NUMBER        ,
      PROCESS_FLAG                       NUMBER        ,
      TRANSACTION_TYPE                   VARCHAR2(10)  ,
      REQUEST_ID                         NUMBER        ,
      PROCESS_CODE		         VARCHAR2(100) ,
      ERROR_CODE		         VARCHAR2(240) ,
      ERROR_MESG                         VARCHAR2(2000)
   );

  -- Operation Network Staging Table Type
  TYPE g_xx_op_ntwrk_stg_tab_type IS TABLE OF G_XX_OP_NTWRK_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

   PROCEDURE main(x_errbuf   OUT VARCHAR2
		    ,x_retcode  OUT VARCHAR2
		    ,p_batch_id      IN  VARCHAR2
		    ,p_restart_flag  IN  VARCHAR2
		    ,p_validate_and_load     IN VARCHAR2
                    ,p_transaction_type IN VARCHAR2);

END xx_bom_rtg_cnv_pkg;
/


GRANT EXECUTE ON APPS.XX_BOM_RTG_CNV_PKG TO INTG_XX_NONHR_RO;
