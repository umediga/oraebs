DROP PACKAGE BODY APPS.XX_BOM_DEPARTMENT_PKG;

CREATE OR REPLACE PACKAGE BODY APPS."XX_BOM_DEPARTMENT_PKG" 
AS
----------------------------------------------------------------------
/*
 Created By     : IBM Development Team
 Creation Date  : 08-Dec-2013
 File Name      : XXBOMDEPT.pkb
 Description    : This script creates the body of the package XX_BOM_DEPARTMENT_PKG
----------------------------*------------------------------------------------------------------
----------------------------*------------------------------------------------------------------
COMMON GUIDELINES REGARDING EMF
-------------------------------
1. All low level emf messages can be retained
2. Hard coding of emf messages are allowed in the code
3. Any other hard coding should be dealt by constants package
4. Exception handling should be left as is most of the places unless specified

Change History:
---------------------------------------------------------------------------------------------
Date            Name          		Remarks
---------------------------------------------------------------------------------------------
08-Dec-2013     Narendra Yadav 		Initial development.
---------------------------------------------------------------------------------------------
*/

-- DO NOT CHANGE ANYTHING IN THESE PROCEDURES mark_records_for_processing and set_cnv_env
-- START RESTRICTIONS

-------------------------------------------------------------------------------------
------------< Procedure for setting Environment >------------
-------------------------------------------------------------------------------------

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
    UPDATE XXBOM_DEPARTMENT_STG
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
------------< Update BOM Department Table Status after Validation >------------
--------------------------------------------------------------------------------
PROCEDURE update_bom_dept_rec_status ( p_bom_dept_rec   IN OUT  g_xx_bom_department_rec_type,
                                      p_error_code     IN      VARCHAR2
                                    ) IS
BEGIN
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Start of update_bom_dept_rec_status');

    IF p_error_code IN (xx_emf_cn_pkg.CN_REC_ERR, xx_emf_cn_pkg.CN_PRC_ERR)
    THEN
        p_bom_dept_rec.ERROR_CODE := xx_emf_cn_pkg.CN_REC_ERR;
    ELSE
        p_bom_dept_rec.ERROR_CODE := xx_intg_common_pkg.find_max(p_error_code, NVL (p_bom_dept_rec.ERROR_CODE, xx_emf_cn_pkg.CN_SUCCESS));

    END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'End of update_bom_dept_rec_status');
EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW, 'Error in update_bom_dept_rec_status '||SQLERRM);
END update_bom_dept_rec_status;

--------------------------------------------------------------------------------
------------< Update BOM Department Staging Records  >------------
--------------------------------------------------------------------------------
FUNCTION update_bom_department_stg (
                                  p_stage_rec   IN OUT NOCOPY   xxconv.XXBOM_DEPARTMENT_STG%ROWTYPE
                                 ,p_batch_id    IN              VARCHAR2
                                 )
  RETURN BOOLEAN
