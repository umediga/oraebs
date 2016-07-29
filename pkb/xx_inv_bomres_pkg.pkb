DROP PACKAGE BODY APPS.XX_INV_BOMRES_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_BOMRES_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMRES.pkb
Description   : This script creates the package xx_inv_bomres_pkg
Change History:
Date         Name                   Remarks
-----------  -------------          -----------------------------------
06-Dec-2013  ABHARGAVA            Initial Draft.
*/
--------------------------------------------------------------------
/*------------------------------------------------------------------
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. All low level emf messages can be retained
2. Hard coding of emf messages are allowed in the code
3. Any other hard coding should be dealt by constants package
4. Exception handling should be left as is most of the places unless specified


-- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
-- START RESTRICTIONS

-------------------------------------------------------------------------------------
------------< Procedure for setting Environment >------------
-------------------------------------------------------------------------------------
*/
PROCEDURE set_cnv_env (
  p_batch_id        VARCHAR2,
  p_required_flag   VARCHAR2 DEFAULT xx_emf_cn_pkg.cn_yes
)
IS
  x_error_code   NUMBER := xx_emf_cn_pkg.cn_success;
BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Start of set_cnv_env');
  g_batch_id := p_batch_id;

  -- Set the environment
  x_error_code := xx_emf_pkg.set_env;

  IF NVL (p_required_flag, xx_emf_cn_pkg.cn_yes) <> xx_emf_cn_pkg.cn_no
  THEN
     xx_emf_pkg.propagate_error (x_error_code);
  END IF;

  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'End of set_cnv_env');

EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low,
                           ' Error Message in  EMF :' || SQLERRM
                          );
     RAISE xx_emf_pkg.g_e_env_not_set;
END set_cnv_env;


-------------------------------------------------------------------------------------
------------< Procedure for Marking Records >------------
-------------------------------------------------------------------------------------
PROCEDURE mark_records_for_processing (p_batch_id     IN   VARCHAR2
                                     , p_restart_flag IN   VARCHAR2)

IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,  'Start of mark_records_for_processing');
    UPDATE XX_INV_BOMRES_STG
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       ,PHASE_CODE = xx_emf_cn_pkg.CN_NEW
    WHERE batch_id = p_batch_id
    AND   ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE = xx_emf_cn_pkg.CN_REC_ERR )
          OR
          (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));

    COMMIT;
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'End of mark_records_for_processing');
END;


--------------------------------------------------------------------------------
------------< Set Stage >------------
--------------------------------------------------------------------------------
PROCEDURE set_stage (p_stage VARCHAR2)
IS
BEGIN
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'Start of set_stage:');
  g_stage := p_stage;
  xx_emf_pkg.write_log (xx_emf_cn_pkg.cn_low, 'End of set_stage:');
END set_stage;

