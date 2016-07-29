DROP PACKAGE APPS.XX_BOM_IMPORT_PKG;

CREATE OR REPLACE PACKAGE APPS."XX_BOM_IMPORT_PKG" AUTHID CURRENT_USER AS
  /* $Header: XXINTGBOMCNV.pks 1.0.0 2012/03/07 00:00:00 partha noship $ */
--==================================================================================
  -- Created By     : Partha S Mohanty
  -- Creation Date  : 07-MAR-2012
  -- Filename       : XXINTGBOMCNV.pks
  -- Description    : Package body for Bills of Material conversion

  -- Change History:

  -- Date        Version#    Name                Remarks
  -- ----------- --------    ---------------     ------------------------------------
  -- 07-MAR-2012   1.0       Partha S Mohanty    Initial development.
--====================================================================================

   -- Global Variables
    G_STAGE			        VARCHAR2(2000);
    G_BATCH_ID		      VARCHAR2(200);
    G_COMP_BATCH_ID		  VARCHAR2(200);
    G_VALIDATE_AND_LOAD	VARCHAR2(100) := 'VALIDATE_AND_LOAD';
    G_BOM_TRANSACTION_TYPE VARCHAR2(100):= NULL;
    G_TRANS_TYPE_CREATE VARCHAR2(10) := 'CREATE';
    G_TRANS_TYPE_DELETE VARCHAR2(10) := 'DELETE';
    G_PROCESS_NAME      VARCHAR2(100) := 'XXINTGBOMCNV';
    G_HEAD_DEL_GRP      VARCHAR2(10):= NULL;
    G_COMP_DEL_GRP      VARCHAR2(10):= NULL;

    G_PROCESS_FLAG      NUMBER := 1;
    G_API_NAME          VARCHAR2(2000);

 TYPE G_XX_BOM_HEADER_STG_REC_TYPE  IS RECORD
  (
    RECORD_NUMBER                 NUMBER,
    ASSEMBLY_ITEM_ID              NUMBER,
    ORGANIZATION_ID               NUMBER ,
    ALTERNATE_BOM_DESIGNATOR      VARCHAR2(10),
    LAST_UPDATE_DATE              DATE,
    LAST_UPDATED_BY               NUMBER,
    CREATION_DATE                 DATE ,
    CREATED_BY                    NUMBER,
    LAST_UPDATE_LOGIN             NUMBER,
    COMMON_ASSEMBLY_ITEM_ID       NUMBER  ,
    SPECIFIC_ASSEMBLY_COMMENT     VARCHAR2(240),
    PENDING_FROM_ECN              VARCHAR2(10),
    ATTRIBUTE_CATEGORY            VARCHAR2(30),
    ATTRIBUTE1                    VARCHAR2(150),
    ATTRIBUTE2                    VARCHAR2(150),
    ATTRIBUTE3                    VARCHAR2(150),
    ATTRIBUTE4                    VARCHAR2(150),
    ATTRIBUTE5                    VARCHAR2(150),
    ATTRIBUTE6                    VARCHAR2(150),
    ATTRIBUTE7                    VARCHAR2(150),
    ATTRIBUTE8                    VARCHAR2(150),
    ATTRIBUTE9                    VARCHAR2(150),
    ATTRIBUTE10                   VARCHAR2(150),
    ATTRIBUTE11                   VARCHAR2(150),
    ATTRIBUTE12                   VARCHAR2(150),
    ATTRIBUTE13                   VARCHAR2(150),
    ATTRIBUTE14                   VARCHAR2(150),
    ATTRIBUTE15                   VARCHAR2(150),
    ASSEMBLY_TYPE                 NUMBER,
    COMMON_BILL_SEQUENCE_ID       NUMBER,
    BILL_SEQUENCE_ID              NUMBER,
    REQUEST_ID                    NUMBER,
    PROGRAM_APPLICATION_ID        NUMBER,
    PROGRAM_ID                    NUMBER,
    PROGRAM_UPDATE_DATE           DATE,
    DEMAND_SOURCE_LINE            VARCHAR2(30) ,
    SET_ID                        VARCHAR2(10),
    COMMON_ORGANIZATION_ID        NUMBER,
    DEMAND_SOURCE_TYPE            NUMBER,
    DEMAND_SOURCE_HEADER_ID       NUMBER,
    TRANSACTION_ID                NUMBER,
    PROCESS_FLAG                  NUMBER,
    ORGANIZATION_CODE             VARCHAR2(3),
    COMMON_ORG_CODE               VARCHAR2(3),
    ITEM_NUMBER                   VARCHAR2(240),
    COMMON_ITEM_NUMBER            VARCHAR2(240),
    NEXT_EXPLODE_DATE             DATE,
    REVISION                      VARCHAR2(3),
    TRANSACTION_TYPE              VARCHAR2(10),
    DELETE_GROUP_NAME             VARCHAR2(10),
    DG_DESCRIPTION                VARCHAR2(240),
    ORIGINAL_SYSTEM_REFERENCE     VARCHAR2(50),
    IMPLEMENTATION_DATE           DATE,
    OBJ_NAME                      VARCHAR2(30),
    PK1_VALUE                     VARCHAR2(240),
    PK2_VALUE                     VARCHAR2(240),
    PK3_VALUE                     VARCHAR2(240),
    PK4_VALUE                     VARCHAR2(240),
    PK5_VALUE                     VARCHAR2(240),
    STRUCTURE_TYPE_NAME           VARCHAR2(80),
    STRUCTURE_TYPE_ID             NUMBER,
    EFFECTIVITY_CONTROL           NUMBER,
    RETURN_STATUS                 VARCHAR2(1) ,
    IS_PREFERRED                  VARCHAR2(1),
    SOURCE_SYSTEM_REFERENCE       VARCHAR2(240) ,
    SOURCE_SYSTEM_REFERENCE_DESC  VARCHAR2(240),
    BATCH_ID                      VARCHAR2(150),
    CHANGE_ID                     NUMBER,
    CATALOG_CATEGORY_NAME         VARCHAR2(240),
    ITEM_CATALOG_GROUP_ID         NUMBER,
    PRIMARY_UNIT_OF_MEASURE       VARCHAR2(25),
    ITEM_DESCRIPTION              VARCHAR2(240),
    TEMPLATE_NAME                 VARCHAR2(240),
    SOURCE_BILL_SEQUENCE_ID       NUMBER,
    ENABLE_ATTRS_UPDATE           VARCHAR2(1),
    INTERFACE_TABLE_UNIQUE_ID     NUMBER,
    BUNDLE_ID                     NUMBER,
    SOURCE_SYSTEM_NAME            VARCHAR2(60), -- Custom columns (datafile)
    ORGANIZATION_CODE_ORIG        VARCHAR2(3), -- Used to store original ORGANIZATION_CODE from Mapping
    PROCESS_CODE                  VARCHAR2(100),
    ERROR_CODE                    VARCHAR2(100),
    ERROR_MESG                    VARCHAR2(2000)
  );

