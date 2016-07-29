DROP PACKAGE BODY APPS.XX_INV_BOMDEPRES_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_INV_BOMDEPRES_PKG" 
AS
----------------------------------------------------------------------
/*
Created By    : IBM Development Team
Creation Date : 06-Dec-2013
File Name     : XXINVBOMDEPRES.pkb
Description   : This script creates the package xx_inv_BOMDEPRES_pkg
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
    UPDATE XX_INV_BOMDEPRES_STG
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
PROCEDURE update_BOMDEPRES_record_status ( p_BOMDEPRES_rec     IN OUT  g_xx_inv_BOMDEPRES_rec_type,
                                        p_error_code     IN      VARCHAR2
                                       ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_cust_record_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_BOMDEPRES_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_BOMDEPRES_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_BOMDEPRES_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_BOMDEPRES_record_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_BOMDEPRES_record_status '||SQLERRM);
END update_BOMDEPRES_record_status;

--------------------------------------------------------------------------------
------------< Update BOM Dept Resources Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_BOMDEPRES_stg (  p_stage_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE
                             ,p_batch_id    IN              VARCHAR2
                           )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_BOMDEPRES_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    UPDATE XX_INV_BOMDEPRES_STG
    SET  BATCH_ID                   = p_stage_rec.BATCH_ID
        ,SOURCE_SYSTEM_NAME         = p_stage_rec.SOURCE_SYSTEM_NAME
        ,ORG_CODE                   = p_stage_rec.org_code
        ,ORG_ID                     = p_stage_rec.org_id
        ,DEPT_ID                    = p_stage_rec.dept_id
        ,RES_ID                     = p_stage_rec.res_id
        ,SHARE_CAPACITY_FLAG        = p_stage_rec.SHARE_CAPACITY_FLAG
        ,SHARE_CAPACITY_FLAG_ID     = p_stage_rec.SHARE_CAPACITY_FLAG_ID
        ,CAPACITY_UNITS             = p_stage_rec.CAPACITY_UNITS
        ,AVAILABLE_24_HOURS_FLAG    = p_stage_rec.AVAILABLE_24_HOURS_FLAG
        ,AVLBL_24_ID                = p_stage_rec.AVLBL_24_ID
        ,CTP_FLAG                   = p_stage_rec.CTP_FLAG
        ,CTP_FLAG_ID                = p_stage_rec.CTP_FLAG_ID
        ,EXCEPTION_SET_NAME         = p_stage_rec.EXCEPTION_SET_NAME
        ,ATP_RULE                   = p_stage_rec.ATP_RULE
        ,ATP_RULE_ID                = p_stage_rec.ATP_RULE_ID
        ,UTILIZATION                = p_stage_rec.UTILIZATION
        ,EFFICIENCY                 = p_stage_rec.EFFICIENCY
        ,SCHEDULE_TO_INSTANCE       = p_stage_rec.SCHEDULE_TO_INSTANCE
        ,SEQUENCING_WINDOW          = p_stage_rec.SEQUENCING_WINDOW
        ,REQUEST_ID                 = xx_emf_pkg.G_REQUEST_ID
        ,LAST_UPDATED_BY            = x_last_updated_by
        ,LAST_UPDATE_DATE           = x_last_update_date
        ,PHASE_CODE                 = p_stage_rec.PHASE_CODE
        ,ERROR_CODE                 = p_stage_rec.ERROR_CODE
        ,ERROR_MSG                  = p_stage_rec.ERROR_MSG
    WHERE batch_id          =   p_batch_id
    and   record_number     =   p_stage_rec.record_number
    and   dept_code         =   p_stage_rec.dept_code
    and   res_code          =   p_stage_rec.RES_CODE;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_BOMDEPRES_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_BOMDEPRES_stg;


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
    from XX_INV_BOMDEPRES_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XX_INV_BOMDEPRES_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XX_INV_BOMDEPRES_STG
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
------------------------------- Fileds Derivation -----------------------------------
-------------------------------------------------------------------------------------
FUNCTION fld_derivations (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'fld_derivations';
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

    -- Deriving Department ID
    BEGIN
        select a.department_id
        into p_res_rec.DEPT_ID
        from BOM_DEPARTMENTS a
        where organization_id = p_res_rec.ORG_ID
        and department_code = p_res_rec.DEPT_CODE;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Department ID :'||p_res_rec.dept_code);
        l_msg := 'Error Deriving Department ID ';
        RAISE l_error_transaction;
    END;

    -- Deriving Resource ID
    BEGIN
        select a.resource_id
        into p_res_rec.RES_ID
        from BOM_RESOURCES a
        where organization_id = p_res_rec.ORG_ID
        and resource_code = p_res_rec.RES_CODE
        and rownum <= 1;
    EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Resource ID :'||p_res_rec.res_code);
        l_msg := 'Error Deriving Resource ID ';
        RAISE l_error_transaction;
    END;

    IF p_res_rec.ATP_RULE IS NOT NULL THEN
      -- Deriving ATP Rule ID
      BEGIN
          select a.rule_id
          into p_res_rec.ATP_RULE_ID
          from mtl_atp_rules a
          where rule_name = p_res_rec.ATP_RULE;
      EXCEPTION
      WHEN OTHERS THEN
          xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving ATP Rule ID :'||p_res_rec.res_code);
          l_msg := 'Error Deriving ATP Rule ID ';
          RAISE l_error_transaction;
      END;
    END IF;

    -- Setting Flag ID's
    IF p_res_rec.SHARE_CAPACITY_FLAG = 'Y' THEN
       p_res_rec.SHARE_CAPACITY_FLAG_id := 1;
    ELSE
       p_res_rec.SHARE_CAPACITY_FLAG_id := 2;
    END IF;

    IF p_res_rec.AVAILABLE_24_HOURS_FLAG = 'Y' THEN
       p_res_rec.AVLBL_24_ID := 1;
    ELSE
       p_res_rec.AVLBL_24_ID := 2;
    END IF;

    IF p_res_rec.CTP_FLAG = 'Y' THEN
       p_res_rec.CTP_FLAG_ID := 1;
    ELSE
       p_res_rec.CTP_FLAG_ID := 2;
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
                       p_res_rec.dept_code||' - '||p_res_rec.res_code,
                       NULL
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'fld_derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_res_rec.record_number,
                       p_res_rec.dept_code||' - '||p_res_rec.res_code,
                       NULL
                      );
     RETURN FALSE;
END fld_derivations;


-------------------------------------------------------------------------------------
-------------------------- Link Resource and Deprtment ------------------------------
-------------------------------------------------------------------------------------
FUNCTION link_load (p_res_rec   IN OUT NOCOPY   xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
  l_error_transaction   EXCEPTION;
  l_rowid               VARCHAR2 (2000);
  l_msg                 VARCHAR2(300);

BEGIN
    g_api_name := 'link_load';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));


    BEGIN
        l_msg := 'Error Inserting Data using API';

        bom_department_resources_pkg.insert_row (
                                                x_rowid                 => l_rowid,
                                                x_department_id         => p_res_rec.dept_id,
                                                x_resource_id           => p_res_rec.res_id,
                                                x_last_update_date      => SYSDATE,
                                                x_last_updated_by       => fnd_global.user_id,
                                                x_creation_date         => SYSDATE,
                                                x_created_by            => fnd_global.user_id,
                                                x_last_update_login     => fnd_global.user_id,
                                                x_share_capacity_flag   => p_res_rec.SHARE_CAPACITY_FLAG_ID,
                                                x_share_from_dept_id    => NULL,
                                                x_capacity_units        => p_res_rec.CAPACITY_UNITS,
                                                x_resource_group_name   => NULL,
                                                x_available_24_hours_flag => p_res_rec.AVLBL_24_ID,
                                                x_ctp_flag                => p_res_rec.CTP_FLAG_ID,
                                                x_attribute_category      => NULL,
                                                x_attribute1              => NULL,
                                                x_attribute2              => NULL,
                                                x_attribute3              => NULL,
                                                x_attribute4              => NULL,
                                                x_attribute5              => NULL,
                                                x_attribute6              => NULL,
                                                x_attribute7              => NULL,
                                                x_attribute8              => NULL,
                                                x_attribute9              => NULL,
                                                x_attribute10             => NULL,
                                                x_attribute11             => NULL,
                                                x_attribute12             => NULL,
                                                x_attribute13             => NULL,
                                                x_attribute14             => NULL,
                                                x_attribute15             => NULL,
                                                x_exception_set_name      => p_res_rec.EXCEPTION_SET_NAME,
                                                x_atp_rule_id             => p_res_rec.atp_rule_id,
                                                x_utilization             => p_res_rec.UTILIZATION,
                                                x_efficiency              => p_res_rec.EFFICIENCY,
                                                x_schedule_to_instance    => p_res_rec.SCHEDULE_TO_INSTANCE,
                                                X_Sequencing_Window       => p_res_rec.SEQUENCING_WINDOW
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
                       p_res_rec.dept_code||' - '||p_res_rec.res_code,
                       NULL
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'link_load Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_res_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_res_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_res_rec.record_number,
                       p_res_rec.dept_code||' - '||p_res_rec.res_code,
                       NULL
                      );
     RETURN FALSE;
END link_load;
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

CURSOR c_BOMDEPRES_load
IS
  select *
  from XX_INV_BOMDEPRES_STG
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));


  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_inv_BOMDEPRES_tab          xx_inv_BOMDEPRES_tab_type;
  l_inv_BOMDEPRES_rec          xxconv.XX_INV_BOMDEPRES_STG%ROWTYPE;

  e_BOMDEPRES_exception   EXCEPTION;

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
         OPEN c_BOMDEPRES_load;
         LOOP
            FETCH c_BOMDEPRES_load
            BULK COLLECT INTO l_inv_BOMDEPRES_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_inv_BOMDEPRES_tab.COUNT
            LOOP
                l_inv_BOMDEPRES_rec := l_inv_BOMDEPRES_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validtion for '||l_inv_BOMDEPRES_rec.DEPT_CODE||' - '||l_inv_BOMDEPRES_rec.RES_CODE);
                x_error_code  := xx_inv_BOMDEPRES_val_pkg.data_validations_BOMDEPRES(l_inv_BOMDEPRES_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_inv_BOMDEPRES_rec.record_number||'  is ' || x_error_code);
                l_inv_BOMDEPRES_rec.phase_code := G_STAGE;
                l_inv_BOMDEPRES_rec.error_code := x_error_code;
                IF update_BOMDEPRES_stg (l_inv_BOMDEPRES_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'BOMDEPRES_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'BOMDEPRES_stg update FAILED');
                END IF;
            END LOOP;
            l_inv_BOMDEPRES_tab.DELETE;
            EXIT WHEN c_BOMDEPRES_load%NOTFOUND;
         END LOOP;
         CLOSE c_BOMDEPRES_load;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into HZ tables.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF Customer Cursor is Open Close the same
        IF c_BOMDEPRES_load%ISOPEN
        THEN
             CLOSE c_BOMDEPRES_load;
        END IF;

        OPEN c_BOMDEPRES_load;

        FETCH c_BOMDEPRES_load
        BULK COLLECT INTO l_inv_BOMDEPRES_tab;

        FOR i IN 1 .. l_inv_BOMDEPRES_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_inv_BOMDEPRES_rec := l_inv_BOMDEPRES_tab (i);
                l_inv_BOMDEPRES_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_inv_BOMDEPRES_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

                IF NOT fld_derivations (p_res_rec => l_inv_BOMDEPRES_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'fld_derivations Failed');
                   RAISE e_BOMDEPRES_exception;
                END IF; -- res_derivations

                IF NOT link_load (p_res_rec => l_inv_BOMDEPRES_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'link_load Failed');
                   RAISE  e_BOMDEPRES_exception;
                END IF; -- link_load

                l_inv_BOMDEPRES_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_inv_BOMDEPRES_rec.error_msg  := NULL;
                IF update_BOMDEPRES_stg (l_inv_BOMDEPRES_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_BOMDEPRES_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_BOMDEPRES_exception
            THEN
                l_inv_BOMDEPRES_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_BOMDEPRES_stg (l_inv_BOMDEPRES_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_BOMDEPRES_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_inv_BOMDEPRES_tab.DELETE;
        CLOSE c_BOMDEPRES_load;

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

END xx_inv_BOMDEPRES_pkg;
/