--------------------------------------------------------------------------------
------------< Update BOM Resource Table after Validation >------------
--------------------------------------------------------------------------------
PROCEDURE update_bomres_record_status ( p_bomres_rec     IN OUT  g_xx_inv_bomres_rec_type,
                                        p_error_code     IN      VARCHAR2
                                       ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cust_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_bomres_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_bomres_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_bomres_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_bomres_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_bomres_record_status '||SQLERRM);
END update_bomres_record_status;

--------------------------------------------------------------------------------
------------< Update BOM Resources Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_bomres_stg (  p_stage_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMRES_STG%ROWTYPE
                             ,p_batch_id    IN              VARCHAR2
                           )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_bomres_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_INV_BOMRES_STG
    SET  BATCH_ID                   = p_stage_rec.BATCH_ID
        ,SOURCE_SYSTEM_NAME         = p_stage_rec.SOURCE_SYSTEM_NAME
        ,RESOURCE_ID                = p_stage_rec.RESOURCE_ID
        ,ORG_CODE                   = p_stage_rec.org_code
        ,ORG_ID                     = p_stage_rec.org_id
        ,DESCRIPTION                = p_stage_rec.description
        ,DISABLE_DATE               = p_stage_rec.DISABLE_DATE
        ,RESOURCE_TYPE              = p_stage_rec.resource_type
        ,RESOURCE_TYPE_ID           = p_stage_rec.resource_type_id
        ,CHARGE_TYPE                = p_stage_rec.charge_type
        ,AUTOCHARGE_TYPE_ID         = p_stage_rec.AUTOCHARGE_TYPE_ID
        ,COST_CODE                  = p_stage_rec.cost_code
        ,COST_CODE_TYPE             = p_stage_rec.cost_code_type
        ,PURCHASE_ITEM              = p_stage_rec.purchase_item
        ,PURCHASE_ITEM_ID           = p_stage_rec.purchase_item_id
        ,UOM                        = p_stage_rec.uom
        ,ABSORPTION_ACCOUNT         = p_stage_rec.absorption_account
        ,ABSORPTION_ACCOUNT_ID      = p_stage_rec.absorption_account_id
        ,RATE_VARIANCE_ACCOUNT      = p_stage_rec.RATE_VARIANCE_ACCOUNT
        ,RATE_VARIANCE_ACCOUNT_ID   = p_stage_rec.RATE_VARIANCE_ACCOUNT_id
        ,ALLOW_COST_FLAG            = p_stage_rec.allow_cost_flag
        ,ALLOW_COST_FLAG_ID         = p_stage_rec.allow_cost_flag_id
        ,COST_ELEMENT_ID            = p_stage_rec.cost_element_id
        ,FUNCTIONAL_CURRENCY_FLAG_ID= p_stage_rec.FUNCTIONAL_CURRENCY_FLAG_ID
        ,DEFAULT_ACTIVITY_ID        = p_stage_rec.DEFAULT_ACTIVITY_ID
        ,STANDARD_RATE_FLAG_ID      = p_stage_rec.STANDARD_RATE_FLAG_ID
        ,ATTRIBUTE_CATEGORY         = p_stage_rec.ATTRIBUTE_CATEGORY
        ,ATTRIBUTE1                 = p_stage_rec.ATTRIBUTE1
        ,ATTRIBUTE2                 = p_stage_rec.ATTRIBUTE2
        ,ATTRIBUTE3                 = p_stage_rec.ATTRIBUTE3
        ,ATTRIBUTE4                 = p_stage_rec.ATTRIBUTE4
        ,ATTRIBUTE5                 = p_stage_rec.ATTRIBUTE5
        ,ATTRIBUTE6                 = p_stage_rec.ATTRIBUTE6
        ,ATTRIBUTE7                 = p_stage_rec.ATTRIBUTE7
        ,ATTRIBUTE8                 = p_stage_rec.ATTRIBUTE8
        ,ATTRIBUTE9                 = p_stage_rec.ATTRIBUTE9
        ,ATTRIBUTE10                = p_stage_rec.ATTRIBUTE10
        ,RECORD_NUMBER              = p_stage_rec.RECORD_NUMBER
        ,REQUEST_ID                 = xx_emf_pkg.G_REQUEST_ID
        ,LAST_UPDATED_BY            = x_last_updated_by
        ,LAST_UPDATE_DATE           = x_last_update_date
        ,PHASE_CODE                 = p_stage_rec.PHASE_CODE
        ,ERROR_CODE                 = p_stage_rec.ERROR_CODE
        ,ERROR_MSG                  = p_stage_rec.ERROR_MSG
    WHERE batch_id          =   p_batch_id
    and   record_number     =   p_stage_rec.record_number
    and   resource_code     =   p_stage_rec.RESOURCE_CODE;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_bomres_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_bomres_stg;


--------------------------------------------------------------------------------
------------< Update Count >------------
--------------------------------------------------------------------------------
PROCEDURE update_cnt
IS
l_suc    NUMBER := 0;
l_err    NUMBER := 0;
l_tot    NUMBER := 0;
BEGIN

    select count(1)
    into l_tot
    from XX_INV_BOMRES_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XX_INV_BOMRES_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XX_INV_BOMRES_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '2';

    xx_emf_pkg.update_recs_cnt
        (
            p_total_recs_cnt   => l_tot,
            p_success_recs_cnt => l_suc,
            p_warning_recs_cnt => 0,
            p_error_recs_cnt   => l_err
        );

EXCEPTION
WHEN OTHERS THEN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_cnt '||SQLERRM);
END;

-------------------------------------------------------------------------------------
--------------------------- Resource Fileds Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION res_derivations (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMRES_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'res_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    -- Deriving Resource Type ID
    IF UPPER(p_res_rec.RESOURCE_TYPE) = UPPER('Person') THEN
       p_res_rec.RESOURCE_TYPE_ID := 2;
    ELSIF UPPER(p_res_rec.RESOURCE_TYPE) = UPPER('Miscellaneous') THEN
       p_res_rec.RESOURCE_TYPE_ID := 4;
    ELSIF UPPER(p_res_rec.RESOURCE_TYPE) = UPPER('Machine') THEN
       p_res_rec.RESOURCE_TYPE_ID := 1;
    ELSIF UPPER(p_res_rec.RESOURCE_TYPE) = UPPER('Currency') THEN
       p_res_rec.RESOURCE_TYPE_ID := 6;
    ELSIF UPPER(p_res_rec.RESOURCE_TYPE) = UPPER('Amount') THEN
       p_res_rec.RESOURCE_TYPE_ID := 5;
    ELSE
       l_msg := 'Error Deriving Resource Type ID ';
       RAISE l_error_transaction;
    END IF;

    -- Functioanl Currency Flag
    IF p_res_rec.RESOURCE_TYPE_ID = 6 THEN
       p_res_rec.FUNCTIONAL_CURRENCY_FLAG_ID := 1;
    ELSE
       p_res_rec.FUNCTIONAL_CURRENCY_FLAG_ID := 2;
    END IF;

    -- Deriving Charge Type ID
    IF UPPER(p_res_rec.CHARGE_TYPE) = UPPER('PO Move') THEN
       p_res_rec.AUTOCHARGE_TYPE_ID := 4;
    ELSIF UPPER(p_res_rec.CHARGE_TYPE) = UPPER('WIP Move') THEN
       p_res_rec.AUTOCHARGE_TYPE_ID := 1;
    ELSIF UPPER(p_res_rec.CHARGE_TYPE) = UPPER('PO Receipt') THEN
       p_res_rec.AUTOCHARGE_TYPE_ID := 3;
    ELSIF UPPER(p_res_rec.CHARGE_TYPE) = UPPER('Manual') THEN
       p_res_rec.AUTOCHARGE_TYPE_ID := 2;
    ELSE
       l_msg := 'Error Deriving Charge Type ID ';
       RAISE l_error_transaction;
    END IF;

    -- Cost Element ID
    IF p_res_rec.AUTOCHARGE_TYPE_ID in (1,2) THEN
       p_res_rec.COST_ELEMENT_ID := 3;
    ELSE
       p_res_rec.COST_ELEMENT_ID := 4;
    END IF;

    -- Deriving Cost Code Type
    IF UPPER(p_res_rec.COST_CODE) = 'Y' THEN
       p_res_rec.COST_CODE_TYPE := 4;
    ELSIF UPPER(p_res_rec.COST_CODE) = 'N' THEN
       p_res_rec.COST_CODE_TYPE := 3;
    ELSE
       p_res_rec.COST_CODE_TYPE := 3;
    END IF;

    -- Deriving Allow Cost Flag
    IF UPPER(p_res_rec.ALLOW_COST_FLAG) = 'Y' THEN
       p_res_rec.ALLOW_COST_FLAG_ID := 1;
    ELSIF UPPER(p_res_rec.ALLOW_COST_FLAG) = 'N' THEN
       p_res_rec.ALLOW_COST_FLAG_ID := 2;
    ELSE
       p_res_rec.ALLOW_COST_FLAG_ID := 2;
    END IF;

    -- Deriving Batchable Flag
    IF UPPER(p_res_rec.BATCHABLE_FLAG) = 'Y' THEN
       p_res_rec.BATCHABLE_FLAG_ID := 1;
    ELSIF UPPER(p_res_rec.BATCHABLE_FLAG) = 'N' THEN
       p_res_rec.BATCHABLE_FLAG_ID := 2;
    ELSE
       p_res_rec.BATCHABLE_FLAG_ID := 2;
    END IF;

    -- Deriving ORG ID
    BEGIN
        select organization_id
        into p_res_rec.ORG_ID
        from org_organization_definitions
        where organization_code = p_res_rec.org_code;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Org Code :'||p_res_rec.org_code);
        l_msg := 'Error Deriving Org Code ';
        RAISE l_error_transaction;
    END;

    -- Deriving Purchase Item ID
    BEGIN
        select inventory_item_id
        into p_res_rec.PURCHASE_ITEM_ID
        from mtl_system_items_b
        where segment1 = p_res_rec.PURCHASE_ITEM
        and organization_id = p_res_rec.ORG_ID;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Inventory Item ID  :'||p_res_rec.PURCHASE_ITEM);
        l_msg := 'Error Deriving Inventory Item ID';
        RAISE l_error_transaction;
    END;

    BEGIN
    -- Deriving Absorption A/C
    IF p_res_rec.absorption_account IS NOT NULL THEN
      select code_combination_id
      into p_res_rec.ABSORPTION_ACCOUNT_ID
      from gl_code_combinations_kfv
      where concatenated_segments  = p_res_rec.absorption_account;
    ELSE
      p_res_rec.ABSORPTION_ACCOUNT_ID :=  NULL;
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Absorption A/C ID :'||p_res_rec.absorption_account);
        l_msg := 'Error Deriving Absorption A/C ';
        RAISE l_error_transaction;
    END;

    BEGIN
    -- Deriving Rate Variance A/C
    IF p_res_rec.RATE_VARIANCE_ACCOUNT IS NOT NULL THEN
      select code_combination_id
      into p_res_rec.RATE_VARIANCE_ACCOUNT_ID
      from gl_code_combinations_kfv
      where concatenated_segments  = p_res_rec.RATE_VARIANCE_ACCOUNT;
    ELSE
      p_res_rec.RATE_VARIANCE_ACCOUNT_ID :=  NULL;
    END IF;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Rate Variance A/C ID :'||p_res_rec.absorption_account);
        l_msg := 'Error Deriving Rate Variance A/C ';
        RAISE l_error_transaction;
    END;

    IF p_res_rec.BILLABLE_ITEM IS NOT NULL THEN
    -- Deriving Billable Item ID
      BEGIN
          select inventory_item_id
          into p_res_rec.BILLABLE_ITEM_ID
          from mtl_system_items_b
          where segment1 = p_res_rec.BILLABLE_ITEM
          and organization_id = p_res_rec.ORG_ID;
      EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Billable Item ID  :'||p_res_rec.PURCHASE_ITEM);
          l_msg := 'Error Deriving Billable Item ID';
          RAISE l_error_transaction;
      END;
    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    RETURN TRUE;
EXCEPTION
  WHEN l_error_transaction
  THEN
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg   := g_api_name || ': ' || l_msg;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg,
                       p_res_rec.record_number,
                       p_res_rec.resource_code,
                       NULL
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'res_derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_res_rec.record_number,
                       p_res_rec.resource_code,
                       NULL
                      );
     RETURN FALSE;
END res_derivations;


-------------------------------------------------------------------------------------
---------------------------------- Attach File --------------------------------------
-------------------------------------------------------------------------------------
FUNCTION resource_load (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMRES_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
  l_error_transaction   EXCEPTION;
  l_rowid               VARCHAR2 (2000);
  l_resource_id         NUMBER;
  l_msg                 VARCHAR2(300);
  L_REQUEST_ID                     NUMBER := NULL;
  L_PROGRAM_APPLICATION_ID         NUMBER := NULL;
  L_PROGRAM_ID                     NUMBER := NULL;
  L_PROGRAM_UPDATE_DATE            DATE := NULL;

BEGIN
    g_api_name := 'resource_load';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    BEGIN
        l_msg := 'Error Inserting Data using BOM_RESOURCES_PKG.Insert_Row API';

        BOM_RESOURCES_PKG.Insert_Row
                       (
                        X_Rowid                          => l_rowid
                       ,X_Resource_Id                    => l_resource_id
                       ,X_Resource_Code                  => p_res_rec.Resource_Code
                       ,X_Organization_Id                => p_res_rec.org_id
                       ,X_Last_Update_Date               => sysdate
                       ,X_Last_Updated_By                => fnd_global.user_id
                       ,X_Creation_Date                  => sysdate
                       ,X_Created_By                     => fnd_global.user_id
                       ,X_Last_Update_Login              => fnd_global.user_id
                       ,X_Description                    => p_res_rec.description
                       ,X_Disable_Date                   => p_res_rec.disable_date
                       ,X_Cost_Element_Id                => p_res_rec.COST_ELEMENT_ID
                       ,X_Purchase_Item_Id               => p_res_rec.purchase_item_id
                       ,X_Cost_Code_Type                 => p_res_rec.COST_CODE_TYPE
                       ,X_Functional_Currency_Flag       => p_res_rec.Functional_Currency_Flag_id
                       ,X_Unit_Of_Measure                => p_res_rec.UOM
                       ,X_Default_Activity_Id            => p_res_rec.Default_Activity_Id
                       ,X_Resource_Type                  => p_res_rec.Resource_Type_id
                       ,X_Autocharge_Type                => p_res_rec.Autocharge_Type_id
                       ,X_Standard_Rate_Flag             => p_res_rec.Standard_Rate_Flag_id
                       ,X_Default_Basis_Type             => NULL
                       ,X_Absorption_Account             => p_res_rec.ABSORPTION_ACCOUNT_ID
                       ,X_Allow_Costs_Flag               => p_res_rec.Allow_Cost_Flag_id
                       ,X_Rate_Variance_Account          => p_res_rec.RATE_VARIANCE_ACCOUNT_ID
                       ,X_Expenditure_Type               => NULL
                       ,X_Attribute_Category             => p_res_rec.Attribute_Category
                       ,X_Attribute1                     => p_res_rec.Attribute1
                       ,X_Attribute2                     => p_res_rec.Attribute2
                       ,X_Attribute3                     => p_res_rec.Attribute3
                       ,X_Attribute4                     => p_res_rec.Attribute4
                       ,X_Attribute5                     => p_res_rec.Attribute5
                       ,X_Attribute6                     => p_res_rec.Attribute6
                       ,X_Attribute7                     => p_res_rec.Attribute7
                       ,X_Attribute8                     => p_res_rec.Attribute8
                       ,X_Attribute9                     => p_res_rec.Attribute9
                       ,X_Attribute10                    => p_res_rec.Attribute10
                       ,X_Attribute11                    => p_res_rec.Attribute11
                       ,X_Attribute12                    => p_res_rec.Attribute12
                       ,X_Attribute13                    => p_res_rec.Attribute13
                       ,X_Attribute14                    => p_res_rec.Attribute14
                       ,X_Attribute15                    => p_res_rec.Attribute15
                       ,X_REQUEST_ID                     => L_REQUEST_ID
                       ,X_PROGRAM_APPLICATION_ID         => L_PROGRAM_APPLICATION_ID
                       ,X_PROGRAM_ID                     => L_PROGRAM_ID
                       ,X_PROGRAM_UPDATE_DATE            => L_PROGRAM_UPDATE_DATE
                       ,x_batchable                      => p_res_rec.batchable_flag_id
                       ,x_min_batch_capacity             => p_res_rec.MIN_BATCH_CAPACITY
                       ,x_max_batch_capacity             => p_res_rec.MAX_BATCH_CAPACITY
                       ,x_batch_capacity_uom             => p_res_rec.BATCH_CAPACITY_UOM
                       ,x_batch_window                   => p_res_rec.BATCH_WINDOW
                       ,x_batch_window_uom               => p_res_rec.BATCH_WINDOW_UOM
                       ,x_competence_id                  => NULL
                       ,x_rating_level_id                => NULL
                       ,x_qualification_type_id          => NULL
                       ,x_billable_item_id               => p_res_rec.BILLABLE_ITEM_ID
                       ,x_supply_subinventory            => NULL
                       ,x_supply_locator_id              => NULL
                      );

            p_res_rec.RESOURCE_ID           :=  l_resource_id;

    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg||' '||SQLERRM);
        RAISE l_error_transaction;
    END;

    IF l_resource_id IS NOT NULL THEN
       RETURN TRUE;
    ELSE
        l_msg := 'Resource ID Not generated';
        RAISE l_error_transaction;
    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


EXCEPTION
  WHEN l_error_transaction
  THEN
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg  := g_api_name || ': ' || l_msg||' '||SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg||' '||SQLERRM,
                       p_res_rec.record_number,
                       p_res_rec.resource_code,
                       NULL
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'resource_load Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_res_rec.record_number,
                       p_res_rec.RESOURCE_CODE,
                       NULL
                      );
     RETURN FALSE;