-- PO Header Level Staging Table Type
TYPE g_xx_bom_hdr_tab_type IS TABLE OF G_XX_BOM_HEADER_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;


  TYPE G_XX_BOM_COMP_STG_REC_TYPE  IS RECORD
  (
    ACD_TYPE												NUMBER,
    ALTERNATE_BOM_DESIGNATOR				VARCHAR2(10),
    ASSEMBLY_ITEM_ID								NUMBER,
    ASSEMBLY_ITEM_NUMBER						VARCHAR2(240),
    ASSEMBLY_TYPE										NUMBER,
    ATTRIBUTE_CATEGORY							VARCHAR2(30),
    ATTRIBUTE1											VARCHAR2(150),
    ATTRIBUTE10											VARCHAR2(150),
    ATTRIBUTE11											VARCHAR2(150),
    ATTRIBUTE12											VARCHAR2(150),
    ATTRIBUTE13											VARCHAR2(150),
    ATTRIBUTE14											VARCHAR2(150),
    ATTRIBUTE15											VARCHAR2(150),
    ATTRIBUTE2											VARCHAR2(150),
    ATTRIBUTE3											VARCHAR2(150),
    ATTRIBUTE4											VARCHAR2(150),
    ATTRIBUTE5											VARCHAR2(150),
    ATTRIBUTE6											VARCHAR2(150),
    ATTRIBUTE7											VARCHAR2(150),
    ATTRIBUTE8											VARCHAR2(150),
    ATTRIBUTE9											VARCHAR2(150),
    AUTO_REQUEST_MATERIAL						VARCHAR2(1),
    BASIS_TYPE											NUMBER,
    BATCH_ID												VARCHAR2(150),
    BILL_SEQUENCE_ID								NUMBER,
    BOM_INVENTORY_COMPS_IFCE_KEY		VARCHAR2(30),
    BOM_ITEM_TYPE										NUMBER,
    BUNDLE_ID												NUMBER,
    CATALOG_CATEGORY_NAME						VARCHAR2(240),
    CHANGE_ID												NUMBER,
    CHANGE_NOTICE										VARCHAR2(10),
    CHANGE_TRANSACTION_TYPE					VARCHAR2(10),
    CHECK_ATP												NUMBER,
    COMMON_COMPONENT_SEQUENCE_ID		NUMBER,
    COMP_SOURCE_SYSTEM_REFER_DESC		VARCHAR2(240),
    COMP_SOURCE_SYSTEM_REFERENCE		VARCHAR2(240),
    COMPONENT_ITEM_ID								NUMBER,
    COMPONENT_ITEM_NUMBER						VARCHAR2(240),
    COMPONENT_QUANTITY							NUMBER,
    COMPONENT_REMARKS								VARCHAR2(240),
    COMPONENT_REVISION_CODE					VARCHAR2(240),
    COMPONENT_REVISION_ID						NUMBER,
    COMPONENT_SEQUENCE_ID						NUMBER,
    COMPONENT_YIELD_FACTOR					NUMBER,
    COST_FACTOR											NUMBER,
    CREATED_BY											NUMBER,
    CREATION_DATE										DATE,
    DDF_CONTEXT1										VARCHAR2(30),
    DDF_CONTEXT2										VARCHAR2(30),
    DELETE_GROUP_NAME								VARCHAR2(10),
    DG_DESCRIPTION									VARCHAR2(240),
    DISABLE_DATE										DATE,
    EFFECTIVITY_DATE								DATE,
    ENFORCE_INT_REQUIREMENTS				VARCHAR2(80),
    ENG_CHANGES_IFCE_KEY						VARCHAR2(30),
    ENG_REVISED_ITEMS_IFCE_KEY			VARCHAR2(30),
    FROM_END_ITEM										VARCHAR2(240),
    FROM_END_ITEM_ID								NUMBER,
    FROM_END_ITEM_MINOR_REV_CODE		VARCHAR2(240),
    FROM_END_ITEM_MINOR_REV_ID			NUMBER,
    FROM_END_ITEM_REV_CODE					VARCHAR2(240),
    FROM_END_ITEM_REV_ID						NUMBER,
    FROM_END_ITEM_UNIT_NUMBER				VARCHAR2(30),
    FROM_MINOR_REVISION_CODE				VARCHAR2(240),
    FROM_MINOR_REVISION_ID					NUMBER,
    FROM_OBJECT_REVISION_CODE				VARCHAR2(80),
    FROM_OBJECT_REVISION_ID					NUMBER,
    HIGH_QUANTITY										NUMBER,
    IMPLEMENTATION_DATE							DATE,
    INCLUDE_IN_COST_ROLLUP					VARCHAR2(3), -- Actually number, changed to varchar2 for datafile
    INCLUDE_ON_BILL_DOCS						NUMBER,
    INCLUDE_ON_SHIP_DOCS						NUMBER,
    INTERFACE_ENTITY_TYPE						VARCHAR2(4),
    INTERFACE_TABLE_UNIQUE_ID				NUMBER,
    INVERSE_QUANTITY								NUMBER,
    ITEM_CATALOG_GROUP_ID						NUMBER,
    ITEM_DESCRIPTION								VARCHAR2(240),
    ITEM_NUM												NUMBER,
    LAST_UPDATE_DATE								DATE,
    LAST_UPDATE_LOGIN								NUMBER,
    LAST_UPDATED_BY									NUMBER,
    LOCATION_NAME										VARCHAR2(81),
    LOW_QUANTITY										NUMBER,
    MODEL_COMP_SEQ_ID								NUMBER,
    MUTUALLY_EXCLUSIVE_OPTIONS			NUMBER,
    NEW_EFFECTIVITY_DATE						DATE,
    NEW_FROM_END_ITEM_UNIT_NUMBER		VARCHAR2(30),
    NEW_OPERATION_SEQ_NUM						NUMBER,
    NEW_REVISED_ITEM_REVISION				VARCHAR2(3),
    OBJ_NAME												VARCHAR2(30),
    OLD_COMPONENT_SEQUENCE_ID				NUMBER,
    OLD_EFFECTIVITY_DATE						DATE,
    OLD_OPERATION_SEQ_NUM						NUMBER,
    OPERATION_LEAD_TIME_PERCENT			NUMBER,
    OPERATION_SEQ_NUM								NUMBER,
    OPTIONAL												NUMBER,
    OPTIONAL_ON_MODEL								NUMBER,
    ORGANIZATION_CODE								VARCHAR2(3),
    ORGANIZATION_ID									NUMBER,
    ORIGINAL_SYSTEM_REFERENCE				VARCHAR2(50),
    PARENT_BILL_SEQ_ID							NUMBER,
    PARENT_REVISION_CODE						VARCHAR2(240),
    PARENT_REVISION_ID							NUMBER,
    PARENT_SOURCE_SYSTEM_REFERENCE	VARCHAR2(240),
    PICK_COMPONENTS									NUMBER,
    PK1_VALUE												VARCHAR2(240),
    PK2_VALUE												VARCHAR2(240),
    PK3_VALUE												VARCHAR2(240),
    PK4_VALUE												VARCHAR2(240),
    PK5_VALUE												VARCHAR2(240),
    PLAN_LEVEL											NUMBER,
    PLANNING_FACTOR									NUMBER,
    PRIMARY_UNIT_OF_MEASURE					VARCHAR2(25),
    PROCESS_FLAG										NUMBER,
    PROGRAM_APPLICATION_ID					NUMBER,
    PROGRAM_ID											NUMBER,
    PROGRAM_UPDATE_DATE							DATE,
    QUANTITY_RELATED								NUMBER,
    REFERENCE_DESIGNATOR						VARCHAR2(15),
    REQUEST_ID											NUMBER,
    REQUIRED_FOR_REVENUE						NUMBER,
    REQUIRED_TO_SHIP								NUMBER,
    RETURN_STATUS										VARCHAR2(1),
    REVISED_ITEM_NUMBER							VARCHAR2(240),
    REVISED_ITEM_SEQUENCE_ID				NUMBER,
    SHIPPING_ALLOWED								NUMBER,
    SO_BASIS												NUMBER,
    SUBSTITUTE_COMP_ID							NUMBER,
    SUBSTITUTE_COMP_NUMBER					VARCHAR2(240),
    SUGGESTED_VENDOR_NAME						VARCHAR2(240),
    SUPPLY_LOCATOR_ID								NUMBER,
    SUPPLY_SUBINVENTORY							VARCHAR2(10),
    TEMPLATE_NAME										VARCHAR2(240),
    TO_END_ITEM_MINOR_REV_CODE			VARCHAR2(240),
    TO_END_ITEM_MINOR_REV_ID				NUMBER,
    TO_END_ITEM_REV_CODE						VARCHAR2(240),
    TO_END_ITEM_REV_ID							NUMBER,
    TO_END_ITEM_UNIT_NUMBER					VARCHAR2(30),
    TO_MINOR_REVISION_CODE					VARCHAR2(240),
    TO_MINOR_REVISION_ID						NUMBER,
    TO_OBJECT_REVISION_CODE					VARCHAR2(240),
    TO_OBJECT_REVISION_ID						NUMBER,
    TRANSACTION_ID									NUMBER,
    TRANSACTION_TYPE								VARCHAR2(10),
    UNIT_PRICE											NUMBER,
    WIP_SUPPLY_TYPE									NUMBER,
    RECORD_NUMBER                   NUMBER, -- Custom columns (datafile)
    SOURCE_SYSTEM_NAME              VARCHAR2(60), -- Custom columns (datafile)
    ORGANIZATION_CODE_ORIG          VARCHAR2(3), -- Used to store original ORGANIZATION_CODE from Mapping
    PRIMARY_UNIT_OF_MEASURE_ORIG    VARCHAR2(25),-- Used to store original PRIMARY_UNIT_OF_MEASURE from Mapping
    INCLUDE_IN_COST_ROLLUP_ORIG     NUMBER, -- Used to store original INCLUDE_IN_COST_ROLLUP
    COMPONENT_YIELD_FACTOR_ORIG     NUMBER,  -- Used to store original COMPONENT_YIELD_FACTOR in Oracle after conversion
    PROCESS_CODE                    VARCHAR2(100), -- Custom columns
    ERROR_CODE                      VARCHAR2(100), -- Custom columns
    ERROR_MESG                      VARCHAR2(2000) -- Custom columns
    );


-- PO Header Level Staging Table Type
  TYPE g_xx_bom_comp_tab_type IS TABLE OF G_XX_BOM_COMP_STG_REC_TYPE
     INDEX BY BINARY_INTEGER;

 PROCEDURE main( errbuf   OUT VARCHAR2
                                ,retcode               OUT VARCHAR2
                                ,p_batch_id             IN  VARCHAR2
                                ,p_comp_batch_id	      IN VARCHAR2
                                ,p_bom_transaction_type IN VARCHAR2
                                ,p_restart_flag         IN  VARCHAR2
                                ,p_validate_and_load    IN VARCHAR2
                               );

END xx_bom_import_pkg;
/


GRANT EXECUTE ON APPS.XX_BOM_IMPORT_PKG TO INTG_XX_NONHR_RO;