IS
    x_last_update_date       DATE   := SYSDATE;
    x_last_updated_by        NUMBER := fnd_global.user_id;
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    g_api_name := 'update_bom_department_stg';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Before updating BOM Dept Staging table');

    UPDATE XXBOM_DEPARTMENT_STG
    SET BATCH_ID			= p_stage_rec.BATCH_ID,
		SOURCE_SYSTEM_NAME 	= p_stage_rec.SOURCE_SYSTEM_NAME,
		RECORD_NUMBER 		= p_stage_rec.RECORD_NUMBER,
		DEPARTMENT_CODE		= p_stage_rec.DEPARTMENT_CODE,
		DEPARTMENT_ID		= p_stage_rec.DEPARTMENT_ID,
		DESCRIPTION			= p_stage_rec.DESCRIPTION,
		ORG_CODE			= p_stage_rec.ORG_CODE,
		ORG_ID				= p_stage_rec.ORG_ID,
		DEPT_COST_CAT		= p_stage_rec.DEPT_COST_CAT,
		DEPT_COST_CAT_CODE	= p_stage_rec.DEPT_COST_CAT_CODE,
		DEPT_CLASS_CODE		= p_stage_rec.DEPT_CLASS_CODE,
		LOCATION			= p_stage_rec.LOCATION,
		LOCATION_ID			= p_stage_rec.LOCATION_ID,
		PROJ_EXP_ORG		= p_stage_rec.PROJ_EXP_ORG,
		PROJ_EXP_ORG_ID		= p_stage_rec.PROJ_EXP_ORG_ID,
		INACTIVE_DATE		= p_stage_rec.INACTIVE_DATE,
		ATTRIBUTE_CATEGORY	= p_stage_rec.ATTRIBUTE_CATEGORY,
		ATTRIBUTE1			= p_stage_rec.ATTRIBUTE1,
		ATTRIBUTE2			= p_stage_rec.ATTRIBUTE2,
		ATTRIBUTE3			= p_stage_rec.ATTRIBUTE3,
		ATTRIBUTE4			= p_stage_rec.ATTRIBUTE4,
		ATTRIBUTE5			= p_stage_rec.ATTRIBUTE5,
		ATTRIBUTE6			= p_stage_rec.ATTRIBUTE6,
		ATTRIBUTE7			= p_stage_rec.ATTRIBUTE7,
		ATTRIBUTE8			= p_stage_rec.ATTRIBUTE8,
		ATTRIBUTE9			= p_stage_rec.ATTRIBUTE9,
		ATTRIBUTE10			= p_stage_rec.ATTRIBUTE10,
		ATTRIBUTE11			= p_stage_rec.ATTRIBUTE11,
		ATTRIBUTE12			= p_stage_rec.ATTRIBUTE12,
		ATTRIBUTE13			= p_stage_rec.ATTRIBUTE13,
		ATTRIBUTE14			= p_stage_rec.ATTRIBUTE14,
		ATTRIBUTE15			= p_stage_rec.ATTRIBUTE15,
		REQUEST_ID			= xx_emf_pkg.G_REQUEST_ID,
		LAST_UPDATED_BY		= x_last_updated_by,
		LAST_UPDATE_DATE	= x_last_update_date,
		PHASE_CODE			= p_stage_rec.PHASE_CODE,
		ERROR_CODE			= p_stage_rec.ERROR_CODE,
		ERROR_MSG			= p_stage_rec.ERROR_MSG
    WHERE batch_id          =   p_batch_id
    and   record_number     =   p_stage_rec.record_number
    and   department_code  	=   p_stage_rec.department_code
    and   org_code         	=   p_stage_rec.org_code;


    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    COMMIT;
    RETURN TRUE;
EXCEPTION
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,'update_bom_department_stg Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_HIGH,SQLERRM);
     RETURN FALSE;