END resource_load;
-------------------------------------------------------------------------------------
----------------------------------Procedure main-------------------------------------
-------------------------------------------------------------------------------------
PROCEDURE main (
  errbuf                OUT NOCOPY      VARCHAR2,
  retcode               OUT NOCOPY      VARCHAR2,
  p_batch_id            IN              VARCHAR2,
  p_restart_flag        IN              VARCHAR2,
  p_validate_and_load   IN              VARCHAR2
)
IS

CURSOR c_bomres_load
IS
  select *
  from XX_INV_BOMRES_STG
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));


  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_inv_bomres_tab          xx_inv_bomres_tab_type;
  l_inv_bomres_rec          xxconv.XX_INV_BOMRES_STG%ROWTYPE;

  e_bomres_exception   EXCEPTION;

BEGIN
     retcode := xx_emf_cn_pkg.CN_SUCCESS;

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Set_cnv_env');
     set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id          '    || p_batch_id);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag      '    || p_restart_flag);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));

     -- Call procedure to update records with the current request_id
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
     mark_records_for_processing(p_batch_id, p_restart_flag);

     IF p_validate_and_load = 'VALIDATE_ONLY' THEN
     -- This section is executed when the user selects to VALIDATE_ONLY mode. The section pertains to validation of data given
         set_stage (xx_emf_cn_pkg.CN_VALID);
         -- Start Data Validation
         OPEN c_bomres_load;
         LOOP
            FETCH c_bomres_load
            BULK COLLECT INTO l_inv_bomres_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_inv_bomres_tab.COUNT
            LOOP
                l_inv_bomres_rec := l_inv_bomres_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion for '||l_inv_bomres_rec.RESOURCE_CODE);
                x_error_code  := xx_inv_bomres_val_pkg.data_validations_bomres(l_inv_bomres_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_inv_bomres_rec.record_number||'  is ' || x_error_code);
                l_inv_bomres_rec.phase_code := G_STAGE;
                l_inv_bomres_rec.error_code := x_error_code;
                IF update_bomres_stg (l_inv_bomres_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomres_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomres_stg update FAILED');
                END IF;
            END LOOP;
            l_inv_bomres_tab.DELETE;
            EXIT WHEN c_bomres_load%NOTFOUND;
         END LOOP;
         CLOSE c_bomres_load;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_bomres_load%ISOPEN
        THEN
             CLOSE c_bomres_load;
        END IF;

        OPEN c_bomres_load;

        FETCH c_bomres_load
        BULK COLLECT INTO l_inv_bomres_tab;

        FOR i IN 1 .. l_inv_bomres_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_inv_bomres_rec := l_inv_bomres_tab (i);
                l_inv_bomres_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_inv_bomres_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

                IF NOT res_derivations (p_res_rec => l_inv_bomres_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'res_derivations Failed');
                   RAISE e_bomres_exception;
                END IF; -- res_derivations

                IF NOT resource_load (p_res_rec => l_inv_bomres_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'resource_ Failed');
                   RAISE  e_bomres_exception;
                END IF; -- resource_

                l_inv_bomres_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_inv_bomres_rec.error_msg  := NULL;
                IF update_bomres_stg (l_inv_bomres_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_bomres_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_bomres_exception
            THEN
                l_inv_bomres_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_bomres_stg (l_inv_bomres_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_bomres_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_inv_bomres_tab.DELETE;
        CLOSE c_bomres_load;

     END IF;  -- Validate and Load Condition

     update_cnt;
     xx_emf_pkg.create_report;

EXCEPTION
    WHEN xx_emf_pkg.G_E_ENV_NOT_SET THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'Checking if this is OK');
         fnd_file.put_line ( fnd_file.output, xx_emf_pkg.CN_ENV_NOT_SET);
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
    WHEN xx_emf_pkg.G_E_REC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'REC_ERROR');
         retcode := xx_emf_cn_pkg.CN_REC_ERR;
         xx_emf_pkg.create_report;
    WHEN xx_emf_pkg.G_E_PRC_ERROR THEN
         xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'PRC_ERROR');
         retcode := xx_emf_cn_pkg.CN_PRC_ERR;
         xx_emf_pkg.create_report;
    WHEN OTHERS THEN
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS '||sqlerrm);
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_inv_bomres_pkg;
/
