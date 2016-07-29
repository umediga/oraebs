DROP PACKAGE BODY APPS.XX_INV_BOMRESRATE_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_BOMRESRATE_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMRESRATE.pkb
Description   : This script creates the package xx_inv_bomresrate_pkg
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
                                     , p_restart_flag IN   VARCHAR2
                                     , p_cost_type    IN   VARCHAR2)

IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW,  'Start of mark_records_for_processing');
    UPDATE XX_INV_BOMRESRATE_STG
    set REQUEST_ID = xx_emf_pkg.G_REQUEST_ID
       ,PHASE_CODE = xx_emf_cn_pkg.CN_NEW
    WHERE batch_id = p_batch_id
    AND   COST_TYPE = p_cost_type
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
PROCEDURE upd_bomresrate_rec_status ( p_bomresrate_rec IN OUT  g_xx_inv_bomresrate_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_bomresrate_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_bomresrate_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_bomresrate_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_bomresrate_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_bomresrate_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_bomresrate_record_status '||SQLERRM);
END upd_bomresrate_rec_status;

--------------------------------------------------------------------------------
--------< Get Status BOM Resource Rate Staging Records from Interface >---------
--------------------------------------------------------------------------------
PROCEDURE post_validations_bomresrate (  p_stage_rec   IN OUT NOCOPY   xxconv.XX_INV_bomresrate_STG%ROWTYPE)
IS
   x_error_code   NUMBER := xx_emf_cn_pkg.CN_SUCCESS;
   l_err_flag     VARCHAR2(100);
   l_err_exp      VARCHAR2(240);
BEGIN
    select error_flag,error_explanation
    into l_err_flag, l_err_exp
    from CST_RESOURCE_COSTS_INTERFACE
    where group_description = p_stage_rec.batch_id||'~'||p_stage_rec.record_number;

    IF l_err_flag IS NULL THEN
       p_stage_rec.error_code := x_error_code;
    ELSE
       p_stage_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
       p_stage_rec.error_msg  := l_err_exp;
       xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                          xx_emf_cn_pkg.CN_STG_DATAVAL,
                          'l_err_exp',
                          p_stage_rec.record_number,
                          p_stage_rec.RES_CODE,
                          NULL
                          );
    END IF;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'post_validations_bomresrate Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     p_stage_rec.error_msg  := l_err_exp;
     p_stage_rec.error_msg  := 'post_validations_bomresrate EXCEPTION';
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATAVAL,
                       'post_validations_bomresrate EXCEPTION',
                       p_stage_rec.record_number,
                       p_stage_rec.RES_CODE,
                       NULL
                      );
END post_validations_bomresrate;
--------------------------------------------------------------------------------
------------< Update BOM Resource Rate Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_bomresrate_stg (  p_stage_rec   IN OUT NOCOPY   xxconv.XX_INV_bomresrate_STG%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                               )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_bomresrate_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_INV_BOMRESRATE_STG
    SET  BATCH_ID                   = p_stage_rec.BATCH_ID
        ,SOURCE_SYSTEM_NAME         = p_stage_rec.SOURCE_SYSTEM_NAME
        ,ORG_CODE                   = p_stage_rec.ORG_CODE
        ,ORG_ID                     = p_stage_rec.ORG_ID
        ,RESOURCE_ID                = p_stage_rec.resource_id
        ,COST_TYPE_ID               = p_stage_rec.cost_type_id
        ,RESOURCE_RATE   			      = p_stage_rec.resource_rate
        ,RECORD_NUMBER              = p_stage_rec.RECORD_NUMBER
        ,REQUEST_ID                 = xx_emf_pkg.G_REQUEST_ID
        ,LAST_UPDATED_BY            = x_last_updated_by
        ,LAST_UPDATE_DATE           = x_last_update_date
        ,PHASE_CODE                 = p_stage_rec.PHASE_CODE
        ,ERROR_CODE                 = p_stage_rec.ERROR_CODE
        ,ERROR_MSG                  = p_stage_rec.ERROR_MSG
    WHERE batch_id                  =   p_batch_id
    and   record_number             =   p_stage_rec.record_number
    and   res_code                  =   p_stage_rec.RES_CODE
    and   cost_type                 =   p_stage_rec.cost_Type;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_bomresrate_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_bomresrate_stg;


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
    from XX_INV_bomresrate_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XX_INV_bomresrate_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XX_INV_bomresrate_STG
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
-------------------- Submit Standard Cost Import Program ----------------------------
-------------------------------------------------------------------------------------
PROCEDURE submit_standard_cst_import(p_cst_type IN VARCHAR2) IS
    x_request_id        NUMBER ;
    x_phase             VARCHAR2 (100);
    x_status            VARCHAR2 (100);
    x_dev_phase         VARCHAR2 (100);
    x_dev_status        VARCHAR2 (100);
    x_message           VARCHAR2 (240);
    x_wait_request      BOOLEAN;

    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'submit_standard_cst_import';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    x_request_id := fnd_request.submit_request
                    (application      => 'BOM',                   -- Application Short Name
                     program          => 'CSTPCIMP',              -- Concurrent Program Short Name
                     description      => 'Cost Import Process',   -- Description
                     start_time       => SYSDATE,
                     sub_request      => FALSE,
                     argument1        => 2,                       -- Import Cost Option - Import resource rates only
                     argument2        => 1,                       -- Mode - Insert new cost information only
                     argument3        => 2,                       -- Group MODE - ALL
                     argument4        => NULL,                    -- Group ID - NULL
                     argument5        => NULL,
                     argument6        => p_cst_type ,             -- Cost Type
                     argument7        => 2                        -- Delete Loaded Rows - NO
                     );
    COMMIT;

    IF x_request_id = 0 THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Error in submitting the Standard PO import');
    ELSE
        xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Standard PO import submitted successfully');
        x_wait_request := fnd_concurrent.wait_for_request
                         (request_id        => x_request_id,
                          interval          => 10,
                          max_wait          => 2000,
                          phase             => x_phase,
                          status            => x_status,
                          dev_phase         => x_dev_phase,
                          dev_status        => x_dev_status,
                          MESSAGE           => x_message
                         );

         IF x_dev_phase = 'COMPLETE' AND x_dev_status = 'NORMAL'
         THEN
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Cost Import Program Completed - Successfully');
         ELSE
             xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'Cost Import Program Completed - Failed');
         END IF;
   END IF;