END update_bom_department_stg;


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
    from XXBOM_DEPARTMENT_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID;

    select count(1)
    into l_suc
    from XXBOM_DEPARTMENT_STG
    where batch_id   =  g_batch_id
    and   request_id =  xx_emf_pkg.G_REQUEST_ID
    and   error_code = '0';

    select count(1)
    into l_err
    from XXBOM_DEPARTMENT_STG
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
---------------------------------- BOM Department Data Derivation -------------------
-------------------------------------------------------------------------------------
--------Deriving Organization_ID for Organization_code-------------------------------
FUNCTION data_derivations (p_dept_rec   IN OUT NOCOPY   xxconv.XXBOM_DEPARTMENT_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  l_error_transaction   EXCEPTION;
  l_msg                 VARCHAR2 (400);
BEGIN
    g_api_name := 'data_derivations';
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    --Deriving Organization ID------------
	BEGIN
		select organization_id
		into p_dept_rec.org_id
		from org_organization_definitions
		where organization_code = p_dept_rec.org_code;
	EXCEPTION
		WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Organization ID  :'||p_dept_rec.org_code);
        l_msg := 'Error Deriving Organization ID';
        RAISE l_error_transaction;
    END;--Organization ID

	IF p_dept_rec.dept_cost_cat is NOT NULL THEN
  --Deriving department cost category-----------
	BEGIN
		SELECT lookup_code
		INTO p_dept_rec.dept_cost_cat_code
		FROM mfg_lookups
		WHERE lookup_type = 'BOM_EAM_COST_CATEGORY'
			  AND enabled_flag = 'Y'
			  AND meaning = p_dept_rec.dept_cost_cat;
	EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving department cost category id for :'||p_dept_rec.dept_cost_cat);
        l_msg := 'Error Deriving department cost category id ';
        RAISE l_error_transaction;
	END;--department cost category
	END IF;

   IF p_dept_rec.location IS NOT NULL THEN
    --Deriving Location ID-------------
    BEGIN
		SELECT location_id
		INTO p_dept_rec.location_id
		FROM hr_locations
		WHERE UPPER(location_code) = UPPER(p_dept_rec.location);
	EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving location id for :'||p_dept_rec.location);
        l_msg := 'Error Deriving location id ';
        RAISE l_error_transaction;
	END;--Location ID
	END IF;

  IF p_dept_rec.proj_exp_org IS NOT NULL THEN
  --Deriving Proj_Exp_org_id---------
	BEGIN
		SELECT hrorg.organization_id
		INTO   p_dept_rec.proj_exp_org_id
		FROM   hr_organization_units hrorg, pa_all_organizations paorg
		WHERE  paorg.organization_id = hrorg.organization_id
		AND    PAORG.PA_ORG_USE_TYPE = 'EXPENDITURES'
		AND    PAORG.INACTIVE_DATE IS NULL
		AND    trunc(sysdate) between hrorg.date_from and nvl(hrorg.date_to, trunc(sysdate))
		AND    upper(hrorg.name) = upper(p_dept_rec.proj_exp_org);
	EXCEPTION
    WHEN OTHERS THEN
        xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'Error Deriving Proj Exp. Org id for :'||p_dept_rec.proj_exp_org);
        l_msg := 'Error Deriving Proj Exp. Org id ';
        RAISE l_error_transaction;
	END;--Proj_Exp_org_id
	END IF;

	xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    RETURN TRUE;
EXCEPTION
  WHEN l_error_transaction
  THEN
     p_dept_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_dept_rec.error_msg   := g_api_name || ': ' || l_msg;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg,
                       p_dept_rec.record_number,
                       p_dept_rec.department_code,
                       p_dept_rec.org_code
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'data_derivations Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_dept_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_dept_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_dept_rec.record_number,
                       p_dept_rec.department_code,
                       p_dept_rec.org_code
                      );
     RETURN FALSE;
END data_derivations;


-------------------------------------------------------------------------------------
---------------------------------- Record Load --------------------------------------
-------------------------------------------------------------------------------------
FUNCTION record_load (p_dept_rec   IN OUT NOCOPY   xxconv.XXBOM_DEPARTMENT_STG%ROWTYPE)
      RETURN BOOLEAN
IS
  --PRAGMA AUTONOMOUS_TRANSACTION;
  l_error_transaction              EXCEPTION;
  l_msg                            VARCHAR2 (400);
  l_rowid                          VARCHAR2 (2000);
  l_department_id                  NUMBER;

