DROP PACKAGE APPS.XX_INV_ITEM_ATTR_UPD_PKG;

CREATE OR REPLACE PACKAGE APPS.xx_inv_item_attr_upd_pkg AUTHID CURRENT_USER AS
  /* $Header: XXINVITEMATTRUPDEXT.pks 1.0.0 2012/05/04 00:00:00 ibm noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 04-May-2012
  -- Filename       : XXINVITEMATTRUPDEXT.pks
  -- Description    : Package spec for Item attributes update

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 04-May-2012   1.0       Partha S Mohanty    Initial development.
  -- 31-Mar-2015   1.1       Dharanidharan       Code Changes for FS4.0
--====================================================================================

   -- Global Variables
    G_STAGE			           VARCHAR2(2000);
    G_MAST_BATCH_ID        VARCHAR2(200);
    G_ORG_BATCH_ID		     VARCHAR2(200);
    G_ASSGN_BATCH_ID       VARCHAR2(200);
    G_VALIDATE_AND_LOAD	   VARCHAR2(100):= 'VALIDATE_AND_LOAD';
    G_BOM_TRANSACTION_TYPE VARCHAR2(100):= NULL;
    G_TRANS_TYPE_MAST      VARCHAR2(10):= 'UPDATE';
    G_TRANS_TYPE_ORG       VARCHAR2(10):= 'UPDATE';
    G_TRANS_TYPE_ASSGN     VARCHAR2(10):= 'CREATE';
    G_SET_PROCESS_ID       NUMBER := NULL;
    G_SET_PROCESS_ID_ORG    NUMBER := NULL;
    G_SET_PROCESS_ID_ASSGN  NUMBER := NULL;

    G_HEAD_DEL_GRP         VARCHAR2(10):= NULL;
    G_COMP_DEL_GRP         VARCHAR2(10):= NULL;

    G_PROCESS_FLAG         NUMBER := 1;
    G_API_NAME             VARCHAR2(2000);
    G_PROCESS_NAME         VARCHAR2(50):= 'XXINVITEMATTRUPDEXT';

    G_YES                  VARCHAR2(1) := 'Y';
    G_NO                   VARCHAR2(1) := 'N';

 TYPE G_XX_ITEM_MAST_STG_REC_TYPE  IS RECORD
   (
     ITEM_NUMBER                      VARCHAR2(40)
    ,ATP_RULE                         VARCHAR2(240)
    ,CHECK_ATP                        VARCHAR2(240)    -- Custom Column
    ,COLLATERAL_ITEM                  VARCHAR2(10)    -- Custom Column
    ,CONTAINER                        VARCHAR2(10)    -- Custom Column
    ,DEFAULT_LOT_STATUS               VARCHAR2(240)  -- Custom Column
    ,DEFAULT_SERIAL_STATUS            VARCHAR2(240)  -- Custom Column
    ,DEFAULT_SHIPPING_ORGANIZATION    VARCHAR2(240)
    ,DIMENSION_UNIT_OF_MEASURE        VARCHAR2(240)  -- Custom Column
    ,HAZARD_CLASS                     VARCHAR2(240)  -- Custom Column
    ,HEIGHT                           NUMBER
    ,ITEM_INSTANCE_CLASS              VARCHAR2(30)   -- Custom Column
    ,LENGTH                           NUMBER
    ,LONG_DESCRIPTION                 VARCHAR2(2000)
    ,LOT_STATUS_ENABLED               VARCHAR2(10)
    ,MINIMUM_LICENSE_QUANTITY         NUMBER
    ,ORDERABLE_ON_THE_WEB             VARCHAR2(10)
    ,OUTSIDE_PROCESSING_ITEM          VARCHAR2(10)    -- Custom Column
    ,OUTSIDE_PROCESSING_UNIT_TYPE     VARCHAR2(240)  -- Custom Column
    ,SERIAL_STATUS_ENABLED            VARCHAR2(10)
    ,TRACK_IN_INSTALLED_BASE          VARCHAR2(10)    -- Custom Column
    ,UNIT_VOLUME                      NUMBER
    ,UNIT_WEIGHT                      NUMBER
    ,USE_APPROVED_SUPPLIER            VARCHAR2(10)    -- Custom Column
    ,VEHICLE                          VARCHAR2(10)
    ,VOLUME_UNIT_OF_MEASURE           VARCHAR2(240)  -- Custom Column
    ,WEB_STATUS                       VARCHAR2(30)
    ,WEIGHT_UNIT_OF_MEASURE           VARCHAR2(240)  -- Custom Column
    ,UNIT_WIDTH                       NUMBER
    ,GLOBAL_ATTRIBUTE_CATEGORY        VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE1                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE2                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE3                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE4                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE5                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE6                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE7                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE8                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE9                VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE10               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE11               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE12               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE13               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE14               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE15               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE16               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE17               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE18               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE19               VARCHAR2(150)
    ,GLOBAL_ATTRIBUTE20               VARCHAR2(150)
    ,ATTRIBUTE_CATEGORY               VARCHAR2(30)
    ,ATTRIBUTE1                       VARCHAR2(240)
    ,ATTRIBUTE2                       VARCHAR2(240)
    ,ATTRIBUTE3                       VARCHAR2(240)
    ,ATTRIBUTE4                       VARCHAR2(240)
    ,ATTRIBUTE5                       VARCHAR2(240)
    ,ATTRIBUTE6                       VARCHAR2(240)
    ,ATTRIBUTE7                       VARCHAR2(240)
    ,ATTRIBUTE8                       VARCHAR2(240)
    ,ATTRIBUTE9                       VARCHAR2(240)
    ,ATTRIBUTE10                      VARCHAR2(240)
    ,ATTRIBUTE11                      VARCHAR2(240)
    ,ATTRIBUTE12                      VARCHAR2(240)
    ,ATTRIBUTE13                      VARCHAR2(240)
    ,ATTRIBUTE14                      VARCHAR2(240)
    ,ATTRIBUTE15                      VARCHAR2(240)
    ,ATTRIBUTE16                      VARCHAR2(240)
    ,ATTRIBUTE17                      VARCHAR2(240)
    ,ATTRIBUTE18                      VARCHAR2(240)
    ,ATTRIBUTE19                      VARCHAR2(240)
    ,ATTRIBUTE20                      VARCHAR2(240)
    ,ATTRIBUTE21                      VARCHAR2(240)
    ,ATTRIBUTE22                      VARCHAR2(240)
    ,ATTRIBUTE23                      VARCHAR2(240)
    ,ATTRIBUTE24                      VARCHAR2(240)
    ,ATTRIBUTE25                      VARCHAR2(240)
    ,ATTRIBUTE26                      VARCHAR2(240)
    ,ATTRIBUTE27                      VARCHAR2(240)
    ,ATTRIBUTE28                      VARCHAR2(240)
    ,ATTRIBUTE29                      VARCHAR2(240)
    ,ATTRIBUTE30                      VARCHAR2(240)
    ,LOT_DIVISIBLE                    VARCHAR2(10)    -- Added on 17_Jul_2012 for FS1.1
    ,INVENTORY_ITEM_STATUS_CODE       VARCHAR2(10)
    ,LOT_CONTROL                      VARCHAR2(240)    -- Custom Column Added for WAVE1
    ,LOT_EXPIRATION                   VARCHAR2(240)    -- Custom Column Added for WAVE1
    ,SHELF_LIFE_DAYS                  NUMBER           -- Added for WAVE1
    ,SERIAL_NUMBER_GENERATION         VARCHAR2(240)    -- Custom Column Added for WAVE1
    ,PURCHASING_ENABLED_FLAG          VARCHAR2(5)      -- Added for WAVE1
    ,REPLENISH_TO_ORDER_FLAG          VARCHAR2(5)     -- ASSEMBLE_TO_ORDER_FLAG   Added for WAVE1
    ,BUILD_IN_WIP_FLAG                VARCHAR2(5)      -- Added for WAVE1
    ,BUYER                            VARCHAR2(240)    -- New Added for WAVE1
    ,LIST_PRICE                       NUMBER           -- New Added for WAVE1
    ,RECEIPT_ROUTING                  VARCHAR2(50)     -- New Added for WAVE1
    ,ITEM_TYPE	                      VARCHAR2(30)     -- New Added for WAVE1
    ,POSTPROCESSING_LEAD_TIME         NUMBER           -- New Added for WAVE1
    ,PREPROCESSING_LEAD_TIME          NUMBER           -- New Added for WAVE1
    ,FULL_LEAD_TIME                   NUMBER           -- New Added for WAVE1
    ,ENG_ITEM_FLAG	                  VARCHAR2(5)      -- New Added for WAVE1
    ,PURCHASING_ITEM_FLAG             VARCHAR2(5)      -- New Added for WAVE1
    ,CUSTOMER_ORDER_FLAG              VARCHAR2(5)      -- New Added for WAVE1
    ,CUSTOMER_ORDER_ENABLED_FLAG      VARCHAR2(5)      -- New Added for WAVE1
    ,WIP_SUPPLY_TYPE                  VARCHAR2(25)      -- New Added for WAVE1
    ,INVENTORY_ITEM_ID                NUMBER          -- Derived columns Starts -- ITEM_NUMBER
    ,ATP_RULE_ID                      NUMBER          -- ATP_RULE
    ,DEFAULT_LOT_STATUS_ID            NUMBER          -- DEFAULT_LOT_STATUS
    ,DEFAULT_SERIAL_STATUS_ID         NUMBER          -- DEFAULT_SERIAL_STATUS
    ,DIMENSION_UOM_CODE               VARCHAR2(3)     -- DIMENSION_UNIT_OF_MEASURE
    ,HAZARD_CLASS_ID                  NUMBER          -- HAZARD_CLASS
    ,IB_ITEM_INSTANCE_CLASS           VARCHAR2(30)    -- ITEM_INSTANCE_CLASS
    ,COMMS_NL_TRACKABLE_FLAG	        VARCHAR2(1)     -- TRACK_IN_INSTALLED_BASE
    ,MUST_USE_APPROVED_VENDOR_FLAG    VARCHAR2(1)     -- USE_APPROVED_SUPPLIER
    ,OUTSIDE_OPERATION_FLAG           VARCHAR2(1)     -- OUTSIDE_PROCESSING_ITEM
    ,OUTSIDE_OPERATION_UOM_TYPE       VARCHAR2(25)    -- OUTSIDE_PROCESSING_UNIT_TYPE
    ,COLLATERAL_FLAG                  VARCHAR2(1)     -- COLLATERAL_ITEM
    ,CONTAINER_ITEM_FLAG	            VARCHAR2(1)     -- CONTAINER
    ,ATP_FLAG                         VARCHAR2(1)     -- CHECK_ATP
    ,VEHICLE_ITEM_FLAG                VARCHAR2(1)     -- VEHICLE
    ,WEIGHT_UOM_CODE                  VARCHAR2(3)     -- WEIGHT_UNIT_OF_MEASURE
    ,DEFAULT_SHIPPING_ORG             NUMBER          -- DEFAULT_SHIPPING_ORGANIZATION
    ,UNIT_HEIGHT                      NUMBER          -- HEIGHT
    ,UNIT_LENGTH                      NUMBER          -- LENGTH
    ,ORDERABLE_ON_WEB_FLAG            VARCHAR2(1)     -- ORDERABLE_ON_THE_WEB
    ,LOT_DIVISIBLE_FLAG               VARCHAR2(1)     -- LOT_DIVISIBLE
    ,ORGANIZATION_CODE                VARCHAR2(50)
    ,INV_ITEM_STATUS_CODE_ORIG        VARCHAR2(10)    -- INVENTORY_ITEM_STATUS_CODE  New Added for WAVE1
    ,LOT_CONTROL_CODE                 NUMBER          -- LOT_CONTROL    Added for WAVE1
    ,SHELF_LIFE_CODE                  NUMBER          -- LOT_EXPIRATION Added for WAVE1
    ,SERIAL_NUMBER_CONTROL_CODE       NUMBER          -- SERIAL_NUMBER_GENERATION Added for WAVE1
    ,BUYER_ID                         NUMBER          -- BUYER New Add for WAVE1
    ,LIST_PRICE_PER_UNIT              NUMBER          -- LIST_PRICE  New Add for WAVE1
    ,RECEIVING_ROUTING_ID             NUMBER          -- RECEIPT_ROUTING New Add for WAVE1
    ,ITEM_TYPE_ORIG                   VARCHAR2(30)    -- ITEM_TYPE New Added for WAVE1
    ,WIP_SUPPLY_TYPE_ORIG             NUMBER          -- WIP_SUPPLY_TYPE New Added for WAVE1
    ,VOLUME_UOM_CODE                  VARCHAR2(3)     -- Derived columns Ends -- VOLUME_UNIT_OF_MEASURE
    ,ORGANIZATION_ID                  NUMBER          -- Mandatory columns Starts
    ,PROCESS_FLAG                     NUMBER
    ,TRANSACTION_TYPE                 VARCHAR2(10)
    ,SET_PROCESS_ID                   NUMBER         -- Mandatory columns Ends
    ,CREATED_BY                       NUMBER
    ,CREATION_DATE                    DATE             -- WHO Columns Starts
    ,LAST_UPDATED_BY                  NUMBER
    ,LAST_UPDATE_DATE                 DATE
    ,LAST_UPDATE_LOGIN                NUMBER           -- WHO Columns Ends
    ,REQUEST_ID                       NUMBER
    ,PROCESS_CODE                     VARCHAR2(100)    -- Custom Coumns
    ,ERROR_CODE                       VARCHAR2(100)    -- Custom Coumns
    ,ERROR_MESG                       VARCHAR2(2000)   -- Custom Coumns
    ,SOURCE_SYSTEM_NAME		  VARCHAR2(100 BYTE) -- Custom Coumns
    ,RECORD_NUMBER                    NUMBER           -- Custom Coumns
    ,BATCH_ID                         VARCHAR2(200)    -- Custom Coumns
    ,SERVICEABLE_PRODUCT_FLAG	      VARCHAR2(1)
    ,SERV_REQ_ENABLED_CODE	      VARCHAR2(30)
    ,SERV_BILLING_ENABLED_FLAG	      VARCHAR2(1)
    ,MATERIAL_BILLABLE_FLAG	      VARCHAR2(30)
  );


TYPE g_xx_item_mast_tab_type IS TABLE OF G_XX_ITEM_MAST_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;


  TYPE G_XX_ITEM_ORG_STG_REC_TYPE  IS RECORD
  (
     ITEM_NUMBER                    VARCHAR2(40)
    ,ORGANIZATION_CODE              VARCHAR2(50)
    ,ASSET_CATEGORY                 VARCHAR2(240)
    ,CALCULATE_ATP                  VARCHAR2(10)
    ,CONTAINER_TYPE                 VARCHAR2(30)
    ,CREATE_FIXED_ASSET             VARCHAR2(30)
    ,DEMAND_TIME_FENCE              VARCHAR2(240)
    ,DEMAND_TIME_FENCE_DAYS         NUMBER
    ,EQUIPMENT                      VARCHAR2(10)
    ,EXCLUDE_FROM_BUDGET            VARCHAR2(10)
    ,EXPENSE_ACCOUNT                VARCHAR2(240)
    ,FIXED_DAYS_SUPPLY              NUMBER
    ,FIXED_LEAD_TIME                NUMBER
    ,FIXED_LOT_MULTIPLIER           NUMBER
    ,FIXED_ORDER_QUANTITY           NUMBER
    ,INPUT_TAX_CLASSIFICATION_CODE  VARCHAR2(50)
    ,INTERNAL_VOLUME                NUMBER
    ,INVENTORY_PLANNING_METHOD      VARCHAR2(240)
    ,LIST_PRICE                     NUMBER
    ,MAKE_OR_BUY                    VARCHAR2(20)
    ,MAXIMUM_LOAD_WEIGHT            NUMBER
    ,MAXIMUM_ORDER_QUANTITY         NUMBER
    ,MINIMUM_FILL_PERCENT           NUMBER
    ,MINIMUM_ORDER_QUANTITY         NUMBER
    ,MIN_MAX_MAXIMUM_QUANTITY       NUMBER
    ,MIN_MAX_MINIMUM_QUANTITY       NUMBER
    ,OM_INDIVISIBLE                 VARCHAR2(10)
    ,PLANNED_INVENTORY_POINT        VARCHAR2(10)
    ,PLANNER                        VARCHAR2(240)
    ,PLANNING_TIME_FENCE            VARCHAR2(240)
    ,PLANNING_TIME_FENCE_DAYS       NUMBER
    ,POSTPROCESSING_LEAD_TIME       NUMBER
    ,PREPROCESSING_LEAD_TIME        NUMBER
    ,PROCESSING_LEAD_TIME           NUMBER
    ,RELEASE_TIME_FENCE             VARCHAR2(240)
    ,RELEASE_TIME_FENCE_DAYS        NUMBER
    ,SALES_ACCOUNT                  VARCHAR2(240)
    ,SOURCE_ORGANIZATION            VARCHAR2(50)
    ,SOURCE_SUBINVENTORY            VARCHAR2(10)
    ,SOURCE_TYPE                    VARCHAR2(240)
    ,SUBSTITUTION_WINDOW            VARCHAR2(240)
    ,SUBSTITUTION_WINDOWS_DAYS      NUMBER
    ,TAXABLE                        VARCHAR2(10)
    ,RECEIPT_ROUTING                VARCHAR2(50)     -- Added on 17_Jul_2012 for FS1.1
    ,OUTSIDE_PROCESSING_ITEM        VARCHAR2(10)     -- Added on 17_Jul_2012 for FS1.1
    ,OUTSIDE_PROCESSING_UNIT_TYPE   VARCHAR2(240)    -- Added on 17_Jul_2012 for FS1.1
    ,BUYER                          VARCHAR2(240)    -- Added on 17_Jul_2012 for FS1.1
    ,ATTRIBUTE29                    VARCHAR2(240)    -- Used for batch_id
    ,CUSTOMER_ORDER_FLAG            VARCHAR2(5)      -- Added for WAVE1
    ,PURCHASING_ITEM_FLAG           VARCHAR2(5)      -- Added for WAVE1
    ,BUILD_IN_WIP_FLAG              VARCHAR2(5)      -- Added for WAVE1
    ,PLANNING_EXCEPTION_SET	        VARCHAR2(10)     -- New Added for WAVE1
    ,ATP_FLAG                       VARCHAR2(240)    -- New Added for WAVE1
    ,ATP_RULE                       VARCHAR2(240)    -- New Added for WAVE1
    ,ATP_COMPONENTS_FLAG            VARCHAR2(240)    -- New Added for WAVE1
    ,SHIP_MODEL_COMPLETE_FLAG	      VARCHAR2(5)      -- New Added for WAVE1
    ,PICK_COMPONENTS_FLAG	          VARCHAR2(5)      -- New Added for WAVE1
    ,DEFAULT_SHIPPING_ORG	          VARCHAR2(240)    -- New Added for WAVE1
    ,INVENTORY_ITEM_STATUS_CODE     VARCHAR2(10)     -- New Added for WAVE1
    ,INVENTORY_ITEM_FLAG            VARCHAR2(5)      -- New Added for WAVE1
    ,STOCK_ENABLED_FLAG	            VARCHAR2(5)      -- New Added for WAVE1
    ,MTL_TRANSACTIONS_ENABLED_FLAG	VARCHAR2(5)      -- New Added for WAVE1
    ,LOT_CONTROL_CODE               VARCHAR2(240)    -- New Added for WAVE1
    ,AUTO_LOT_ALPHA_PREFIX	        VARCHAR2(30)     -- New Added for WAVE1
    ,START_AUTO_LOT_NUMBER	        VARCHAR2(30)     -- New Added for WAVE1
    ,SHELF_LIFE_CODE                VARCHAR2(240)    -- New Added for WAVE1
    ,SHELF_LIFE_DAYS                NUMBER           -- New Added for WAVE1
    ,RESERVABLE_TYPE	              VARCHAR2(5)      -- New Added for WAVE1
    ,LOT_STATUS_ENABLED             VARCHAR2(10)     -- New Added for WAVE1
    ,DEFAULT_LOT_STATUS             VARCHAR2(240)    -- New Added for WAVE1
    ,LOT_DIVISIBLE_FLAG             VARCHAR2(5)      -- New Added for WAVE1
    ,LOT_SPLIT_ENABLED	            VARCHAR2(5)      -- New Added for WAVE1
    ,LOT_MERGE_ENABLED	            VARCHAR2(5)      -- New Added for WAVE1
    ,LOT_TRANSLATE_ENABLED                   VARCHAR2(1)   -- New Added on  31-Mar-2015 for FS V4.0
    ,LOT_SUBSTITUTION_ENABLED             VARCHAR2(1)     -- New Added on  31-Mar-2015 for FS V4.0
    ,SERIAL_NUMBER_CONTROL_CODE     VARCHAR2(240)    -- New Added for WAVE1
    ,AUTO_SERIAL_ALPHA_PREFIX	      VARCHAR2(30)     -- New Added for WAVE1
    ,START_AUTO_SERIAL_NUMBER	      VARCHAR2(30)     -- New Added for WAVE1
    ,SERIAL_STATUS_ENABLED          VARCHAR2(5)      -- New Added for WAVE1
    ,DEFAULT_SERIAL_STATUS          VARCHAR2(240)    -- New Added for WAVE1
    ,DEFAULT_SO_SOURCE_TYPE	        VARCHAR2(30)     -- New Added for WAVE1
    ,RETURNABLE_FLAG	              VARCHAR2(5)      -- New Added for WAVE1
    ,RETURN_INSPECTION_REQUIREMENT	VARCHAR2(5)      -- New Added for WAVE1
    ,BULK_PICKED_FLAG	              VARCHAR2(5)      -- New Added for WAVE1
    ,BOM_ENABLED_FLAG	              VARCHAR2(5)      -- New Added for WAVE1
    ,PURCHASING_ENABLED_FLAG        VARCHAR2(5)      -- New Added for WAVE1
    ,CUSTOMER_ORDER_ENABLED_FLAG    VARCHAR2(5)      -- New Added for WAVE1
    ,REPLENISH_TO_ORDER_FLAG        VARCHAR2(1)      -- New Added for WAVE1
    ,WIP_SUPPLY_TYPE                VARCHAR2(25)     -- New Added for WAVE1
    ,INVENTORY_ITEM_ID              NUMBER   -- Derived columns starts -- ITEM_NUMBER
    ,ASSET_CATEGORY_ID              NUMBER                          -- ASSET_CATEGORY
    ,MRP_CALCULATE_ATP_FLAG         VARCHAR2(1)                     -- CALCULATE_ATP
    ,CONTAINER_TYPE_CODE            VARCHAR2(30)                    -- CONTAINER_TYPE
    ,ASSET_CREATION_CODE            VARCHAR2(30)                    -- CREATE_FIXED_ASSET
    ,DEMAND_TIME_FENCE_CODE         NUMBER                          -- DEMAND_TIME_FENCE
    ,EQUIPMENT_TYPE                 NUMBER                          -- EQUIPMENT
    ,EXCLUDE_FROM_BUDGET_FLAG       NUMBER                          -- EXCLUDE_FROM_BUDGET
    ,EXPENSE_ACCOUNT_CCID           NUMBER                          -- EXPENSE_ACCOUNT
    ,PURCHASING_TAX_CODE            VARCHAR2(50)                    -- INPUT_TAX_CLASSIFICATION_CODE
    ,INVENTORY_PLANNING_CODE        NUMBER                          -- INVENTORY_PLANNING_METHOD
    ,PLANNING_MAKE_BUY_CODE         NUMBER                          -- MAKE_OR_BUY
    ,INDIVISIBLE_FLAG               VARCHAR2(1)                     -- OM_INDIVISIBLE
    ,PLANNED_INV_POINT_FLAG         VARCHAR2(1)                     -- PLANNED_INVENTORY_POINT
    ,PLANNER_CODE                   VARCHAR2(10)                    -- PLANNER
    ,PLANNING_TIME_FENCE_CODE       NUMBER                          -- PLANNING_TIME_FENCE
    ,FULL_LEAD_TIME                 NUMBER                          -- PROCESSING_LEAD_TIME
    ,RELEASE_TIME_FENCE_CODE        NUMBER                          -- RELEASE_TIME_FENCE
    ,SALES_ACCOUNT_CCID             NUMBER                          -- SALES_ACCOUNT
    ,SOURCE_ORGANIZATION_ID         NUMBER                          -- SOURCE_ORGANIZATION
    ,SOURCE_TYPE_CODE               NUMBER                          -- SOURCE_TYPE
    ,MAX_MINMAX_QUANTITY            NUMBER                          -- MIN_MAX_MAXIMUM_QUANTITY
    ,MIN_MINMAX_QUANTITY            NUMBER                          -- MIN_MAX_MINIMUM_QUANTITY
    ,LIST_PRICE_PER_UNIT            NUMBER                          -- LIST_PRICE
    ,TAXABLE_FLAG                   VARCHAR2(1)                     -- TAXABLE
    ,RECEIVING_ROUTING_ID           NUMBER                          -- RECEIPT_ROUTING
    ,OUTSIDE_OPERATION_FLAG         VARCHAR2(1)                     -- OUTSIDE_PROCESSING_ITEM
    ,OUTSIDE_OPERATION_UOM_TYPE     VARCHAR2(25)                    -- OUTSIDE_PROCESSING_UNIT_TYPE
    ,BUYER_ID                       NUMBER                          -- BUYER
    ,SHELF_LIFE_CODE_ORIG           NUMBER                          -- LOT_EXPIRATION Added for WAVE1
    ,ATP_FLAG_ORIG                  VARCHAR2(1)                     -- ATP_FLAG New Added for WAVE1
    ,ATP_RULE_ID                    NUMBER                          -- ATP_RULE New Added for WAVE1
    ,ATP_COMPONENTS_FLAG_ORIG       VARCHAR2(1)                     -- ATP_COMPONENTS_FLAG New Added for WAVE1
    ,DEFAULT_SHIPPING_ORG_ORIG      NUMBER                          -- DEFAULT_SHIPPING_ORG New Added for WAVE1
    ,INV_ITEM_STATUS_CODE_ORIG      VARCHAR2(10)                    -- INVENTORY_ITEM_STATUS_CODE  New Added for WAVE1
    ,LOT_CONTROL_CODE_ORIG          NUMBER                          -- LOT_CONTROL_CODE    New Added for WAVE1
    ,RESERVABLE_TYPE_ORIG           NUMBER                          -- RESERVABLE_TYPE     New Added for WAVE1
    ,DEFAULT_LOT_STATUS_ID          NUMBER                          -- DEFAULT_LOT_STATUS  New Added for WAVE1
    ,SERIAL_NUMBER_CTRL_CODE_ORIG   NUMBER                          -- SERIAL_NUMBER_CONTROL_CODE New Added for WAVE1
    ,DEFAULT_SERIAL_STATUS_ID       NUMBER                          -- DEFAULT_SERIAL_STATUS New Added for WAVE1
    ,RETURN_INSPECT_REQ_ORIG	      VARCHAR2(5)                     -- RETURN_INSPECTION_REQUIREMENT New Added for WAVE1
    ,WIP_SUPPLY_TYPE_ORIG           NUMBER                          -- WIP_SUPPLY_TYPE New Added for WAVE1
    ,SUBSTITUTION_WINDOW_CODE       NUMBER          -- Derived columns ends -- SUBSTITUTION_WINDOW
    ,ORGANIZATION_ID                NUMBER          -- Mandatory Columns Starts -- ORGANIZATION_CODE
    ,PROCESS_FLAG                   NUMBER
    ,TRANSACTION_TYPE               VARCHAR2(10)
    ,SET_PROCESS_ID                 NUMBER          -- Mandatory Columns Ends
    ,CREATED_BY                     NUMBER          -- WHO Columns Starts
    ,CREATION_DATE                  DATE
    ,LAST_UPDATED_BY                NUMBER
    ,LAST_UPDATE_DATE               DATE
    ,LAST_UPDATE_LOGIN              NUMBER           -- WHO Columns Ends
    ,REQUEST_ID                     NUMBER
    ,PROCESS_CODE                   VARCHAR2(100)         -- Custom Coumns
    ,ERROR_CODE                     VARCHAR2(100)         -- Custom Coumns
    ,ERROR_MESG                     VARCHAR2(2000)        -- Custom Coumns
    ,SOURCE_SYSTEM_NAME		VARCHAR2(100 BYTE)    -- Custom Coumns
    ,RECORD_NUMBER                  NUMBER                -- Custom Coumns
    ,BATCH_ID                       VARCHAR2(200)         -- Custom Coumns
    );



  TYPE g_xx_item_org_tab_type IS TABLE OF G_XX_ITEM_ORG_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;


 TYPE G_XX_ITEM_ASSGN_STG_REC_TYPE  IS RECORD
  (
     ITEM_NUMBER                    VARCHAR2(40)
    ,ORGANIZATION_CODE              VARCHAR2(50)
    ,ATTRIBUTE28                    VARCHAR2(240) -- Used for storing batch id
    ,INVENTORY_ITEM_ID              NUMBER   -- Derived columns starts -- ITEM_NUMBER
    ,ORGANIZATION_ID                NUMBER          -- Mandatory Columns Starts -- ORGANIZATION_CODE
    ,PROCESS_FLAG                   NUMBER
    ,TRANSACTION_TYPE               VARCHAR2(10)
    ,SET_PROCESS_ID                 NUMBER          -- Mandatory Columns Ends
    ,CREATED_BY                     NUMBER          -- WHO Columns Starts
    ,CREATION_DATE                  DATE
    ,LAST_UPDATED_BY                NUMBER
    ,LAST_UPDATE_DATE               DATE
    ,LAST_UPDATE_LOGIN              NUMBER           -- WHO Columns Ends
    ,REQUEST_ID                       NUMBER
    ,PROCESS_CODE                   VARCHAR2(100)         -- Custom Coumns
    ,ERROR_CODE                     VARCHAR2(100)         -- Custom Coumns
    ,ERROR_MESG                     VARCHAR2(2000)        -- Custom Coumns
    ,SOURCE_SYSTEM_NAME	            VARCHAR2(100)
    ,RECORD_NUMBER                  NUMBER                -- Custom Coumns
    ,BATCH_ID                       VARCHAR2(200)         -- Custom Coumns
    );

 TYPE g_xx_item_assgn_tab_type IS TABLE OF G_XX_ITEM_ASSGN_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;


 PROCEDURE main( errbuf   OUT VARCHAR2
                                ,retcode                OUT VARCHAR2
                                ,p_batch_id             IN  VARCHAR2
                                ,p_org_batch_id	        IN VARCHAR2
                                ,p_restart_flag         IN  VARCHAR2
                                ,p_validate_and_load    IN VARCHAR2
                                ,p_mast_attr_update     IN VARCHAR2
                                ,p_item_assign          IN VARCHAR2
                                ,p_org_attr_update      IN VARCHAR2
                               );

END xx_inv_item_attr_upd_pkg;
/


GRANT EXECUTE ON APPS.XX_INV_ITEM_ATTR_UPD_PKG TO INTG_XX_NONHR_RO;