EXCEPTION
WHEN OTHERS THEN
       xx_emf_pkg.write_log(xx_emf_cn_pkg.cn_high,'submit_standard_cst_import Unhandled Exception');
END submit_standard_cst_import;

-------------------------------------------------------------------------------------
--------------------------- Resource Rate Fileds Derivation ------------------------------
-------------------------------------------------------------------------------------
FUNCTION res_derivations (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_bomresrate_STG%ROWTYPE)
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

    -- Deriving Resource ID
    BEGIN
        select resource_id
        into p_res_rec.RESOURCE_ID
        from bom_resources
        where resource_code = p_res_rec.RES_CODE
        and organization_id = p_res_rec.ORG_ID
        and cost_code_type = 4;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Resource Code  :'||p_res_rec.RES_CODE);
        l_msg := 'Error Deriving Resource ID';
        RAISE l_error_transaction;
    END;

    -- Deriving Cost Type ID
    BEGIN
        select cost_Type_id
        into p_res_rec.COST_TYPE_ID
        from CST_COST_TYPES
        where cost_type = p_res_rec.cost_Type;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error DerivingCost Type ID  :'||p_res_rec.cost_Type);
        l_msg := 'Error Deriving Resource ID';
        RAISE l_error_transaction;
    END;

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
                       p_res_rec.res_code,
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
                       p_res_rec.res_code,
                       NULL
                      );
     RETURN FALSE;
END res_derivations;


-------------------------------------------------------------------------------------
-------------------------------- Resource Rate Load----------------------------------
-------------------------------------------------------------------------------------
FUNCTION resource_load (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_bomresrate_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2(300);

BEGIN
    g_api_name := 'resource_load';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    BEGIN
        l_msg := 'Error Inserting Data into CST_RESOURCE_COSTS_INTERFACE';

        insert into CST_RESOURCE_COSTS_INTERFACE
        (
        RESOURCE_ID,
        RESOURCE_CODE,
        COST_TYPE_ID,
        COST_TYPE,
        ORGANIZATION_ID,
        ORGANIZATION_CODE,
        LAST_UPDATE_DATE,
        LAST_UPDATED_BY,
        CREATION_DATE,
        CREATED_BY,
        PROCESS_FLAG,
        RESOURCE_RATE,
        GROUP_DESCRIPTION
        )
        VALUES
        (
        p_res_rec.resource_id,
        p_res_rec.res_code,
        p_res_rec.COST_TYPE_ID,
        p_res_rec.COST_TYPE,
        p_res_rec.ORG_ID,
        p_Res_rec.ORG_code,
        sysdate,
        fnd_global.user_id,
        sysdate,
        fnd_global.user_id,
        1,
        p_Res_rec.RESOURCE_RATE,
        p_res_rec.batch_id||'~'||p_res_rec.record_number
        );

    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg||' '||SQLERRM);
        RAISE l_error_transaction;
    END;

    RETURN TRUE;
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
                       p_res_rec.res_code,
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
                       p_res_rec.RES_CODE,
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
  p_cost_type           IN              VARCHAR2,
  p_restart_flag        IN              VARCHAR2,
  p_validate_and_load   IN              VARCHAR2
)
IS

CURSOR c_bomresrate_load
IS
  select *
  from XX_INV_bomresrate_STG
  WHERE batch_id = p_batch_id
  AND   cost_type = p_cost_type
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));