BEGIN
    g_api_name := 'record_load';
	l_department_id := null;
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' +');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

	bom_departments_pkg.insert_row (
                                      x_rowid                 => l_rowid,
                                      x_department_id         => l_department_id,
                                      x_department_code       => p_dept_rec.DEPARTMENT_CODE,
                                      x_organization_id       => p_dept_rec.org_Id,
                                      x_last_update_date      => SYSDATE,
                                      x_last_updated_by       => fnd_global.user_id,
                                      x_creation_date         => SYSDATE,
                                      x_created_by            => fnd_global.user_id,
                                      x_last_update_login     => fnd_global.user_id,
                                      x_description           => p_dept_rec.DESCRIPTION,
                                      x_disable_date          => p_dept_rec.INACTIVE_DATE,
                                      x_department_class_code => p_dept_rec.DEPT_CLASS_CODE,
                                      x_pa_expenditure_org_id => p_dept_rec.proj_exp_org_id,
                                      x_attribute_category    => NULL,
                                      x_attribute1            => NULL,
                                      x_attribute2            => NULL,
                                      x_attribute3            => NULL,
                                      x_attribute4            => NULL,
                                      x_attribute5            => NULL,
                                      x_attribute6            => NULL,
                                      x_attribute7            => NULL,
                                      x_attribute8            => NULL,
                                      x_attribute9            => NULL,
                                      x_attribute10           => NULL,
                                      x_attribute11           => NULL,
                                      x_attribute12           => NULL,
                                      x_attribute13           => NULL,
                                      x_attribute14           => NULL,
                                      x_attribute15           => NULL,
                                      x_location_id           => p_dept_rec.location_id,
                                      x_scrap_account         => NULL,
                                      x_est_absorption_account => NULL,
                                      x_maint_cost_category    => p_dept_rec.dept_cost_cat_code
                                      );
        IF l_department_id IS NOT NULL THEN
           dbms_output.put_line('Department ID : '||l_department_id);
           update XXBOM_DEPARTMENT_STG
           set error_code = '0'
              ,phase_code = 'Loaded'
              ,error_msg = to_char(l_department_id)
              ,ORG_ID = p_dept_rec.org_id
              ,DEPT_COST_CAT_CODE = p_dept_rec.dept_cost_cat_code
              ,LOCATION_ID =  p_dept_rec.location_id
              ,PROJ_EXP_ORG_ID = p_dept_rec.org_id
              ,last_update_date = sysdate
           where record_number = p_dept_rec.record_number;
        ELSE
           --dbms_output.put_line('Exception');
           update XXBOM_DEPARTMENT_STG
           set error_code = '2'
              ,phase_code = 'Loaded'
              ,error_msg  = 'No Department ID'
              ,last_update_date = sysdate
           where record_number = p_dept_rec.record_number;
        END IF;

    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,g_api_name||' -');
    xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,RPAD ('=', 40, '='));

    RETURN TRUE;
EXCEPTION
  WHEN l_error_transaction
  THEN
     p_dept_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_dept_rec.error_msg   := g_api_name || ': ' || l_msg||' '||SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || l_msg||' '||SQLERRM,
                       p_dept_rec.record_number,
                       p_dept_rec.department_code,
                       p_dept_rec.org_code
                      );
     RETURN FALSE;
  WHEN OTHERS
  THEN
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,l_msg);
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,'record_load Failed');
     xx_emf_pkg.write_log(xx_emf_cn_pkg.CN_LOW,SQLERRM);
     p_dept_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
     p_dept_rec.error_msg   := g_api_name || ': ' || SQLERRM;
     xx_emf_pkg.error (xx_emf_cn_pkg.CN_MEDIUM,
                       xx_emf_cn_pkg.CN_STG_DATADRV,
                       g_api_name || ': ' || SQLERRM,
                       p_dept_rec.record_number,
                       p_dept_rec.department_code,
                       p_dept_rec.org_code
                      );
     RETURN FALSE;
END record_load;
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