CURSOR c_bomrate_load
IS
  select *
  from XX_INV_bomresrate_STG
  WHERE batch_id = p_batch_id
  AND   cost_type = p_cost_type
  AND   error_code = xx_emf_cn_pkg.CN_SUCCESS;

  x_error_code                  NUMBER := xx_emf_cn_pkg.cn_success;
  l_inv_bomresrate_tab          xx_inv_bomresrate_tab_type;
  l_inv_bomresrate_rec          xxconv.XX_INV_bomresrate_STG%ROWTYPE;

  e_bomresrate_exception   EXCEPTION;

BEGIN
     retcode := xx_emf_cn_pkg.CN_SUCCESS;

     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before Setting Environment');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Calling Set_cnv_env');
     set_cnv_env (p_batch_id,xx_emf_cn_pkg.CN_YES);

     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Starting main process with the following parameters');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_batch_id          '    || p_batch_id);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_cost_Type         '    || p_cost_type);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_restart_flag      '    || p_restart_flag);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_MEDIUM, 'Main:Param - p_validate_and_load '    || p_validate_and_load);
     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));

     -- Call procedure to update records with the current request_id
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Calling mark_records_for_processing..');
     mark_records_for_processing(p_batch_id, p_cost_type,p_restart_flag);

     IF p_validate_and_load = 'VALIDATE_ONLY' THEN
     -- This section is executed when the user selects to VALIDATE_ONLY mode. The section pertains to validation of data given
         set_stage (xx_emf_cn_pkg.CN_VALID);
         -- Start Data Validation
         OPEN c_bomresrate_load;
         LOOP
            FETCH c_bomresrate_load
            BULK COLLECT INTO l_inv_bomresrate_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_inv_bomresrate_tab.COUNT
            LOOP
                l_inv_bomresrate_rec := l_inv_bomresrate_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion for '||l_inv_bomresrate_rec.RES_CODE);
                x_error_code  := xx_inv_bomresrate_val_pkg.data_validations_bomresrate(l_inv_bomresrate_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_inv_bomresrate_rec.record_number||'  is ' || x_error_code);
                l_inv_bomresrate_rec.phase_code := G_STAGE;
                l_inv_bomresrate_rec.error_code := x_error_code;
                IF update_bomresrate_stg (l_inv_bomresrate_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomresrate_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomresrate_stg update FAILED');
                END IF;
            END LOOP;
            l_inv_bomresrate_tab.DELETE;
            EXIT WHEN c_bomresrate_load%NOTFOUND;
         END LOOP;
         CLOSE c_bomresrate_load;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_bomresrate_load%ISOPEN
        THEN
             CLOSE c_bomresrate_load;
        END IF;

        OPEN c_bomresrate_load;

        FETCH c_bomresrate_load
        BULK COLLECT INTO l_inv_bomresrate_tab;

        FOR i IN 1 .. l_inv_bomresrate_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_inv_bomresrate_rec := l_inv_bomresrate_tab (i);
                l_inv_bomresrate_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_inv_bomresrate_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

                IF NOT res_derivations (p_res_rec => l_inv_bomresrate_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'res_derivations Failed');
                   RAISE e_bomresrate_exception;
                END IF; -- res_derivations

                IF NOT resource_load (p_res_rec => l_inv_bomresrate_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'resource_ Failed');
                   RAISE  e_bomresrate_exception;
                END IF; -- resource_load

                l_inv_bomresrate_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_inv_bomresrate_rec.error_msg  := NULL;
                IF update_bomresrate_stg (l_inv_bomresrate_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_bomresrate_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_bomresrate_exception
            THEN
                l_inv_bomresrate_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_bomresrate_stg (l_inv_bomresrate_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_bomresrate_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_inv_bomresrate_tab.DELETE;
        CLOSE c_bomresrate_load;

       submit_standard_cst_import(p_cost_type);
       -- Post Validate Section
       OPEN c_bomrate_load;
       LOOP
          FETCH c_bomrate_load
          BULK COLLECT INTO l_inv_bomresrate_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

          FOR i IN 1 .. l_inv_bomresrate_tab.COUNT
          LOOP
              l_inv_bomresrate_rec := l_inv_bomresrate_tab (i);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Post Load Data Validation for '||l_inv_bomresrate_rec.RES_CODE);
              post_validations_bomresrate(l_inv_bomresrate_rec);
              xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_inv_bomresrate_rec.record_number||'  is ' || x_error_code);
              l_inv_bomresrate_rec.phase_code := 'Post Load';
              IF update_bomresrate_stg (l_inv_bomresrate_rec, p_batch_id)
              THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomresrate_stg updated');
              ELSE
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bomresrate_stg update FAILED');
              END IF;
          END LOOP;
          l_inv_bomresrate_tab.DELETE;
          EXIT WHEN c_bomrate_load%NOTFOUND;
       END LOOP;
       CLOSE c_bomrate_load;
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
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS'||sqlerrm);
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_inv_bomresrate_pkg;
/