CURSOR c_bom_department
IS
  select *
  from XXBOM_DEPARTMENT_STG
  WHERE batch_id = p_batch_id
  AND  ((p_restart_flag = xx_emf_cn_pkg.CN_ERR_RECS AND  ERROR_CODE  = xx_emf_cn_pkg.CN_REC_ERR )
       OR
        (p_restart_flag = xx_emf_cn_pkg.CN_ALL_RECS AND  NVL(ERROR_CODE, xx_emf_cn_pkg.CN_REC_ERR) in (xx_emf_cn_pkg.CN_REC_ERR,decode(PHASE_CODE,xx_emf_cn_pkg.CN_PROCESS_DATA,xx_emf_cn_pkg.CN_REC_ERR,xx_emf_cn_pkg.CN_SUCCESS))));


  x_error_code              NUMBER := xx_emf_cn_pkg.cn_success;
  l_bom_department_tab     xx_bom_department_tab_type;
  l_bom_department_rec     xxconv.XXBOM_DEPARTMENT_STG%ROWTYPE;

  e_bom_dept_exception   EXCEPTION;

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
     -- This section is executed when the user selects to VALIDATE_ONLY mode. The section pertains to validation of given data
         set_stage (xx_emf_cn_pkg.CN_VALID);
         -- Start Data Validation
         OPEN c_bom_department;
         LOOP
            FETCH c_bom_department
            BULK COLLECT INTO l_bom_department_tab LIMIT xx_emf_cn_pkg.cn_bulk_collect;

            FOR i IN 1 .. l_bom_department_tab.COUNT
            LOOP
                l_bom_department_rec := l_bom_department_tab (i);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, ' ');
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('*', 40, '*'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'In Data validation for Department '||l_bom_department_rec.DEPARTMENT_CODE);
                x_error_code  := xx_bom_department_val_pkg.data_validations_att(l_bom_department_rec);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'x_error_code for '||l_bom_department_rec.record_number||'  is ' || x_error_code);
                l_bom_department_rec.phase_code := G_STAGE;
                l_bom_department_rec.error_code := x_error_code;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW, 'Going to update staging table after validation in val_only mode');
                IF update_bom_department_stg (l_bom_department_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'xx_bom_department_stg updated');
                ELSE
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'xx_bom_department_stg update FAILED');
                END IF;
            END LOOP;
            l_bom_department_tab.DELETE;
            EXIT WHEN c_bom_department%NOTFOUND;
         END LOOP;
         CLOSE c_bom_department;
     ELSIF p_validate_and_load = 'VALIDATE_AND_LOAD' THEN
     -- This section is executed when the user selects to VALIDATE_AND_LOAD mode. The section will use API's to load data into BOM Department table.
        set_stage (xx_emf_cn_pkg.CN_PROCESS_DATA);

        -- IF BOM Department Cursor is Open then Close the same
        IF c_bom_department%ISOPEN
        THEN
             CLOSE c_bom_department;
        END IF;

        OPEN c_bom_department;

        FETCH c_bom_department
        BULK COLLECT INTO l_bom_department_tab;

        FOR i IN 1 .. l_bom_department_tab.COUNT
        LOOP
            BEGIN
                SAVEPOINT skip_transaction;

                l_bom_department_rec := l_bom_department_tab (i);
                l_bom_department_rec.phase_code := g_stage;

                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,'Name : ' || l_bom_department_rec.RECORD_NUMBER);
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_LOW,RPAD ('#', 40, '#'));

				IF NOT data_derivations (p_dept_rec => l_bom_department_rec)
                THEN
                   xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'data_derivations Failed');
                   RAISE e_bom_dept_exception;
                END IF; -- data_derivations

                IF NOT record_load (p_dept_rec => l_bom_department_rec)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'record_load Failed');
                    RAISE e_bom_dept_exception;
                END IF; -- record_load

                l_bom_department_rec.error_code := xx_emf_cn_pkg.CN_SUCCESS;
                l_bom_department_rec.error_msg  := NULL;
                IF update_bom_department_stg (l_bom_department_rec, p_batch_id)
                THEN
                     xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'update_bom_department_stg updated');
                END IF;

                COMMIT;
            EXCEPTION
            WHEN e_bom_dept_exception
            THEN
                l_bom_department_rec.error_code := xx_emf_cn_pkg.CN_REC_ERR;
                IF update_bom_department_stg (l_bom_department_rec,p_batch_id)
                THEN
                    xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'bom_department_stg updated');
                END IF;
                xx_emf_pkg.write_log (xx_emf_cn_pkg.CN_HIGH,'Transaction Rolled Back...');
                ROLLBACK TO SAVEPOINT skip_transaction;
            END;
        END LOOP;

        l_bom_department_tab.DELETE;
        CLOSE c_bom_department;

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
        xx_emf_pkg.write_log ( xx_emf_cn_pkg.CN_LOW, 'OTHERS '||SQLERRM);
        retcode := xx_emf_cn_pkg.CN_PRC_ERR;
        xx_emf_pkg.create_report;
END main;

END xx_bom_department_pkg;
/
